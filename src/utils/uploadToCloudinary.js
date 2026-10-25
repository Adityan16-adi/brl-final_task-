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

const determineResourceType = (options = {}) => {
  if (options.resource_type) return options.resource_type;
  if (options.resourceType) return options.resourceType;

  const mimetype = (options.mimetype || '').toLowerCase();
  const ext = options.filename ? path.extname(options.filename).toLowerCase() : '';

  // Images
  if (
    mimetype.startsWith('image/') ||
    ['.jpg', '.jpeg', '.png', '.webp', '.gif', '.svg', '.bmp'].includes(ext)
  ) {
    return 'image';
  }

  // Videos
  if (
    mimetype.startsWith('video/') ||
    ['.mp4', '.webm', '.mov', '.avi', '.mkv'].includes(ext)
  ) {
    return 'video';
  }

  // Raw documents (PDFs, ZIPs, Office docs, text) to bypass Cloudinary's "PDF and ZIP files delivery" image security restriction
  return 'raw';
};

const uploadToCloudinary = (buffer, folder, options = {}) =>
  new Promise((resolve, reject) => {
    if (!buffer || !Buffer.isBuffer(buffer) || buffer.length === 0) {
      return reject(new Error('Upload failed: Empty or invalid file buffer provided'));
    }

    const resourceType = determineResourceType(options);

    if (!isCloudinaryConfigured()) {
      // Robust disk storage fallback when Cloudinary credentials are not present
      try {
        const uploadsDir = path.resolve(__dirname, '../../uploads');
        if (!fs.existsSync(uploadsDir)) {
          fs.mkdirSync(uploadsDir, { recursive: true });
        }
        const safeFolder = (folder || 'file').replace(/[^a-zA-Z0-9_-]/g, '_');
        const ext = options.filename
          ? path.extname(options.filename).toLowerCase()
          : (resourceType === 'image' ? '.png' : (resourceType === 'video' ? '.mp4' : '.bin'));
        const filename = `${safeFolder}_${Date.now()}_${Math.random().toString(36).slice(2, 8)}${ext}`;
        const filePath = path.join(uploadsDir, filename);
        fs.writeFileSync(filePath, buffer);

        const localUrl = `/uploads/${filename}`;
        return resolve({
          secure_url: localUrl,
          url: localUrl,
          public_id: `local_${filename}`,
          resource_type: resourceType,
          bytes: buffer.length,
          original_filename: options.filename || '',
        });
      } catch (fsErr) {
        return reject(new Error(`Local file storage fallback failed: ${fsErr.message}`));
      }
    }

    const uploadOptions = {
      folder,
      resource_type: resourceType,
      ...(options.cloudinaryOptions || {}),
    };

    const stream = cloudinary.uploader.upload_stream(
      uploadOptions,
      (err, result) => {
        if (err) return reject(err);
        resolve(result);
      }
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
    const res = await cloudinary.uploader.destroy(publicId, { resource_type: resourceType || 'raw' });
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
module.exports.determineResourceType = determineResourceType;
