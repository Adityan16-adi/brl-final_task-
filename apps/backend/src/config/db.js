const mongoose = require("mongoose");

const connectDB = async () => {
  const uri = process.env.MONGO_URI;
  if (!uri?.trim()) throw new Error("MONGO_URI is required before connecting to MongoDB.");
  mongoose.connection.on("error", (error) => {
    console.error("MongoDB connection error:", error.name || "UnknownError");
  });
  try {
    await mongoose.connect(uri, { serverSelectionTimeoutMS: 10000 });
  } catch (error) {
    throw new Error(`MongoDB connection failed (${error.name || "unknown error"}). Check MONGO_URI and database network access.`);
  }
  console.log("MongoDB connected");
  return mongoose.connection;
};

const closeDB = async () => {
  if (mongoose.connection.readyState !== 0) {
    await mongoose.disconnect();
  }
};

module.exports = connectDB;
module.exports.closeDB = closeDB;
