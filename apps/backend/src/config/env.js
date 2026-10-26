const path = require("path");
const dotenv = require("dotenv");

const envPath = path.resolve(__dirname, "../../.env");
dotenv.config({ path: envPath });

function validateEnv() {
  const missing = ["MONGO_URI", "CLOUDINARY_CLOUD_NAME", "CLOUDINARY_API_KEY", "CLOUDINARY_API_SECRET", "FIREBASE_PROJECT_ID"]
    .filter((name) => !process.env[name]?.trim());
  if (missing.length) {
    throw new Error(`Missing required backend environment variable(s): ${missing.join(", ")}. Configure apps/backend/.env using apps/backend/.env.example.`);
  }
  const port = Number(process.env.PORT || 5000);
  if (!Number.isInteger(port) || port < 1 || port > 65535) {
    throw new Error("PORT must be an integer from 1 to 65535.");
  }
  return { port };
}

module.exports = { envPath, validateEnv };
