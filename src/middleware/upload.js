const multer = require('multer');

const allowedTypes = [
  'application/pdf',
  'application/msword',
  'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
  'application/vnd.ms-powerpoint',
  'application/vnd.openxmlformats-officedocument.presentationml.presentation',
  'image/jpeg',
  'image/png',
  'text/plain',
];

const upload = multer({
  storage: multer.memoryStorage(),            // keep file in RAM, not on disk
  limits: { fileSize: 10 * 1024 * 1024 },     // 10 MB max
  fileFilter: (req, file, cb) => {
    if (allowedTypes.includes(file.mimetype)) cb(null, true);
    else cb(new Error('File type not allowed'));
  },
});

module.exports = upload;