import aiosmtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from email.mime.base import MIMEBase
from email import encoders
import os
from typing import List, Optional
from jinja2 import Environment, FileSystemLoader
import logging

logger = logging.getLogger(__name__)

class EmailService:
    def __init__(self):
        self.smtp_host = os.getenv("SMTP_HOST", "smtp.gmail.com")
        self.smtp_port = int(os.getenv("SMTP_PORT", "587"))
        self.smtp_username = os.getenv("SMTP_USERNAME", "")
        self.smtp_password = os.getenv("SMTP_PASSWORD", "")
        self.use_tls = os.getenv("SMTP_USE_TLS", "true").lower() == "true"
        self.from_email = os.getenv("FROM_EMAIL", "BookIt <noreply@bookit.com>")
        self.frontend_url = os.getenv("FRONTEND_URL", "http://localhost:3000")
        
        # Check if email is properly configured
        self.is_configured = bool(self.smtp_username and self.smtp_password)
        
        if not self.is_configured:
            logger.warning("Email service not configured. Set SMTP_USERNAME and SMTP_PASSWORD in .env file")
        
        # Set up Jinja2 environment for email templates
        template_dir = os.path.join(os.path.dirname(__file__), "..", "templates", "emails")
        try:
            self.jinja_env = Environment(
                loader=FileSystemLoader(template_dir),
                autoescape=True
            )
        except Exception as e:
            logger.error(f"Failed to initialize email templates: {e}")
            self.jinja_env = None
    
    async def send_email(
        self,
        to_email: str,
        subject: str,
        html_body: str,
        text_body: Optional[str] = None,
        attachments: Optional[List[str]] = None
    ) -> bool:
        """
        Send an email using SMTP
        """
        # Check if email service is configured
        if not self.is_configured:
            logger.warning(f"Email service not configured, skipping email to {to_email}")
            logger.info(f"Email preview - Subject: {subject}")
            logger.info(f"Email preview - To: {to_email}")
            return True  # Return True for development/testing
        
        try:
            # Create message
            message = MIMEMultipart("alternative")
            message["From"] = self.from_email
            message["To"] = to_email
            message["Subject"] = subject
            
            # Add text version if provided
            if text_body:
                text_part = MIMEText(text_body, "plain", "utf-8")
                message.attach(text_part)
            
            # Add HTML version
            html_part = MIMEText(html_body, "html", "utf-8")
            message.attach(html_part)
            
            # Add attachments if provided
            if attachments:
                for file_path in attachments:
                    if os.path.isfile(file_path):
                        with open(file_path, "rb") as attachment:
                            part = MIMEBase("application", "octet-stream")
                            part.set_payload(attachment.read())
                            encoders.encode_base64(part)
                            part.add_header(
                                "Content-Disposition",
                                f"attachment; filename= {os.path.basename(file_path)}",
                            )
                            message.attach(part)
            
            # Connect and send email
            async with aiosmtplib.SMTP(
                hostname=self.smtp_host,
                port=self.smtp_port,
                use_tls=False,  # We'll start TLS manually
            ) as server:
                if self.use_tls:
                    await server.starttls()
                
                await server.login(self.smtp_username, self.smtp_password)
                await server.send_message(message)
                
                logger.info(f"Email sent successfully to {to_email}")
                return True
                
        except Exception as e:
            logger.error(f"Failed to send email to {to_email}: {str(e)}")
            return False
    
    async def send_password_reset_email(self, to_email: str, reset_token: str, user_name: str = "") -> bool:
        """
        Send a password reset email with a beautiful HTML template
        """
        try:
            # Check if templates are available
            if not self.jinja_env:
                logger.error("Email templates not available")
                return False
                
            # Load the HTML template
            template = self.jinja_env.get_template("password_reset.html")
            
            # Create reset link
            reset_link = f"{self.frontend_url}/reset-password?token={reset_token}"
            
            # Render the template with variables
            html_body = template.render(
                user_name=user_name or to_email.split('@')[0].title(),
                reset_link=reset_link,
                support_email="support@bookit.com",
                company_name="BookIt",
                frontend_url=self.frontend_url
            )
            
            # Create text version for better compatibility
            text_body = f"""
Hi {user_name or to_email.split('@')[0].title()},

You recently requested to reset your password for your BookIt account. Click the link below to reset it:

{reset_link}

If you did not request a password reset, please ignore this email or contact our support team.

This link will expire in 1 hour for security reasons.

Best regards,
The BookIt Team

If you're having trouble clicking the reset link, copy and paste the following URL into your web browser:
{reset_link}
            """.strip()
            
            subject = "Reset Your BookIt Password"
            
            return await self.send_email(
                to_email=to_email,
                subject=subject,
                html_body=html_body,
                text_body=text_body
            )
            
        except Exception as e:
            logger.error(f"Failed to send password reset email to {to_email}: {str(e)}")
            return False
    
    async def send_welcome_email(self, to_email: str, user_name: str) -> bool:
        """
        Send a welcome email to new users
        """
        try:
            # Check if templates are available
            if not self.jinja_env:
                logger.error("Email templates not available")
                return False
                
            template = self.jinja_env.get_template("welcome.html")
            
            html_body = template.render(
                user_name=user_name,
                company_name="BookIt",
                frontend_url=self.frontend_url,
                support_email="support@bookit.com"
            )
            
            text_body = f"""
Welcome to BookIt, {user_name}!

Thank you for joining BookIt, your trusted partner for finding and booking the perfect accommodations.

Get started by exploring our featured hotels and destinations at: {self.frontend_url}

If you have any questions, feel free to reach out to our support team at support@bookit.com

Happy travels!
The BookIt Team
            """.strip()
            
            subject = f"Welcome to BookIt, {user_name}! 🏨"
            
            return await self.send_email(
                to_email=to_email,
                subject=subject,
                html_body=html_body,
                text_body=text_body
            )
            
        except Exception as e:
            logger.error(f"Failed to send welcome email to {to_email}: {str(e)}")
            return False

# Create a global instance
email_service = EmailService()