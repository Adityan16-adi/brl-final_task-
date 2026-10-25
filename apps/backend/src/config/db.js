const dns = require("dns");
const mongoose = require("mongoose");

let memoryServer = null;

const connectDB = async () => {
  const uri = process.env.MONGO_URI || process.env.MONGODB_URI;

  // 1. If MONGO_URI is specified, try connecting to it first
  if (uri) {
    try {
      await mongoose.connect(uri, { serverSelectionTimeoutMS: 3000 });
      console.log("MongoDB connected successfully!");
      return;
    } catch (error) {
      if (uri.startsWith("mongodb+srv://") && error.message && error.message.includes("querySrv")) {
        try {
          console.warn("Local DNS failed SRV query. Retrying MongoDB Atlas connection with public DNS resolvers...");
          dns.setServers(["8.8.8.8", "1.1.1.1"]);
          await mongoose.connect(uri);
          console.log("MongoDB connected successfully via public DNS resolvers!");
          return;
        } catch (retryError) {
          console.error("MongoDB connection failed on retry:", retryError.message);
        }
      } else {
        console.warn(`Could not connect to external MongoDB at ${uri}: ${error.message}`);
      }
    }
  }

  // 2. In non-production environments, start an in-memory MongoDB instance to ensure zero crashes
  if (process.env.NODE_ENV !== "production") {
    try {
      console.warn("Starting local in-memory MongoDB server for development...");
      const { MongoMemoryServer } = require("mongodb-memory-server");
      memoryServer = await MongoMemoryServer.create();
      const memoryUri = memoryServer.getUri();
      await mongoose.connect(memoryUri);
      console.log(`Development MongoDB connected successfully at ${memoryUri}`);
      return;
    } catch (memError) {
      console.error("Failed to start development in-memory MongoDB:", memError.message);
    }
  }

  // 3. In strict production or if memory server fails, fail closed
  console.error("MongoDB connection failed: No reachable MongoDB database found.");
  process.exit(1);
};

module.exports = connectDB;
