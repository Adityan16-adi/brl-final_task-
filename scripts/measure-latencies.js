const path = require('path');
const fs = require('fs');

async function measure() {
  const rootDir = path.resolve(__dirname, '..');
  require('dotenv').config({ path: path.join(rootDir, '.env') });
  
  let mlApiKey = process.env.ML_API_TOKEN;
  const mlEnvPath = path.join(rootDir, 'ml_service', '.env');
  if (!mlApiKey && fs.existsSync(mlEnvPath)) {
    const lines = fs.readFileSync(mlEnvPath, 'utf8').split(/\r?\n/);
    for (const l of lines) {
      const match = l.match(/^(?:ML_API_TOKEN|Ml_API_TOKEN)\s*=\s*(.*)$/i);
      if (match) mlApiKey = match[1].trim();
    }
  }

  const mlUrl = (process.env.ML_SERVICE_URL || 'https://brl-final-task.onrender.com').replace(/\/+$/, '');
  console.log(`ML Base URL: ${mlUrl}`);
  console.log(`ML_API_TOKEN configured: ${!!mlApiKey}\n`);

  async function timeRequest(name, url, options) {
    const start = performance.now();
    try {
      const res = await fetch(url, options);
      const elapsed = ((performance.now() - start) / 1000).toFixed(3);
      const isJson = (res.headers.get('content-type') || '').includes('application/json');
      const data = isJson ? await res.json().catch(() => null) : null;
      console.log(`[${name}] Status: ${res.status} | Latency: ${elapsed}s`);
      return { name, status: res.status, latency: elapsed, data };
    } catch (err) {
      const elapsed = ((performance.now() - start) / 1000).toFixed(3);
      console.log(`[${name}] Error: ${err.message} | Latency: ${elapsed}s`);
      return { name, error: err.message, latency: elapsed };
    }
  }

  // 1. Health check / warm-up
  console.log('--- 1. Service Health Warm-up ---');
  await timeRequest('Health Ping', `${mlUrl}/health`, {
    signal: AbortSignal.timeout(60000),
  });

  // 2. Spam check allow (harmless message)
  console.log('\n--- 2. Spam Check Allow (clean message) ---');
  await timeRequest('Spam Allow', `${mlUrl}/spam/check`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'X-API-Key': mlApiKey || '',
      'X-User-Id': 'measure-user-01',
    },
    body: JSON.stringify({
      meeting_id: 'measure-meeting-1',
      user_id: 'measure-user-01',
      message: 'Hello class, remember we have office hours at 4 PM today.',
    }),
    signal: AbortSignal.timeout(30000),
  });

  // 3. Spam check warn (spam message)
  console.log('\n--- 3. Spam Check Warn (flagged spam) ---');
  await timeRequest('Spam Warn', `${mlUrl}/spam/check`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'X-API-Key': mlApiKey || '',
      'X-User-Id': 'measure-user-02',
    },
    body: JSON.stringify({
      meeting_id: 'measure-meeting-1',
      user_id: 'measure-user-02',
      message: 'BUY BITCOIN NOW FREE MONEY CLICK http://scam.xyz http://free-coins.win',
    }),
    signal: AbortSignal.timeout(30000),
  });

  // 4. Missing token rejection (verify 401/403)
  console.log('\n--- 4. Missing Token Rejection ---');
  await timeRequest('Missing Token Rejection', `${mlUrl}/spam/check`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'X-User-Id': 'measure-user-03',
    },
    body: JSON.stringify({
      meeting_id: 'measure-meeting-1',
      user_id: 'measure-user-03',
      message: 'Hello',
    }),
    signal: AbortSignal.timeout(30000),
  });

  // 5. Mentor chat reply
  console.log('\n--- 5. AI Mentor Chat Reply ---');
  await timeRequest('Mentor Chat', `${mlUrl}/mentor/chat`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'X-API-Key': mlApiKey || '',
      'X-User-Id': 'measure-user-01',
    },
    body: JSON.stringify({
      session_id: 'measure-session-01',
      message: 'What is Newton\'s first law in simple words?',
    }),
    signal: AbortSignal.timeout(60000),
  });
}

measure();
