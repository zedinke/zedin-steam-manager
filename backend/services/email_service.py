import aiosmtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
import os
from jinja2 import Template

async def send_verification_email(email: str, username: str, token: str):
    """Send email verification"""
    frontend_url = os.getenv("FRONTEND_URL", "http://localhost")
    verification_url = f"{frontend_url}/verify-email?token={token}"
    
    # Modern email template with beautiful design
    html_template = Template("""
    <!DOCTYPE html>
    <html lang="hu">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Email Megerősítés - Zedin Steam Manager</title>
        <style>
            * {
                margin: 0;
                padding: 0;
                box-sizing: border-box;
            }
            body {
                font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                padding: 40px 20px;
                line-height: 1.6;
            }
            .email-wrapper {
                max-width: 600px;
                margin: 0 auto;
                background: #ffffff;
                border-radius: 16px;
                overflow: hidden;
                box-shadow: 0 20px 60px rgba(0, 0, 0, 0.3);
            }
            .header {
                background: linear-gradient(135deg, #2c3e50 0%, #34495e 100%);
                padding: 40px 30px;
                text-align: center;
                color: white;
            }
            .header h1 {
                font-size: 28px;
                font-weight: 700;
                margin-bottom: 8px;
                text-shadow: 2px 2px 4px rgba(0,0,0,0.2);
            }
            .header p {
                font-size: 14px;
                opacity: 0.9;
                color: #ecf0f1;
            }
            .content {
                padding: 40px 30px;
                color: #2c3e50;
            }
            .greeting {
                font-size: 20px;
                font-weight: 600;
                color: #2c3e50;
                margin-bottom: 20px;
            }
            .message {
                font-size: 16px;
                color: #555;
                margin-bottom: 30px;
                line-height: 1.8;
            }
            .button-container {
                text-align: center;
                margin: 40px 0;
            }
            .verify-button {
                display: inline-block;
                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                color: white;
                padding: 16px 40px;
                text-decoration: none;
                border-radius: 50px;
                font-weight: 600;
                font-size: 16px;
                box-shadow: 0 10px 30px rgba(102, 126, 234, 0.4);
                transition: transform 0.3s ease, box-shadow 0.3s ease;
            }
            .verify-button:hover {
                transform: translateY(-2px);
                box-shadow: 0 15px 40px rgba(102, 126, 234, 0.5);
            }
            .link-box {
                background: #f8f9fa;
                border: 2px dashed #dee2e6;
                border-radius: 8px;
                padding: 20px;
                margin: 30px 0;
                word-break: break-all;
            }
            .link-box p {
                font-size: 13px;
                color: #6c757d;
                margin-bottom: 10px;
            }
            .link-box a {
                color: #667eea;
                text-decoration: none;
                font-size: 13px;
                word-break: break-all;
            }
            .info-box {
                background: #fff3cd;
                border-left: 4px solid #ffc107;
                padding: 15px 20px;
                margin: 30px 0;
                border-radius: 4px;
            }
            .info-box p {
                font-size: 14px;
                color: #856404;
                margin: 0;
            }
            .footer {
                background: #f8f9fa;
                padding: 30px;
                text-align: center;
                border-top: 1px solid #dee2e6;
            }
            .footer p {
                font-size: 13px;
                color: #6c757d;
                margin: 5px 0;
            }
            .footer a {
                color: #667eea;
                text-decoration: none;
            }
            .icon {
                width: 60px;
                height: 60px;
                margin: 0 auto 20px;
                background: rgba(255,255,255,0.2);
                border-radius: 50%;
                display: flex;
                align-items: center;
                justify-content: center;
                font-size: 30px;
            }
            .features {
                display: flex;
                gap: 20px;
                margin: 30px 0;
                flex-wrap: wrap;
            }
            .feature {
                flex: 1;
                min-width: 150px;
                text-align: center;
                padding: 20px;
                background: #f8f9fa;
                border-radius: 8px;
            }
            .feature-icon {
                font-size: 24px;
                margin-bottom: 10px;
            }
            .feature-title {
                font-size: 14px;
                font-weight: 600;
                color: #2c3e50;
                margin-bottom: 5px;
            }
            .feature-desc {
                font-size: 12px;
                color: #6c757d;
            }
        </style>
    </head>
    <body>
        <div class="email-wrapper">
            <div class="header">
                <div class="icon">🎮</div>
                <h1>Zedin Steam Manager</h1>
                <p>Professzionális Steam Szerver Menedzsment</p>
            </div>
            
            <div class="content">
                <div class="greeting">
                    Üdvözlünk, {{ username }}! 👋
                </div>
                
                <div class="message">
                    <p>Köszönjük, hogy regisztráltál a <strong>Zedin Steam Manager</strong> platformra!</p>
                    <p style="margin-top: 15px;">
                        Az ASE (Ark: Survival Evolved) és ASA (Ark: Survival Ascended) szervereid 
                        professzionális kezeléséhez már csak egy lépés van hátra: erősítsd meg az email címedet!
                    </p>
                </div>

                <div class="features">
                    <div class="feature">
                        <div class="feature-icon">⚡</div>
                        <div class="feature-title">Gyors Telepítés</div>
                        <div class="feature-desc">Automatikus szerver setup</div>
                    </div>
                    <div class="feature">
                        <div class="feature-icon">📊</div>
                        <div class="feature-title">Valós idejű Monitorozás</div>
                        <div class="feature-desc">RAM, CPU, HDD köv etés</div>
                    </div>
                    <div class="feature">
                        <div class="feature-icon">🔧</div>
                        <div class="feature-title">RCON Kezelés</div>
                        <div class="feature-desc">Teljes szerver kontroll</div>
                    </div>
                </div>
                
                <div class="button-container">
                    <a href="{{ verification_url }}" class="verify-button">
                        ✉️ Email Megerősítése
                    </a>
                </div>
                
                <div class="link-box">
                    <p>Ha a gomb nem működik, másold be ezt a linket a böngésződbe:</p>
                    <a href="{{ verification_url }}">{{ verification_url }}</a>
                </div>
                
                <div class="info-box">
                    <p>⏱️ <strong>Fontos:</strong> Ez a link 24 órán belül lejár. Ha nem te regisztráltál, nyugodtan hagyd figyelmen kívül ezt az emailt.</p>
                </div>
            </div>
            
            <div class="footer">
                <p><strong>Zedin Steam Manager</strong></p>
                <p>Professzionális megoldás ARK szerverek kezeléséhez</p>
                <p style="margin-top: 15px;">
                    <a href="{{ frontend_url }}">Nyitóoldal</a> • 
                    <a href="{{ frontend_url }}/dashboard">Dashboard</a> • 
                    <a href="https://github.com/zedinke/zedin-steam-manager">GitHub</a>
                </p>
                <p style="margin-top: 15px; font-size: 11px; color: #adb5bd;">
                    © 2025 Zedin Steam Manager. Minden jog fenntartva.
                </p>
            </div>
        </div>
    </body>
    </html>
    """)
    
    html_content = html_template.render(
        username=username, 
        verification_url=verification_url,
        frontend_url=frontend_url
    )
    
    # Create message
    message = MIMEMultipart("alternative")
    message["Subject"] = "🎮 Email megerősítés - Zedin Steam Manager"
    message["From"] = os.getenv("SMTP_USER", "noreply@zedinmanager.com")
    message["To"] = email
    
    message.attach(MIMEText(html_content, "html"))
    
    # Send email
    smtp_password = os.getenv("SMTP_PASSWORD")
    
    # Check if SMTP is configured
    if not smtp_password or smtp_password == "change_me_in_production":
        # Development mode - write verification URL to file and log
        log_message = f"""
{'='*80}
📧 EMAIL VERIFICATION (Development Mode)
{'='*80}
To: {email}
Username: {username}
Verification URL: {verification_url}
{'='*80}
"""
        print(log_message, flush=True)
        
        # Also write to file for easier access
        try:
            with open("/tmp/verification_urls.txt", "a") as f:
                f.write(f"{email}: {verification_url}\n")
        except:
            pass
        return
    
    try:
        await aiosmtplib.send(
            message,
            hostname=os.getenv("SMTP_HOST", "smtp.gmail.com"),
            port=int(os.getenv("SMTP_PORT", 587)),
            username=os.getenv("SMTP_USER"),
            password=smtp_password,
            start_tls=True
        )
        print(f"✅ Email sent successfully to {email}", flush=True)
    except Exception as e:
        print(f"❌ Failed to send email: {e}", flush=True)
        print(f"📧 Verification URL: {verification_url}", flush=True)
