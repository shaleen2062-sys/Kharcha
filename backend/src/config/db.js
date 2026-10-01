const mongoose = require("mongoose");
const dns = require("dns");

const connectDB = async () => {
  dns.setServers(["8.8.8.8", "1.1.1.1"]);

  try {
    await mongoose.connect(process.env.MONGO_URI);
    console.log("Connected to MongoDB");
  } catch (error) {
    console.error("MongoDB connection error:", error);
    process.exit(1); 
  }
};

module.exports = connectDB;