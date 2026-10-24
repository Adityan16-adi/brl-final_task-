
const Material = require("../models/Material");
const uploadToCloudinary = require("../utils/uploadToCloudinary");
const { deleteFromCloudinary } = uploadToCloudinary;

const detectType = (mimetype = "") => {
    if (mimetype.startsWith("image/")) return "image";
    if (mimetype.startsWith("video/")) return "video";
    return "note";
};

// POST /api/materials
exports.createMaterial = async (req, res) => {
    let newlyUploadedPublicId = null;
    let newlyUploadedResourceType = null;

    try {
        const {
            classId,
            uploadedBy,
            title,
            description,
            link,
            thumbnailUrl,
        } = req.body || {};

        if (!classId || !title || !uploadedBy) {
            return res.status(400).json({
                success: false,
                message: "classId, uploadedBy and title are required",
            });
        }

        if (!req.file && !link) {
            return res.status(400).json({
                success: false,
                message: "Attach a file or provide a link",
            });
        }

        let type = "link";
        let fileUrl = "";
        let filePublicId = "";
        let fileResourceType = "";
        let generatedThumbnail = thumbnailUrl || "";

        if (req.file) {
            type = detectType(req.file.mimetype);

            const result = await uploadToCloudinary(
                req.file.buffer,
                "learning-materials"
            );

            fileUrl = result.secure_url;
            filePublicId = result.public_id;
            fileResourceType = result.resource_type;
            newlyUploadedPublicId = result.public_id;
            newlyUploadedResourceType = result.resource_type;

            if (type === "image") {
                generatedThumbnail = result.secure_url;
            }
        }

        const material = await Material.create({
            classId,
            uploadedBy,
            title,
            description: description || "",
            type,
            fileUrl,
            filePublicId,
            fileResourceType,
            thumbnailUrl: generatedThumbnail,
            link: link || "",
        });

        return res.status(201).json({
            success: true,
            message: "Material added",
            data: material,
        });
    } catch (error) {
        if (newlyUploadedPublicId) {
            await deleteFromCloudinary(newlyUploadedPublicId, newlyUploadedResourceType);
        }
        if (error.message && error.message.includes("Cloud storage is not configured")) {
            return res.status(503).json({
                success: false,
                message: "Storage service not configured. Unable to upload file.",
            });
        }
        console.error("Create material error:", error);
        return res.status(500).json({
            success: false,
            message: "Unable to create material",
        });
    }
};

// GET /api/materials/class/:classId
exports.getMaterialsByClass = async (req, res) => {
    try {
        const filter = { classId: req.params.classId };

        if (req.query.type) {
            filter.type = req.query.type;
        }

        const data = await Material.find(filter).sort({ createdAt: -1 });

        return res.json({ success: true, data });
    } catch (error) {
        console.error("Get materials error:", error);
        return res.status(500).json({
            success: false,
            message: "Unable to retrieve materials",
        });
    }
};

// GET /api/materials/:id
exports.getMaterialById = async (req, res) => {
    try {
        const material = await Material.findById(req.params.id);

        if (!material) {
            return res.status(404).json({
                success: false,
                message: "Material not found",
            });
        }

        return res.json({ success: true, data: material });
    } catch (error) {
        console.error("Get material error:", error);
        return res.status(500).json({
            success: false,
            message: "Unable to retrieve material",
        });
    }
};

// DELETE /api/materials/:id
exports.deleteMaterial = async (req, res) => {
    try {
        const material = await Material.findById(req.params.id);

        if (!material) {
            return res.status(404).json({
                success: false,
                message: "Material not found",
            });
        }

        await Material.findByIdAndDelete(req.params.id);

        // Safe cleanup: Only delete from Cloudinary AFTER DB deletion succeeds
        if (material.filePublicId) {
            await deleteFromCloudinary(material.filePublicId, material.fileResourceType);
        }

        return res.json({
            success: true,
            message: "Material deleted",
            data: material,
        });
    } catch (error) {
        console.error("Delete material error:", error);
        return res.status(500).json({
            success: false,
            message: "Unable to delete material",
        });
    }
};
