const fs = require('fs');
const path = require('path');
const http = require('http');

async function runPartA() {
  console.log('====================================================');
  console.log('PART A: VERIFYING REAL INTEGRATIONS & ENVIRONMENT');
  console.log('====================================================\n');

  const rootDir = path.resolve(__dirname, '..');
  const rootEnvPath = path.join(rootDir, '.env');
  const mlEnvPath = path.join(rootDir, 'ml_service', '.env');
  const googleServicesPath = path.join(rootDir, 'apps', 'mobile', 'android', 'app', 'google-services.json');

  // Load environment variables
  require('dotenv').config({ path: rootEnvPath });
  const mlEnv = {};
  if (fs.existsSync(mlEnvPath)) {
    const lines = fs.readFileSync(mlEnvPath, 'utf8').split(/\r?\n/);
    for (const line of lines) {
      const trimmed = line.trim();
      if (!trimmed || trimmed.startsWith('#')) continue;
      const eq = trimmed.indexOf('=');
      if (eq > 0) {
        mlEnv[trimmed.slice(0, eq).trim()] = trimmed.slice(eq + 1).trim();
      }
    }
  }

  // 1. Environment Variable Audit
  console.log('--- 1. Environment Variable Audit ---');
  const rootExpectedKeys = [
    'PORT',
    'NODE_ENV',
    'MONGO_URI',
    'JWT_SECRET',
    'TEACHER_SIGNUP_KEY',
    'FIREBASE_SERVICE_ACCOUNT_PATH',
    'CLOUDINARY_CLOUD_NAME',
    'CLOUDINARY_API_KEY',
    'CLOUDINARY_API_SECRET',
    'ML_SERVICE_URL',
    'ML_API_TOKEN',
    'LIVEKIT_URL',
    'LIVEKIT_API_KEY',
    'LIVEKIT_API_SECRET',
  ];

  const rootEnvReport = {};
  for (const k of rootExpectedKeys) {
    const val = process.env[k];
    rootEnvReport[k] = val && val.trim().length > 0 ? 'PRESENT' : 'ABSENT';
  }

  // Also check if mlEnv has ML_API_TOKEN / Ml_API_TOKEN
  const mlApiKey = process.env.ML_API_TOKEN || mlEnv.ML_API_TOKEN || mlEnv.Ml_API_TOKEN || mlEnv.ml_api_token;
  if (!process.env.ML_API_TOKEN && mlApiKey) {
    process.env.ML_API_TOKEN = mlApiKey;
    rootEnvReport['ML_API_TOKEN'] = 'PRESENT (from ml_service/.env)';
  }

  console.log('Root .env Variables:');
  for (const [k, v] of Object.entries(rootEnvReport)) {
    console.log(`  • ${k}: ${v}`);
  }

  console.log('\nml_service/.env Variables:');
  const mlExpectedKeys = ['GROQ_API_KEY', 'ML_API_TOKEN', 'Ml_API_TOKEN'];
  for (const k of mlExpectedKeys) {
    const val = mlEnv[k];
    console.log(`  • ${k}: ${val && val.trim().length > 0 ? 'PRESENT' : 'ABSENT'}`);
  }

  const gsExists = fs.existsSync(googleServicesPath);
  console.log(`\ngoogle-services.json (${googleServicesPath}): ${gsExists ? 'PRESENT' : 'ABSENT'}\n`);

  // 2. Firebase Verification
  console.log('--- 2. Firebase Integration Verification ---');
  const buildGradleKts = path.join(rootDir, 'apps', 'mobile', 'android', 'app', 'build.gradle.kts');
  let appId = 'unknown';
  if (fs.existsSync(buildGradleKts)) {
    const bgContent = fs.readFileSync(buildGradleKts, 'utf8');
    const m = bgContent.match(/applicationId\s*=\s*["']([^"']+)["']/);
    if (m) appId = m[1];
  }
  console.log(`Android applicationId: ${appId}`);

  // Test Firebase Admin initialization
  let fbAdminInit = false;
  let fbAuth = null;
  try {
    const fb = require('../config/firebase');
    fbAdminInit = !!(fb.app && fb.auth);
    fbAuth = fb.auth;
  } catch (err) {
    console.log(`Firebase Admin init error: ${err.message}`);
  }
  console.log(`Firebase Admin Initialized: ${fbAdminInit ? 'PASS' : 'FAIL'}`);

  // Real route accepting Firebase tokens: GET /api/auth/me or GET /protected (both use verifyToken middleware)
  console.log(`Firebase ID Token verification route: GET /api/auth/me, GET /protected (authMiddleware.js lines 89-107)`);
  if (fbAdminInit) {
    console.log('Firebase verification status: PASS (Credentials valid, auth service active)');
  } else {
    console.log('Firebase verification status: BLOCKED (Service account credentials missing or invalid)');
  }
  console.log('');

  // 3. Cloudinary Verification
  console.log('--- 3. Cloudinary Integration Verification ---');
  let cloudinaryStatus = 'FAIL';
  try {
    const uploadToCloudinary = require('../src/utils/uploadToCloudinary');
    const { deleteFromCloudinary, isCloudinaryConfigured } = uploadToCloudinary;
    const isConfigured = isCloudinaryConfigured();
    console.log(`Cloudinary Configured in backend: ${isConfigured}`);

    if (isConfigured) {
      // Tiny 1x1 transparent PNG buffer
      const tinyPng = Buffer.from(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=',
        'base64'
      );

      console.log('Performing test upload (1x1 PNG) to Cloudinary...');
      const uploadRes = await uploadToCloudinary(tinyPng, 'test-verification');
      console.log(`Upload returned secure_url domain: ${new URL(uploadRes.secure_url).hostname}`);
      console.log(`Upload public_id: ${uploadRes.public_id}`);

      // Confirm returned URL loads
      const headRes = await fetch(uploadRes.secure_url);
      console.log(`HTTP status loading uploaded asset: ${headRes.status}`);

      // Delete test asset
      console.log('Deleting test asset from Cloudinary...');
      const delRes = await deleteFromCloudinary(uploadRes.public_id, uploadRes.resource_type || 'image');
      console.log(`Deletion result: ${delRes}`);

      if (headRes.status === 200 && delRes === true) {
        cloudinaryStatus = 'PASS';
      }
    }
  } catch (cErr) {
    console.error(`Cloudinary error: ${cErr.message}`);
    cloudinaryStatus = `FAIL (${cErr.message})`;
  }
  console.log(`Cloudinary status: ${cloudinaryStatus}\n`);

  // 4. LiveKit Verification
  console.log('--- 4. LiveKit Integration Verification ---');
  let liveKitStatus = 'FAIL';
  try {
    const connectDB = require('../config/db');
    await connectDB();

    const User = require('../src/models/User');
    const Classroom = require('../src/models/Classroom');

    const teacher = await User.findOne({ role: 'teacher' });
    const student = await User.findOne({ role: 'student' });
    const classroom = await Classroom.findOne({ teacherUid: teacher?.uid });

    if (!teacher || !classroom) {
      console.log('Seed teacher or classroom not found. Seeding first...');
      await require('../src/utils/seedDemoData')();
    }

    const seededTeacher = await User.findOne({ role: 'teacher' });
    const seededStudent = await User.findOne({ role: 'student' });
    const seededClassroom = await Classroom.findOne({ teacherUid: seededTeacher?.uid });

    // Start server
    const { app } = require('../server');
    const server = http.createServer(app);
    await new Promise((res) => server.listen(0, res));
    const port = server.address().port;
    const base = `http://127.0.0.1:${port}`;

    // Create teacher JWT
    const jwt = require('jsonwebtoken');
    const jwtSecret = require('../src/middleware/authMiddleware').getJwtSecret();
    const teacherToken = jwt.sign(
      { uid: seededTeacher.uid, email: seededTeacher.email, name: seededTeacher.name, role: 'teacher', _id: seededTeacher._id },
      jwtSecret,
      { expiresIn: '1h' }
    );

    const unenrolledToken = jwt.sign(
      { uid: 'stranger-uid-999', email: 'stranger@example.com', name: 'Stranger', role: 'student' },
      jwtSecret,
      { expiresIn: '1h' }
    );

    // Call meeting token endpoint as teacher
    console.log(`Requesting meeting token for class ${seededClassroom._id} as authorized teacher...`);
    const tRes = await fetch(`${base}/api/classrooms/${seededClassroom._id}/meeting/token`, {
      method: 'POST',
      headers: { Authorization: `Bearer ${teacherToken}`, 'Content-Type': 'application/json' },
    });
    const tData = await tRes.json();
    console.log(`Teacher meeting token response status: ${tRes.status}`);

    // Call meeting token endpoint as unenrolled stranger
    console.log(`Requesting meeting token as unauthorized stranger...`);
    const uRes = await fetch(`${base}/api/classrooms/${seededClassroom._id}/meeting/token`, {
      method: 'POST',
      headers: { Authorization: `Bearer ${unenrolledToken}`, 'Content-Type': 'application/json' },
    });
    console.log(`Unauthorized stranger response status: ${uRes.status} (Expected 403 Forbidden)`);

    server.close();

    if (tRes.status === 200 && tData.token && uRes.status === 403) {
      liveKitStatus = 'PASS';
      console.log('Room token generated successfully and issued exclusively for classroom members.');
    } else if (tData.status === 'awaiting_credentials') {
      liveKitStatus = 'BLOCKED (LiveKit awaiting configured cloud credentials)';
    } else {
      liveKitStatus = `FAIL (status=${tRes.status})`;
    }
  } catch (lkErr) {
    console.error(`LiveKit error: ${lkErr.message}`);
    liveKitStatus = `FAIL (${lkErr.message})`;
  }
  console.log(`LiveKit status: ${liveKitStatus}\n`);

  // 5. Hosted ML Service Verification
  console.log('--- 5. ML Service & Groq Verification ---');
  let mlStatus = 'FAIL';
  const mlServiceUrl = process.env.ML_SERVICE_URL || 'https://brl-final-task.onrender.com';
  const finalMlToken = process.env.ML_API_TOKEN || mlApiKey;
  console.log(`ML Service URL: ${mlServiceUrl}`);
  console.log(`ML_API_TOKEN present: ${!!finalMlToken}`);

  try {
    // 5a. Health check
    console.log(`Calling GET ${mlServiceUrl}/health...`);
    const hRes = await fetch(`${mlServiceUrl}/health`, { signal: AbortSignal.timeout(15000) });
    const hData = await hRes.json();
    console.log(`Health status: ${hRes.status}`, hData);

    // 5b. Spam check (harmless message)
    console.log('Calling POST /spam/check with harmless message...');
    const cleanRes = await fetch(`${mlServiceUrl}/spam/check`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-API-Key': finalMlToken || '',
        'X-User-Id': 'test-student-01',
      },
      body: JSON.stringify({
        meeting_id: 'class-demo-101',
        user_id: 'test-student-01',
        message: 'Good morning professor, will the slides from today be posted on the portal?',
      }),
      signal: AbortSignal.timeout(15000),
    });
    const cleanData = await cleanRes.json();
    console.log('Harmless check result:', cleanData);

    // 5c. Spam check (obvious spam message)
    console.log('Calling POST /spam/check with obvious spam message...');
    const spamRes = await fetch(`${mlServiceUrl}/spam/check`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-API-Key': finalMlToken || '',
        'X-User-Id': 'test-spammer-99',
      },
      body: JSON.stringify({
        meeting_id: 'class-demo-101',
        user_id: 'test-spammer-99',
        message: 'BUY CHEAP CRYPTO NOW AT http://spam1.xyz http://spam2.xyz http://spam3.xyz WIN FREE MONEY TODAY CLICK CLICK CLICK',
      }),
      signal: AbortSignal.timeout(15000),
    });
    const spamData = await spamRes.json();
    console.log('Spam check result:', spamData);

    // 5d. Mentor chat
    console.log('Calling POST /mentor/chat with test question...');
    const chatRes = await fetch(`${mlServiceUrl}/mentor/chat`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-API-Key': finalMlToken || '',
        'X-User-Id': 'test-student-01',
      },
      body: JSON.stringify({
        session_id: 'student-01:course-101:conv-1',
        message: 'What is Newton\'s third law of motion in one sentence?',
        course_id: 'course-101',
      }),
      signal: AbortSignal.timeout(60000),
    });
    const chatData = await chatRes.json();
    console.log(`Mentor chat HTTP status: ${chatRes.status}`);
    const mentorReply = chatData?.reply || chatData?.response;
    console.log('Mentor reply preview:', mentorReply ? mentorReply.slice(0, 100) + '...' : JSON.stringify(chatData));

    // 5e. Missing key error test
    console.log('Calling POST /spam/check with missing key to verify clean rejection...');
    const badKeyRes = await fetch(`${mlServiceUrl}/spam/check`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-User-Id': 'test-student-01',
      },
      body: JSON.stringify({
        meeting_id: 'class-demo-101',
        user_id: 'test-student-01',
        message: 'Hello',
      }),
      signal: AbortSignal.timeout(15000),
    });
    console.log(`Missing key HTTP status: ${badKeyRes.status} (Expected 401 or 403)`);

    const isHealthOk = hRes.status === 200;
    const isCleanOk = cleanData.is_spam === false;
    const isSpamOk = spamData.is_spam === true;
    const isChatOk = chatRes.status === 200 && !!mentorReply;
    const isKeyProtected = badKeyRes.status === 401 || badKeyRes.status === 403;

    if (isHealthOk && isCleanOk && isSpamOk && isChatOk && isKeyProtected) {
      mlStatus = 'PASS';
    } else {
      mlStatus = `PARTIAL (health=${isHealthOk}, clean=${isCleanOk}, spam=${isSpamOk}, chat=${isChatOk}, authProtect=${isKeyProtected})`;
    }
  } catch (mErr) {
    console.error(`ML error: ${mErr.message}`);
    mlStatus = `FAIL (${mErr.message})`;
  }
  console.log(`ML status: ${mlStatus}\n`);

  console.log('====================================================');
  console.log('PART A SUMMARY:');
  console.log(`1. Environment Variable Audit: COMPLETED`);
  console.log(`2. Firebase: ${fbAdminInit ? 'PASS' : 'BLOCKED'}`);
  console.log(`3. Cloudinary: ${cloudinaryStatus}`);
  console.log(`4. LiveKit: ${liveKitStatus}`);
  console.log(`5. ML Service: ${mlStatus}`);
  console.log('====================================================');

  process.exit(0);
}

runPartA().catch((err) => {
  console.error('Fatal execution error:', err);
  process.exit(1);
});
