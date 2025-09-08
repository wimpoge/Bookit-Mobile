# 📧 Email Setup Guide

## Quick Setup for Gmail

1. **Enable 2-Factor Authentication** on your Gmail account
2. **Generate an App Password**:
   - Go to Google Account settings
   - Security → 2-Step Verification → App Passwords
   - Select "Mail" and generate a password
3. **Update your `.env` file**:

```env
# Email Configuration
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USERNAME=your-email@gmail.com
SMTP_PASSWORD=your-16-character-app-password
SMTP_USE_TLS=true
FROM_EMAIL=BookIt <your-email@gmail.com>
FRONTEND_URL=http://localhost:3000
```

## Alternative SMTP Providers

### Outlook/Hotmail
```env
SMTP_HOST=smtp-mail.outlook.com
SMTP_PORT=587
SMTP_USERNAME=your-email@outlook.com
SMTP_PASSWORD=your-password
```

### Yahoo Mail
```env
SMTP_HOST=smtp.mail.yahoo.com
SMTP_PORT=587
SMTP_USERNAME=your-email@yahoo.com
SMTP_PASSWORD=your-app-password
```

## Development Mode

If you don't configure email credentials, the system will:
- ✅ Still accept forgot password requests
- ✅ Generate secure reset tokens
- ✅ Log email details to console
- ✅ Return success responses
- ⚠️ Skip actual email sending

This allows you to test the forgot password flow without email setup.

## Testing the Email

1. Set up your email credentials in `.env`
2. Restart the backend server
3. Go to the app and click "Forgot Password"
4. Check your email for the beautiful reset message!

## Security Notes

- Never commit your `.env` file to version control
- Use App Passwords, not your regular password
- The reset tokens expire in 1 hour for security
- The system doesn't reveal if an email exists (security best practice)