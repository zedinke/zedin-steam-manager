import smtplib
import secrets
import string
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from datetime import datetime, timedelta
from typing import Optional
from sqlalchemy.orm import Session
from models.user import User
from config.settings import settings
import logging

logger = logging.getLogger(__name__)

class EmailService:
    def __init__(self):
        # Using Gmail SMTP for free email service
        self.smtp_server = "smtp.gmail.com"
        self.smtp_port = 587
        self.sender_email = settings.EMAIL_SENDER
        self.sender_password = settings.EMAIL_PASSWORD
        self.sender_name = "Zedin Steam Manager"
        
    def generate_verification_token(self) -> str:
        """Generate a secure verification token"""
        return ''.join(secrets.choice(string.ascii_letters + string.digits) for _ in range(32))
    
    def generate_verification_code(self) -> str:
        """Generate a 6-digit verification code"""
        return ''.join(secrets.choice(string.digits) for _ in range(6))
    
    def create_verification_email_html(self, user_name: str, verification_code: str, verification_link: str) -> str:
        """Create beautiful HTML email template"""
        return f"""
        <!DOCTYPE html>
        <html lang="hu">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>Email megerősítés - Zedin Steam Manager</title>
            <style>
                body {{ font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; margin: 0; padding: 20px; background-color: #f5f5f5; }}
                .container {{ max-width: 600px; margin: 0 auto; background-color: white; border-radius: 10px; box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1); }}
                .header {{ background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); padding: 30px; border-radius: 10px 10px 0 0; text-align: center; }}
                .header h1 {{ color: white; margin: 0; font-size: 28px; }}
                .header p {{ color: #e0e7ff; margin: 10px 0 0 0; }}
                .content {{ padding: 40px 30px; }}
                .welcome {{ font-size: 20px; color: #333; margin-bottom: 20px; }}
                .verification-box {{ background-color: #f8fafc; border: 2px dashed #667eea; border-radius: 8px; padding: 25px; text-align: center; margin: 25px 0; }}
                .verification-code {{ font-size: 32px; font-weight: bold; color: #667eea; letter-spacing: 3px; margin: 10px 0; }}
                .or-divider {{ text-align: center; margin: 25px 0; color: #666; }}
                .btn {{ display: inline-block; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; text-decoration: none; padding: 15px 30px; border-radius: 25px; font-weight: bold; margin: 10px 0; }}
                .btn:hover {{ transform: translateY(-2px); box-shadow: 0 4px 8px rgba(0, 0, 0, 0.2); }}
                .info {{ background-color: #fff3cd; border: 1px solid #ffeaa7; border-radius: 5px; padding: 15px; margin: 20px 0; }}
                .footer {{ background-color: #f8f9fa; padding: 20px 30px; border-radius: 0 0 10px 10px; text-align: center; color: #666; font-size: 12px; }}
                .logo {{ width: 50px; height: 50px; margin: 0 auto 10px; background: rgba(255, 255, 255, 0.2); border-radius: 50%; display: flex; align-items: center; justify-content: center; }}
            </style>
        </head>
        <body>
            <div class="container">
                <div class="header">
                    <div class="logo">🎮</div>
                    <h1>Zedin Steam Manager</h1>
                    <p>Üdvözlünk a Steam szerver menedzsment rendszerben!</p>
                </div>
                
                <div class="content">
                    <h2 class="welcome">Szia {user_name}! 👋</h2>
                    
                    <p>Köszönjük, hogy regisztráltál a Zedin Steam Manager rendszerbe! A regisztrációd befejezéséhez kérlek erősítsd meg az email címedet.</p>
                    
                    <div class="verification-box">
                        <h3>📧 Megerősítő kód</h3>
                        <div class="verification-code">{verification_code}</div>
                        <p>Add meg ezt a kódot a regisztrációs oldalon</p>
                    </div>
                    
                    <div class="or-divider">
                        <strong>VAGY</strong>
                    </div>
                    
                    <div style="text-align: center;">
                        <a href="{verification_link}" class="btn">
                            ✅ Email megerősítése egy kattintással
                        </a>
                    </div>
                    
                    <div class="info">
                        <strong>📝 Fontos információk:</strong>
                        <ul>
                            <li>Ez a kód 24 órán belül lejár</li>
                            <li>A regisztrációd után <strong>USER</strong> jogosultsági szintet kapsz</li>
                            <li>Ha nem te regisztráltál, kérlek hagyd figyelmen kívül ezt az emailt</li>
                        </ul>
                    </div>
                    
                    <p>Ha bármilyen kérdésed van, lépj kapcsolatba velünk!</p>
                    
                    <p>Üdvözlettel,<br>
                    <strong>A Zedin Steam Manager csapata</strong> 🚀</p>
                </div>
                
                <div class="footer">
                    <p>© 2025 Zedin Steam Manager | Professional Steam Server Management</p>
                    <p>Ez egy automatikusan generált email, kérlek ne válaszolj rá.</p>
                </div>
            </div>
        </body>
        </html>
        """
    
    async def send_verification_email(self, db: Session, user: User) -> bool:
        """Send verification email to user"""
        try:
            # Generate verification code and token
            verification_code = self.generate_verification_code()
            verification_token = self.generate_verification_token()
            
            # Update user with verification data
            user.verification_token = verification_token
            user.verification_expires = datetime.utcnow() + timedelta(hours=24)
            
            # Store verification code in token (for simplicity)
            user.verification_token = f"{verification_token}:{verification_code}"
            db.commit()
            
            # Create verification link
            verification_link = f"{settings.FRONTEND_URL}/verify-email?token={verification_token}"
            
            # Create email
            html_content = self.create_verification_email_html(
                user.get_full_name(),
                verification_code,
                verification_link
            )
            
            msg = MIMEMultipart('alternative')
            msg['Subject'] = "🎮 Email megerősítés - Zedin Steam Manager"
            msg['From'] = f"{self.sender_name} <{self.sender_email}>"
            msg['To'] = user.email
            
            html_part = MIMEText(html_content, 'html', 'utf-8')
            msg.attach(html_part)
            
            # Send email
            with smtplib.SMTP(self.smtp_server, self.smtp_port) as server:
                server.starttls()
                server.login(self.sender_email, self.sender_password)
                server.send_message(msg)
            
            logger.info(f"Verification email sent to {user.email}")
            return True
            
        except Exception as e:
            logger.error(f"Failed to send verification email to {user.email}: {str(e)}")
            return False
    
    async def send_welcome_email(self, user: User) -> bool:
        """Send welcome email after successful verification"""
        try:
            welcome_html = f"""
            <html>
            <body style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
                <div style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); padding: 30px; text-align: center; border-radius: 10px 10px 0 0;">
                    <h1 style="color: white; margin: 0;">🎉 Üdvözlünk a Zedin Steam Manager-ben!</h1>
                </div>
                
                <div style="padding: 30px; background: white; border-radius: 0 0 10px 10px; box-shadow: 0 4px 6px rgba(0,0,0,0.1);">
                    <h2>Szia {user.get_full_name()}! 👋</h2>
                    
                    <p>Sikeresen megerősítetted az email címedet! Most már teljes hozzáférésed van a Zedin Steam Manager rendszerhez.</p>
                    
                    <div style="background: #f0f9ff; padding: 20px; border-radius: 8px; margin: 20px 0;">
                        <h3>🎮 Mit tehetsz most?</h3>
                        <ul>
                            <li>Steam szerverek kezelése (ASE/ASA)</li>
                            <li>Real-time monitoring</li>
                            <li>RCON parancsok végrehajtása</li>
                            <li>Szerver konfigurációk szerkesztése</li>
                        </ul>
                    </div>
                    
                    <p>Jelenlegi jogosultsági szinted: <strong>USER</strong></p>
                    
                    <div style="text-align: center; margin: 30px 0;">
                        <a href="{settings.FRONTEND_URL}/login" style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; text-decoration: none; padding: 15px 30px; border-radius: 25px; font-weight: bold;">
                            🚀 Bejelentkezés most
                        </a>
                    </div>
                    
                    <p>Jó szórakozást! 🎉</p>
                    
                    <p>Üdvözlettel,<br><strong>A Zedin Steam Manager csapata</strong></p>
                </div>
            </body>
            </html>
            """
            
            msg = MIMEMultipart('alternative')
            msg['Subject'] = "🎉 Üdvözlünk a Zedin Steam Manager-ben!"
            msg['From'] = f"{self.sender_name} <{self.sender_email}>"
            msg['To'] = user.email
            
            html_part = MIMEText(welcome_html, 'html', 'utf-8')
            msg.attach(html_part)
            
            with smtplib.SMTP(self.smtp_server, self.smtp_port) as server:
                server.starttls()
                server.login(self.sender_email, self.sender_password)
                server.send_message(msg)
            
            logger.info(f"Welcome email sent to {user.email}")
            return True
            
        except Exception as e:
            logger.error(f"Failed to send welcome email to {user.email}: {str(e)}")
            return False

# Global email service instance
email_service = EmailService()