const multer = require('multer');

const allowedTypes = [
  'application/pdf',
  'application/msword',
  'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
  'application/vnd.ms-powerpoint',
  'application/vnd.openxmlformats-officedocument.presentationml.presentation',
  'image/jpeg',
  'image/png',
  'image/webp',
  'text/plain',
  'video/mp4',
  'video/webm',
  'video/quicktime',
];

const upload = multer({
  storage: multer.memoryStorage(),            // keep file in RAM, not on disk
  limits: { fileSize: 25 * 1024 * 1024 },     // 25 MB max
  fileFilter: (req, file, cb) => {
    if (allowedTypes.includes(file.mimetype)) cb(null, true);
    else cb(new Error('File type not allowed. Supported formats: PDF, DOC, DOCX, PPT, PPTX, JPG, PNG, WEBP, TXT, MP4, WEBM, MOV.'));
  },
});

module.exports = upload;