const path = require('path');
const fs = require('fs');
const cloudinary = require('../../config/cloudinary');

const isCloudinaryConfigured = () => {
  const { CLOUDINARY_CLOUD_NAME, CLOUDINARY_API_KEY, CLOUDINARY_API_SECRET } = process.env;
  return !!(
    CLOUDINARY_CLOUD_NAME &&
    CLOUDINARY_API_KEY &&
    CLOUDINARY_API_SECRET &&
    CLOUDINARY_API_KEY !== 'your_cloudinary_api_key'
  );
};

const uploadToCloudinary = (buffer, folder) =>
  new Promise((resolve, reject) => {
    if (!buffer || !Buffer.isBuffer(buffer) || buffer.length === 0) {
      return reject(new Error('Upload failed: Empty or invalid file buffer provided'));
    }

    if (!isCloudinaryConfigured()) {
      // Robust disk storage fallback when Cloudinary credentials are not present
      try {
        const uploadsDir = path.resolve(__dirname, '../../uploads');
        if (!fs.existsSync(uploadsDir)) {
          fs.mkdirSync(uploadsDir, { recursive: true });
        }
        const safeFolder = (folder || 'file').replace(/[^a-zA-Z0-9_-]/g, '_');
        const filename = `${safeFolder}_${Date.now()}_${Math.random().toString(36).slice(2, 8)}.bin`;
        const filePath = path.join(uploadsDir, filename);
        fs.writeFileSync(filePath, buffer);

        const localUrl = `/uploads/${filename}`;
        return resolve({
          secure_url: localUrl,
          url: localUrl,
          public_id: `local_${filename}`,
          resource_type: 'raw',
          bytes: buffer.length,
        });
      } catch (fsErr) {
        return reject(new Error(`Local file storage fallback failed: ${fsErr.message}`));
      }
    }

    const stream = cloudinary.uploader.upload_stream(
      { folder, resource_type: 'auto' },
      (err, result) => (err ? reject(err) : resolve(result))
    );
    stream.end(buffer);
  });

const deleteFromCloudinary = async (publicId, resourceType = 'image') => {
  if (!publicId) return false;

  // Handle local file cleanup
  if (publicId.startsWith('local_')) {
    try {
      const filename = publicId.replace(/^local_/, '');
      const uploadsDir = path.resolve(__dirname, '../../uploads');
      const filePath = path.join(uploadsDir, filename);
      if (fs.existsSync(filePath)) {
        fs.unlinkSync(filePath);
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  if (!isCloudinaryConfigured()) return false;

  try {
    const res = await cloudinary.uploader.destroy(publicId, { resource_type: resourceType });
    if (res?.result === 'ok') {
      return true;
    }
    console.warn(`Cloudinary deletion returned non-ok result for ${publicId}:`, res);
    return false;
  } catch (err) {
    console.warn(`Failed to delete asset ${publicId} from Cloudinary:`, err.message);
    return false;
  }
};

module.exports = uploadToCloudinary;
module.exports.uploadToCloudinary = uploadToCloudinary;
module.exports.isCloudinaryConfigured = isCloudinaryConfigured;
module.exports.deleteFromCloudinary = deleteFromCloudinary;
