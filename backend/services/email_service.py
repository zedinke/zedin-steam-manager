import aiosmtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
import os
from jinja2 import Template
import os

def _log_dev_email(log_message: str, file_path: str, file_content: str):
    """Helper to log email content in development mode."""
    print(log_message, flush=True)
    
    # Correctly determine the project root and create the log path
    # Assuming this script is in backend/services, so we go up two levels
    project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
    log_file_path = os.path.join(project_root, file_path)
    log_dir = os.path.dirname(log_file_path)

    try:
        if not os.path.exists(log_dir):
            os.makedirs(log_dir)
            
        with open(log_file_path, "a") as f:
            f.write(file_content)
    except IOError as e:
        print(f"Could not write to log file {log_file_path}: {e}", flush=True)


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
                <div class="icon">GAME</div>
                <h1>Zedin Steam Manager</h1>
                <p>Professzionális Steam Szerver Menedzsment</p>
            </div>
            
            <div class="content">
                <div class="greeting">
                    Üdvözlünk, {{ username }}!
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
                        <div class="feature-icon"></div>
                        <div class="feature-title">Gyors Telepítés</div>
                        <div class="feature-desc">Automatikus szerver setup</div>
                    </div>
                    <div class="feature">
                        <div class="feature-icon"></div>
                        <div class="feature-title">Valós idejű Monitorozás</div>
                        <div class="feature-desc">RAM, CPU, HDD köv etés</div>
                    </div>
                    <div class="feature">
                        <div class="feature-icon"></div>
                        <div class="feature-title">RCON Kezelés</div>
                        <div class="feature-desc">Teljes szerver kontroll</div>
                    </div>
                </div>
                
                <div class="button-container">
                    <a href="{{ verification_url }}" class="verify-button">
                        Email Megerősítése
                    </a>
                </div>
                
                <div class="link-box">
                    <p>Ha a gomb nem működik, másold be ezt a linket a böngésződbe:</p>
                    <a href="{{ verification_url }}">{{ verification_url }}</a>
                </div>
                
                    <div class="info-box">
                    <p><strong>Fontos:</strong> Ez a link 24 órán belül lejár. Ha nem te regisztráltál, nyugodtan hagyd figyelmen kívül ezt az emailt.</p>
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
    ")
    
    html_content = html_template.render(
        username=username, 
        verification_url=verification_url,
        frontend_url=frontend_url
    )
    
    # Create message
    message = MIMEMultipart("alternative")
    message["Subject"] = "Email megerősítés - Zedin Steam Manager"
    message["From"] = os.getenv("SMTP_USER", "noreply@zedinmanager.com")
    message["To"] = email
    
    message.attach(MIMEText(html_content, "html"))
    
    # Send email
    smtp_password = os.getenv("SMTP_PASSWORD")
    
    # Check if SMTP is configured
    if not smtp_password or smtp_password == "change_me_in_production":
        log_message = f"""
    {'='*80}
    # 📧 EMAIL VERIFICATION (Development Mode)
    EMAIL VERIFICATION (Development Mode)
    {'='*80}
    To: {email}
    Username: {username}
    Verification URL: {verification_url}
    {'='*80}
    """
                    """
            log_message,
            file_path="logs/verification_urls.txt",
            file_content=f"{email}: {verification_url}\n"
        )
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


async def send_token_email(email: str, username: str, token_code: str, duration_days: int):
    """Send token generation email"""
    frontend_url = os.getenv("FRONTEND_URL", "http://localhost")
    activation_url = f"{frontend_url}/tokens/activate"
    
    html_template = Template("""
<!DOCTYPE html>
<html lang="hu">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Token Generálva - Zedin Steam Manager</title>
</head>
<body style="margin: 0; padding: 0; font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);">
    <table role="presentation" style="width: 100%; border-collapse: collapse;">
        <tr>
            <td style="padding: 40px 20px;">
                <table role="presentation" style="max-width: 600px; margin: 0 auto; background: white; border-radius: 20px; box-shadow: 0 20px 60px rgba(0,0,0,0.3); overflow: hidden;">
                    <tr>
                        <td style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); padding: 40px 30px; text-align: center;">
                            <h1 style="margin: 0; color: white; font-size: 28px; font-weight: bold;">
                                Uj Token Generálva
                            </h1>
                            <p style="margin: 10px 0 0 0; color: rgba(255,255,255,0.9); font-size: 16px;">
                                Zedin Steam Manager
                            </p>
                        </td>
                    </tr>
                    <tr>
                        <td style="padding: 40px 30px;">
                            <h2 style="margin: 0 0 20px 0; color: #333; font-size: 24px;">
                                Üdv {{ username }}!
                            </h2>
                            <p style="margin: 0 0 20px 0; color: #666; font-size: 16px; line-height: 1.6;">
                                Generáltunk neked egy <strong>Server Admin</strong> tokent! 
                                Ezzel a tokennel teljes hozzáférést kapsz a szerverkezelési funkciókhoz.
                            </p>
                            <div style="background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%); padding: 30px; border-radius: 15px; margin: 30px 0; text-align: center; box-shadow: 0 8px 20px rgba(240, 147, 251, 0.3);">
                                <p style="margin: 0 0 10px 0; color: white; font-size: 14px; text-transform: uppercase; letter-spacing: 2px;">
                                    Token Kód
                                </p>
                                <p style="margin: 0; color: white; font-size: 24px; font-weight: bold; font-family: 'Courier New', monospace; letter-spacing: 1px; word-break: break-all;">
                                    {{ token_code }}
                                </p>
                            </div>
                            <table role="presentation" style="width: 100%; margin: 30px 0; background: #f8f9fa; border-radius: 12px; overflow: hidden;">
                                <tr>
                                    <td style="padding: 20px; border-bottom: 1px solid #e9ecef;">
                                        <p style="margin: 0; color: #666; font-size: 14px;"><strong>Érvényesség:</strong></p>
                                        <p style="margin: 5px 0 0 0; color: #333; font-size: 16px;">{{ duration_days }} nap</p>
                                    </td>
                                </tr>
                                <tr>
                                    <td style="padding: 20px;">
                                        <p style="margin: 0; color: #666; font-size: 14px;"><strong>Jogosultság:</strong></p>
                                        <p style="margin: 5px 0 0 0; color: #333; font-size: 16px;">Server Admin</p>
                                    </td>
                                </tr>
                            </table>
                            <table role="presentation" style="margin: 30px 0; width: 100%;">
                                <tr>
                                    <td style="text-align: center;">
                                        <a href="{{ activation_url }}" 
                                           style="display: inline-block; padding: 16px 40px; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; text-decoration: none; border-radius: 50px; font-weight: bold; font-size: 16px; box-shadow: 0 4px 15px rgba(102, 126, 234, 0.4);">
                                            Token Aktiválása
                                        </a>
                                    </td>
                                </tr>
                            </table>
                            <div style="background: #fff3cd; border-left: 4px solid #ffc107; padding: 20px; border-radius: 8px; margin: 30px 0;">
                                <h3 style="margin: 0 0 15px 0; color: #856404; font-size: 16px;">
                                    Aktiválási Lépések
                                </h3> 
                                <ol style="margin: 0; padding-left: 20px; color: #856404; font-size: 14px; line-height: 1.8;">
                                    <li>Jelentkezz be a Zedin Steam Manager fiókodba</li>
                                    <li>Navigálj a "Token Aktiválás" menüpontba</li>
                                    <li>Másold be a fenti token kódot</li>
                                    <li>Kattints az "Aktiválás" gombra</li>
                                    <li>Élvezd a Server Admin jogosultságokat!</li>
                                </ol>
                            </div>
                        </td>
                    </tr>
                    <tr>
                        <td style="background: #f8f9fa; padding: 30px; text-align: center; border-top: 1px solid #e9ecef;">
                            <p style="margin: 0 0 10px 0; color: #666; font-size: 14px;">
                                <strong>Zedin Steam Manager</strong> - Token Kezelés
                            </p>
                            <p style="margin: 0 0 10px 0; color: #999; font-size: 12px;">
                                Ez egy automatikus email. Kérjük, ne válaszolj rá.
                            </p>
                            <p style="margin: 0; color: #dc3545; font-size: 12px; font-weight: bold;">
                                Ne oszd meg a token kódot senkivel!
                            </p>
                        </td>
                    </tr>
                </table>
            </td>
        </tr>
    </table>
</body>
</html>
    """)

    html_content = html_template.render(
        username=username,
        token_code=token_code,
        duration_days=duration_days,
        activation_url=activation_url
    )
    
    message = MIMEMultipart('alternative')
    message['Subject'] = 'Server Admin Token Generálva - Zedin Steam Manager'
    message['From'] = os.getenv("SMTP_USER", "noreply@zedinmanager.com")
    message['To'] = email
    
    message.attach(MIMEText(html_content, 'html'))
    
    smtp_password = os.getenv("SMTP_PASSWORD")
    
    if not smtp_password or smtp_password == "change_me_in_production":
        print(f"TOKEN EMAIL (Dev Mode) - {email}: {token_code}", flush=True)
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
        print(f"✅ Token email sent to {email}", flush=True)
    except Exception as e:
        print(f"❌ Failed to send token email: {e}", flush=True)


async def send_expiry_notification(email: str, username: str, token_code: str, days_remaining: int):
    """Send token expiry notification email"""
    frontend_url = os.getenv("FRONTEND_URL", "http://localhost")
    
    html_template = Template("""
<!DOCTYPE html>
<html lang="hu">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Token Lejárat - Zedin Steam Manager</title>
</head>
<body style="margin: 0; padding: 0; font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);">
    <table role="presentation" style="width: 100%; border-collapse: collapse;">
        <tr>
            <td style="padding: 40px 20px;">
                <table role="presentation" style="max-width: 600px; margin: 0 auto; background: white; border-radius: 20px; box-shadow: 0 20px 60px rgba(0,0,0,0.3); overflow: hidden;">
                    <tr>
                        <td style="background: linear-gradient(135deg, #ff9966 0%, #ff5e62 100%); padding: 40px 30px; text-align: center;">
                                <h1 style="margin: 0; color: white; font-size: 28px; font-weight: bold;">
                                    Token Lejárat
                                </h1>
                            <p style="margin: 10px 0 0 0; color: rgba(255,255,255,0.9); font-size: 16px;">
                                Zedin Steam Manager
                            </p>
                        </td>
                    </tr>
                    <tr>
                        <td style="padding: 40px 30px;">
                            <h2 style="margin: 0 0 20px 0; color: #333; font-size: 24px;">
                                Üdv {{ username }}!
                            </h2>
                            <p style="margin: 0 0 20px 0; color: #666; font-size: 16px; line-height: 1.6;">
                                A <strong>Server Admin</strong> tokened hamarosan lejár! 
                                Kérjük, lépj kapcsolatba egy Manager Admin-nal új token generálásához.
                            </p>
                            <div style="background: linear-gradient(135deg, #ff9966 0%, #ff5e62 100%); padding: 30px; border-radius: 15px; margin: 30px 0; text-align: center; box-shadow: 0 8px 20px rgba(255, 94, 98, 0.3);">
                                <p style="margin: 0 0 10px 0; color: white; font-size: 14px; text-transform: uppercase; letter-spacing: 2px;">
                                    Hátralévő Idő
                                </p>
                                <p style="margin: 0; color: white; font-size: 48px; font-weight: bold;">
                                    {{ days_remaining }}
                                </p>
                                <p style="margin: 10px 0 0 0; color: white; font-size: 18px;">
                                    nap
                                </p>
                            </div>
                            <div style="background: #f8f9fa; padding: 20px; border-radius: 12px; margin: 30px 0;">
                                <p style="margin: 0 0 10px 0; color: #666; font-size: 14px;">
                                        <strong>Token Kód:</strong>
                                </p>
                                <p style="margin: 0; color: #333; font-size: 16px; font-family: 'Courier New', monospace; word-break: break-all;">
                                    {{ token_code }}
                                </p>
                            </div>
                            <div style="background: #d1ecf1; border-left: 4px solid #0c5460; padding: 20px; border-radius: 8px; margin: 30px 0;">
                                <h3 style="margin: 0 0 15px 0; color: #0c5460; font-size: 16px;">
                                        Következő Lépések
                                </h3>
                                <ul style="margin: 0; padding-left: 20px; color: #0c5460; font-size: 14px; line-height: 1.8;">
                                    <li>Lépj kapcsolatba egy Manager Admin-nal</li>
                                    <li>Kérj új tokent a jogosultságok megőrzéséhez</li>
                                    <li>Aktiváld az új tokent a lejárat előtt</li>
                                </ul>
                            </div>
                            <table role="presentation" style="margin: 30px 0; width: 100%;">
                                <tr>
                                    <td style="text-align: center;">
                                        <a href="{{ frontend_url }}/dashboard" 
                                           style="display: inline-block; padding: 16px 40px; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; text-decoration: none; border-radius: 50px; font-weight: bold; font-size: 16px; box-shadow: 0 4px 15px rgba(102, 126, 234, 0.4);">
                                            Dashboard Megnyitása
                                        </a>
                                    </td>
                                </tr>
                            </table>
                        </td>
                    </tr>
                    <tr>
                        <td style="background: #f8f9fa; padding: 30px; text-align: center; border-top: 1px solid #e9ecef;">
                            <p style="margin: 0 0 10px 0; color: #666; font-size: 14px;">
                                <strong>Zedin Steam Manager</strong> - Token Kezelés
                            </p>
                            <p style="margin: 0; color: #999; font-size: 12px;">
                                Ez egy automatikus figyelmeztető email.
                            </p>
                        </td>
                    </tr>
                </table>
            </td>
        </tr>
    </table>
</body>
</html>
    ")

    html_content = html_template.render(
        username=username,
        token_code=token_code,
        days_remaining=days_remaining,
        frontend_url=frontend_url
    )
    
    message = MIMEMultipart('alternative')
    message['Subject'] = f'Token Lejárat ({days_remaining} nap) - Zedin Steam Manager'
    message['From'] = os.getenv("SMTP_USER", "noreply@zedinmanager.com")
    message['To'] = email
    
    message.attach(MIMEText(html_content, 'html'))
    
    smtp_password = os.getenv("SMTP_PASSWORD")
    
    if not smtp_password or smtp_password == "change_me_in_production":
        print(f"📧 EXPIRY EMAIL (Dev Mode) - {email}: {days_remaining} days", flush=True)
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
        print(f"✅ Expiry notification sent to {email}", flush=True)
    except Exception as e:
        print(f"❌ Failed to send expiry notification: {e}", flush=True)


async def send_password_reset_email(email: str, username: str, reset_token: str):
    """Send password reset email"""
    frontend_url = os.getenv("FRONTEND_URL", "http://localhost")
    reset_url = f"{frontend_url}/reset-password?token={reset_token}"
    
    html_template = Template("""
<!DOCTYPE html>
<html lang="hu">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Jelszó Visszaállítás - Zedin Steam Manager</title>
</head>
<body style="margin: 0; padding: 0; font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);">
    <table role="presentation" style="width: 100%; border-collapse: collapse;">
        <tr>
            <td style="padding: 40px 20px;">
                <table role="presentation" style="max-width: 600px; margin: 0 auto; background: white; border-radius: 20px; box-shadow: 0 20px 60px rgba(0,0,0,0.3); overflow: hidden;">
                    <tr>
                        <td style="background: linear-gradient(135deg, #2c3e50 0%, #34495e 100%); padding: 40px 30px; text-align: center;">
                            <h1 style="margin: 0; color: white; font-size: 28px; font-weight: bold;">
                                Jelszó Visszaállítás
                            </h1>
                            <p style="margin: 10px 0 0 0; color: rgba(255,255,255,0.9); font-size: 16px;">
                                Zedin Steam Manager
                            </p>
                        </td>
                    </tr>
                    <tr>
                        <td style="padding: 40px 30px;">
                            <h2 style="margin: 0 0 20px 0; color: #333; font-size: 24px;">
                                Üdv {{ username }}!
                            </h2>
                            <p style="margin: 0 0 20px 0; color: #666; font-size: 16px; line-height: 1.6;">
                                Jelszó visszaállítást kértél a <strong>Zedin Steam Manager</strong> fiókodhoz. 
                                Ha nem te voltál, nyugodtan hagyd figyelmen kívül ezt az emailt.
                            </p>
                            <table role="presentation" style="margin: 30px 0; width: 100%;">
                                <tr>
                                    <td style="text-align: center;">
                                        <a href="{{ reset_url }}" 
                                           style="display: inline-block; padding: 16px 40px; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; text-decoration: none; border-radius: 50px; font-weight: bold; font-size: 16px; box-shadow: 0 4px 15px rgba(102, 126, 234, 0.4);"> 
                                            Jelszó Visszaállítása
                                        </a>
                                    </td>
                                </tr>
                            </table>
                            <div style="background: #f8f9fa; border: 2px dashed #dee2e6; padding: 20px; border-radius: 12px; margin: 30px 0;">
                                <p style="margin: 0 0 10px 0; color: #666; font-size: 13px;">
                                    Ha a gomb nem működik, másold be ezt a linket a böngésződbe:
                                </p>
                                <p style="margin: 0; color: #667eea; font-size: 13px; word-break: break-all; font-family: 'Courier New', monospace;">
                                    {{ reset_url }}
                                </p>
                            </div>
                            <div style="background: #fff3cd; border-left: 4px solid #ffc107; padding: 20px; border-radius: 8px; margin: 30px 0;">
                                <h3 style="margin: 0 0 15px 0; color: #856404; font-size: 16px;">
                                    Biztonsági Megjegyzés
                                </h3>
                                <ul style="margin: 0; padding-left: 20px; color: #856404; font-size: 14px; line-height: 1.8;">
                                    <li>Ez a link 1 órán belül lejár</li>
                                    <li>Csak egyszer használható</li>
                                    <li>Ha nem te kérted, hagyd figyelmen kívül ezt az emailt</li>
                                    <li>Soha ne oszd meg ezt a linket senkivel</li>
                                </ul>
                            </div>
                            <div style="background: #d1ecf1; border-left: 4px solid #0c5460; padding: 20px; border-radius: 8px; margin: 30px 0;">
                                <p style="margin: 0; color: #0c5460; font-size: 14px; line-height: 1.6;">
                                    <strong>Tipp:</strong> Válassz erős jelszót, amely tartalmaz kisbetűket, 
                                    nagybetűket, számokat és speciális karaktereket.
                                </p>
                            </div>
                        </td>
                    </tr>
                    <tr>
                        <td style="background: #f8f9fa; padding: 30px; text-align: center; border-top: 1px solid #e9ecef;">
                            <p style="margin: 0 0 10px 0; color: #666; font-size: 14px;">
                                <strong>Zedin Steam Manager</strong> - Fiók Biztonság
                            </p>
                            <p style="margin: 0 0 10px 0; color: #999; font-size: 12px;">
                                Ez egy automatikus email. Kérjük, ne válaszolj rá.
                            </p>
                            <p style="margin: 0; color: #dc3545; font-size: 12px; font-weight: bold;">
                                Ha nem te kérted a visszaállítást, azonnal jelezz nekünk!
                            </p>
                        </td>
                    </tr>
                </table>
            </td>
        </tr>
    </table>
</body>
</html>
    ")
    
    html_content = html_template.render(
        username=username,
        reset_url=reset_url
    )
    
    message = MIMEMultipart('alternative')
    message['Subject'] = 'Jelszó Visszaállítás - Zedin Steam Manager'
    message['From'] = os.getenv("SMTP_USER", "noreply@zedinmanager.com")
    message['To'] = email
            """
    message.attach(MIMEText(html_content, 'html'))
    
    smtp_password = os.getenv("SMTP_PASSWORD")
    
    if not smtp_password or smtp_password == "change_me_in_production":
        log_message = f"""
{'='*80}
📧 PASSWORD RESET EMAIL (Development Mode)
{'='*80}
To: {email}
Reset URL: {reset_url}
{'='*80}
"""
        _log_dev_email(
            log_message,
            file_path="logs/password_reset_urls.txt",
            file_content=f"{email}: {reset_url}\n"
        )
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
        print(f"✅ Password reset email sent to {email}", flush=True)
    except Exception as e:
        print(f"❌ Failed to send password reset email: {e}", flush=True)
        print(f"🔗 Reset URL: {reset_url}", flush=True)