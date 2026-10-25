const path = require('path');
const multer = require('multer');

const allowedTypes = [
  'application/pdf',
  'application/msword',
  'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
  'application/vnd.ms-powerpoint',
  'application/vnd.openxmlformats-officedocument.presentationml.presentation',
  'application/vnd.ms-excel',
  'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
  'application/zip',
  'application/x-zip-compressed',
  'application/x-zip',
  'multipart/x-zip',
  'image/jpeg',
  'image/png',
  'image/webp',
  'text/plain',
  'text/csv',
  'video/mp4',
  'video/webm',
  'video/quicktime',
];

const allowedExtensions = new Set([
  '.pdf',
  '.doc',
  '.docx',
  '.ppt',
  '.pptx',
  '.xls',
  '.xlsx',
  '.txt',
  '.csv',
  '.mp4',
  '.webm',
  '.mov',
  '.jpg',
  '.jpeg',
  '.png',
  '.webp',
  '.zip',
]);

const upload = multer({
  storage: multer.memoryStorage(),            // keep file in RAM, not on disk
  limits: { fileSize: 25 * 1024 * 1024 },     // 25 MB max
  fileFilter: (req, file, cb) => {
    const ext = path.extname(file.originalname || '').toLowerCase();
    const mimeMatch = allowedTypes.includes(file.mimetype);
    const extMatch = allowedExtensions.has(ext);

    // If mimetype matches or file extension is in allowed extensions
    if (mimeMatch || extMatch) {
      cb(null, true);
    } else {
      cb(new Error('File type not allowed. Supported formats: PDF, DOC, DOCX, PPT, PPTX, XLS, XLSX, TXT, MP4, ZIP, JPG, PNG, WEBP.'));
    }
  },
});

module.exports = upload;
