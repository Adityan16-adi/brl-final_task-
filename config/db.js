const dns = require("dns");
const mongoose = require("mongoose");

const connectDB = async () => {
    const uri = process.env.MONGO_URI;
    if (!uri) {
        console.error("MongoDB connection failed: MONGO_URI is not set in environment.");
        process.exit(1);
    }

    try {
        await mongoose.connect(uri);
        console.log("MongoDB connected successfully!");
    } catch (error) {
        // If SRV lookup fails due to local router/ISP DNS refusing SRV queries, retry with public DNS
        if (uri.startsWith("mongodb+srv://") && error.message && error.message.includes("querySrv")) {
            try {
                console.warn("Local DNS failed SRV query. Retrying MongoDB Atlas connection with public DNS resolvers...");
                dns.setServers(["8.8.8.8", "1.1.1.1"]);
                await mongoose.connect(uri);
                console.log("MongoDB connected successfully via public DNS resolvers!");
                return;
            } catch (retryError) {
                console.error("MongoDB connection failed on retry:", retryError.message);
                process.exit(1);
            }
        }

        console.error("MongoDB connection failed:", error.message);
        process.exit(1);
    }
};

module.exports = connectDB;
