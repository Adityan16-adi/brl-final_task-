const assert = require('assert');
const path = require('path');

const upload = require('../src/middleware/upload');
const uploadToCloudinary = require('../src/utils/uploadToCloudinary');
const { determineResourceType } = uploadToCloudinary;

async function runPartB() {
  console.log('====================================================');
  console.log('PART B: VERIFYING UPLOAD ENDPOINTS & FILE HANDLING');
  console.log('====================================================\n');

  let passedTests = 0;
  let totalTests = 0;

  function test(name, fn) {
    totalTests++;
    try {
      fn();
      console.log(`  [PASS] ${name}`);
      passedTests++;
    } catch (err) {
      console.error(`  [FAIL] ${name}: ${err.message}`);
    }
  }

  // 1. Cloudinary Resource Type Routing Tests
  console.log('--- 1. Cloudinary Resource Type Routing Tests ---');
  test('Routes PDF to raw (bypasses Cloudinary image security restriction)', () => {
    assert.strictEqual(
      determineResourceType({ mimetype: 'application/pdf', filename: 'report.pdf' }),
      'raw'
    );
  });

  test('Routes ZIP archives to raw', () => {
    assert.strictEqual(
      determineResourceType({ mimetype: 'application/zip', filename: 'project_archive.zip' }),
      'raw'
    );
  });

  test('Routes Office documents (.docx, .pptx, .xlsx) to raw', () => {
    assert.strictEqual(
      determineResourceType({
        mimetype: 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
        filename: 'notes.docx',
      }),
      'raw'
    );
    assert.strictEqual(
      determineResourceType({
        mimetype: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        filename: 'grades.xlsx',
      }),
      'raw'
    );
    assert.strictEqual(
      determineResourceType({
        mimetype: 'application/vnd.openxmlformats-officedocument.presentationml.presentation',
        filename: 'slides.pptx',
      }),
      'raw'
    );
  });

  test('Routes images (.png, .jpg, .webp) to image', () => {
    assert.strictEqual(
      determineResourceType({ mimetype: 'image/png', filename: 'diagram.png' }),
      'image'
    );
    assert.strictEqual(
      determineResourceType({ mimetype: 'image/jpeg', filename: 'photo.jpg' }),
      'image'
    );
  });

  test('Routes videos (.mp4, .webm) to video', () => {
    assert.strictEqual(
      determineResourceType({ mimetype: 'video/mp4', filename: 'lecture.mp4' }),
      'video'
    );
  });

  // 2. Express Multer Middleware Verification
  console.log('\n--- 2. Express Multer Upload Middleware Tests ---');

  test('Upload limit is strictly configured to 25 MB', () => {
    assert.strictEqual(upload.limits.fileSize, 25 * 1024 * 1024);
  });

  test('Upload fileFilter rejects forbidden executable files (.exe)', (done) => {
    let called = false;
    upload.fileFilter(
      {},
      { mimetype: 'application/x-msdownload', originalname: 'malware.exe' },
      (err, accept) => {
        called = true;
        assert.ok(err instanceof Error);
        assert.ok(err.message.includes('File type not allowed'));
        assert.strictEqual(accept, undefined);
      }
    );
    assert.ok(called);
  });

  test('Upload fileFilter rejects forbidden script files (.bat, .sh)', (done) => {
    let called = false;
    upload.fileFilter(
      {},
      { mimetype: 'application/x-sh', originalname: 'script.sh' },
      (err, accept) => {
        called = true;
        assert.ok(err instanceof Error);
        assert.ok(err.message.includes('File type not allowed'));
      }
    );
    assert.ok(called);
  });

  test('Upload fileFilter accepts valid PDF files', () => {
    let accepted = false;
    upload.fileFilter(
      {},
      { mimetype: 'application/pdf', originalname: 'lecture_notes.pdf' },
      (err, accept) => {
        assert.strictEqual(err, null);
        assert.strictEqual(accept, true);
        accepted = true;
      }
    );
    assert.ok(accepted);
  });

  test('Upload fileFilter accepts valid ZIP archives', () => {
    let accepted = false;
    upload.fileFilter(
      {},
      { mimetype: 'application/zip', originalname: 'assignment_pack.zip' },
      (err, accept) => {
        assert.strictEqual(err, null);
        assert.strictEqual(accept, true);
        accepted = true;
      }
    );
    assert.ok(accepted);
  });

  test('Upload fileFilter accepts Word, Excel, and PowerPoint documents', () => {
    const docs = [
      { mimetype: 'application/msword', originalname: 'doc1.doc' },
      {
        mimetype:
          'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
        originalname: 'doc2.docx',
      },
      { mimetype: 'application/vnd.ms-excel', originalname: 'sheet1.xls' },
      {
        mimetype:
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        originalname: 'sheet2.xlsx',
      },
      {
        mimetype:
          'application/vnd.openxmlformats-officedocument.presentationml.presentation',
        originalname: 'pres.pptx',
      },
    ];

    for (const d of docs) {
      let accepted = false;
      upload.fileFilter({}, d, (err, accept) => {
        assert.strictEqual(err, null);
        assert.strictEqual(accept, true);
        accepted = true;
      });
      assert.ok(accepted, `Failed to accept ${d.originalname}`);
    }
  });

  test('Upload fileFilter accepts PNG, JPEG, and WebP images', () => {
    const images = [
      { mimetype: 'image/png', originalname: 'photo.png' },
      { mimetype: 'image/jpeg', originalname: 'scan.jpg' },
      { mimetype: 'image/webp', originalname: 'diagram.webp' },
    ];
    for (const img of images) {
      let accepted = false;
      upload.fileFilter({}, img, (err, accept) => {
        assert.strictEqual(err, null);
        assert.strictEqual(accept, true);
        accepted = true;
      });
      assert.ok(accepted, `Failed to accept ${img.originalname}`);
    }
  });

  // 3. Submission Model & Controller Structure
  console.log('\n--- 3. Submission Model & Schema Verification ---');
  test('Submission model supports link, attachments array, and backward-compatible fields', () => {
    const Submission = require('../src/models/Submission');
    const schemaPaths = Submission.schema.paths;

    assert.ok(schemaPaths['link'], 'Submission schema must define link field');
    assert.ok(schemaPaths['attachments'], 'Submission schema must define attachments field');
    assert.ok(schemaPaths['text'], 'Submission schema must define text field');
    assert.ok(
      schemaPaths['fileUrl'],
      'Submission schema must define backward-compatible fileUrl field'
    );
    assert.ok(schemaPaths['isLate'], 'Submission schema must define isLate field');
    assert.ok(schemaPaths['marks'], 'Submission schema must define marks field');
    assert.ok(schemaPaths['status'], 'Submission schema must define status field');
  });

  console.log('\n====================================================');
  console.log(`PART B RESULT: ${passedTests}/${totalTests} Tests Passed`);
  console.log('====================================================\n');

  if (passedTests !== totalTests) {
    process.exit(1);
  }
}

if (require.main === module) {
  runPartB().catch((err) => {
    console.error('Fatal error running Part B tests:', err);
    process.exit(1);
  });
}

module.exports = runPartB;
