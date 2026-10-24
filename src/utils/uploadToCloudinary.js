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
      return reject(new Error('Cloud storage is not configured. Set CLOUDINARY_CLOUD_NAME, CLOUDINARY_API_KEY, and CLOUDINARY_API_SECRET.'));
    }
    const stream = cloudinary.uploader.upload_stream(
      { folder, resource_type: 'auto' },
      (err, result) => (err ? reject(err) : resolve(result))
    );
    stream.end(buffer);
  });

const deleteFromCloudinary = async (publicId, resourceType = 'image') => {
  if (!publicId || !isCloudinaryConfigured()) return false;
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
