import aiosmtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
import os
from jinja2 import Template

async def send_verification_email(email: str, username: str, token: str):
    """Send email verification"""
    frontend_url = os.getenv("FRONTEND_URL", "http://localhost")
    verification_url = f"{frontend_url}/verify-email?token={token}"
    
    # Email template
    html_template = Template("""
    <!DOCTYPE html>
    <html>
    <head>
        <style>
            body { font-family: Arial, sans-serif; }
            .container { max-width: 600px; margin: 0 auto; padding: 20px; }
            .button { background-color: #4CAF50; color: white; padding: 12px 24px; 
                     text-decoration: none; border-radius: 4px; display: inline-block; }
        </style>
    </head>
    <body>
        <div class="container">
            <h2>Welcome to Zedin Steam Manager!</h2>
            <p>Hello {{ username }},</p>
            <p>Thank you for registering. Please verify your email address by clicking the button below:</p>
            <p><a href="{{ verification_url }}" class="button">Verify Email</a></p>
            <p>Or copy this link: {{ verification_url }}</p>
            <p>This link will expire in 24 hours.</p>
            <p>If you didn't register, please ignore this email.</p>
        </div>
    </body>
    </html>
    """)
    
    html_content = html_template.render(username=username, verification_url=verification_url)
    
    # Create message
    message = MIMEMultipart("alternative")
    message["Subject"] = "Verify your email - Zedin Steam Manager"
    message["From"] = os.getenv("SMTP_USER", "noreply@zedinmanager.com")
    message["To"] = email
    
    message.attach(MIMEText(html_content, "html"))
    
    # Send email
    try:
        await aiosmtplib.send(
            message,
            hostname=os.getenv("SMTP_HOST", "smtp.gmail.com"),
            port=int(os.getenv("SMTP_PORT", 587)),
            username=os.getenv("SMTP_USER"),
            password=os.getenv("SMTP_PASSWORD"),
            start_tls=True
        )
    except Exception as e:
        print(f"Failed to send email: {e}")
