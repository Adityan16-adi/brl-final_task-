const User = require("../models/User");

const syncUser = async (req, res) => {
    try {
        const { uid, email, name } = req.user;

        if (!email) {
            return res.status(400).json({
                success: false,
                message: "Email is required"
            });
        }

        const user = await User.findOneAndUpdate(
            { uid },
            {
                uid,
                email,
                name: name || email.split("@")[0]
            },
            {
                new: true,
                upsert: true,
                runValidators: true,
                setDefaultsOnInsert: true
            }
        );

        res.status(200).json({
            success: true,
            message: "User profile synced successfully",
            user
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            message: "Failed to sync user profile"
        });
    }
};

module.exports = { syncUser };