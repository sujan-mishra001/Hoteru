require('dotenv').config();
const express = require('express');
const nodemailer = require('nodemailer');
const cors = require('cors');
const bodyParser = require('body-parser');

const app = express();
const PORT = 3000;

app.use(cors());
app.use(bodyParser.json());

// In-memory store for OTPs (For production, use Redis or a Database)
const otpStore = new Map();

const admin = require('firebase-admin');

// Service Account Setup
// 1. Go to Firebase Console -> Project Settings -> Service Accounts
// 2. Click "Generate New Private Key"
// 3. Save the file as "serviceAccountKey.json" in this folder (otp_server)
try {
    const serviceAccount = require('./serviceAccountKey.json');
    admin.initializeApp({
        credential: admin.credential.cert(serviceAccount)
    });
    console.log("Firebase Admin Initialized");
} catch (e) {
    console.warn("WARNING: serviceAccountKey.json not found. Password reset will fail.");
}

const transporter = nodemailer.createTransport({
    service: 'gmail',
    auth: {
        user: process.env.EMAIL_USER,
        pass: process.env.EMAIL_PASS
    }
});

// Endpoint: Send OTP
app.post('/send-otp', async (req, res) => {
    const { email, type } = req.body; // type can be 'signup' or 'reset'

    if (!email) {
        return res.status(400).json({ success: false, message: 'Email is required' });
    }

    // Generate 6 digit OTP
    const otp = Math.floor(100000 + Math.random() * 900000).toString();

    // Store with expiry (5 minutes)
    otpStore.set(email, {
        code: otp,
        expires: Date.now() + 5 * 60 * 1000
    });

    // Template Selection
    let subject = 'Your Verification Code';
    let title = 'Verify your email address';
    let message = 'Thanks for starting the new account creation process. We want to make sure it\'s really you. Please enter the following verification code when prompted.';
    let actionText = 'Verification Code';

    if (type === 'reset') {
        // Verify User Exists first
        try {
            await admin.auth().getUserByEmail(email);
        } catch (error) {
            if (error.code === 'auth/user-not-found') {
                return res.json({ success: false, message: 'User does not exist' });
            }
            // For other errors, log but maybe don't block (or block if critical)
            console.error('Check user error:', error);
        }

        subject = 'Reset Your Password';
        title = 'Password Reset Request';
        message = 'We received a request to reset your password for your Dautari Adda account. Enter the code below to set a new password.';
        actionText = 'Reset Code';
    }

    const mailOptions = {
        from: `Dautari Adda <${process.env.EMAIL_USER}>`,
        to: email,
        subject: subject,
        html: `
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>${subject}</title>
        </head>
        <body style="margin: 0; padding: 0; font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #f4f7f6;">
            <table border="0" cellpadding="0" cellspacing="0" width="100%" style="max-width: 600px; margin: 0 auto; background-color: #ffffff; margin-top: 40px; border-radius: 16px; overflow: hidden; box-shadow: 0 4px 12px rgba(0,0,0,0.05);">
                <!-- Header -->
                <tr>
                    <td style="background-color: #2D3436; padding: 30px; text-align: center;">
                        <h1 style="color: #FFC107; margin: 0; font-size: 28px; font-weight: 700; letter-spacing: 1px;">Dautari Adda</h1>
                    </td>
                </tr>
                
                <!-- Body -->
                <tr>
                    <td style="padding: 40px 30px;">
                        <h2 style="color: #2D3436; font-size: 22px; margin-top: 0; margin-bottom: 20px;">${title}</h2>
                        <p style="color: #636e72; font-size: 16px; line-height: 1.6; margin-bottom: 30px;">
                            ${message}
                        </p>
                        
                        <!-- OTP Box -->
                        <div style="background-color: #f9f9f9; border-radius: 12px; padding: 20px; text-align: center; margin-bottom: 30px; border: 1px dashed #FFC107;">
                            <span style="display: block; color: #b2bec3; font-size: 14px; margin-bottom: 10px; text-transform: uppercase; letter-spacing: 1px;">${actionText}</span>
                            <span style="font-size: 36px; font-weight: 800; color: #2D3436; letter-spacing: 8px;">${otp}</span>
                        </div>
                        
                        <p style="color: #636e72; font-size: 15px; line-height: 1.6; margin-bottom: 0;">
                            This code will expire in <strong style="color: #d63031;">5 minutes</strong>. If you didn't request this, you can safely ignore this email.
                        </p>
                    </td>
                </tr>
                
                <!-- Footer -->
                <tr>
                    <td style="background-color: #f1f2f6; padding: 20px; text-align: center;">
                        <p style="color: #b2bec3; font-size: 12px; margin: 0;">
                            &copy; ${new Date().getFullYear()} Dautari Adda. All rights reserved.
                        </p>
                    </td>
                </tr>
            </table>
        </body>
        </html>
        `
    };

    try {
        await transporter.sendMail(mailOptions);
        console.log(`OTP (${type}) sent to ${email}`);
        res.json({ success: true, message: 'OTP sent successfully' });
    } catch (error) {
        console.error('Error sending email:', error);
        res.status(500).json({ success: false, message: 'Failed to send OTP' });
    }
});

// Endpoint: Verify OTP
app.post('/verify-otp', (req, res) => {
    const { email, code } = req.body;

    if (!email || !code) {
        return res.status(400).json({ success: false, message: 'Email and code required' });
    }

    const record = otpStore.get(email);

    if (!record) {
        return res.json({ success: false, message: 'No OTP found for this email' });
    }

    if (Date.now() > record.expires) {
        otpStore.delete(email);
        return res.json({ success: false, message: 'OTP expired' });
    }

    if (record.code === code) {
        otpStore.delete(email); // consume OTP
        return res.json({ success: true, message: 'OTP Verified' });
    } else {
        return res.json({ success: false, message: 'Invalid OTP' });
    }
});

// Endpoint: Complete Password Reset
app.post('/complete-password-reset', async (req, res) => {
    const { email, code, newPassword } = req.body;

    if (!email || !code || !newPassword) {
        return res.status(400).json({ success: false, message: 'Missing fields' });
    }

    // 1. Verify OTP
    const record = otpStore.get(email);
    if (!record) return res.json({ success: false, message: 'Invalid or expired OTP' });
    if (Date.now() > record.expires) {
        otpStore.delete(email);
        return res.json({ success: false, message: 'OTP expired' });
    }
    if (record.code !== code) return res.json({ success: false, message: 'Invalid OTP' });

    // 2. Update Password in Firebase
    try {
        const userRecord = await admin.auth().getUserByEmail(email);
        await admin.auth().updateUser(userRecord.uid, {
            password: newPassword
        });

        otpStore.delete(email); // consume OTP
        console.log(`Password reset for ${email}`);
        res.json({ success: true, message: 'Password updated successfully' });
    } catch (error) {
        console.error('Error updating password:', error);
        res.status(500).json({ success: false, message: 'Failed to update password: ' + error.message });
    }
});

app.listen(PORT, () => {
    console.log(`Server running on http://localhost:${PORT}`);
});
