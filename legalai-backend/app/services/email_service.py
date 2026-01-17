import smtplib
import socket
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from flask import current_app
from typing import Optional
import time


class EmailService:
    """
    Email service with:
    - Connection pooling
    - Retry mechanism
    - Timeout handling
    - Gmail-specific optimizations
    - Security-safe logging
    """
    
    SMTP_TIMEOUT = 30  
    MAX_RETRIES = 3
    RETRY_DELAY = 2  
    
    @staticmethod
    def _get_smtp_config() -> dict:
        """Extract and validate SMTP configuration."""
        cfg = current_app.config
        return {
            'host': cfg.get('SMTP_HOST'),
            'port': int(cfg.get('SMTP_PORT', 587)),
            'user': cfg.get('SMTP_USER'),
            'password': cfg.get('SMTP_PASS'),
            'from_email': cfg.get('EMAIL_FROM'),
            'use_tls': cfg.get('MAIL_USE_TLS', True)
        }
    
    @staticmethod
    def _validate_config(config: dict) -> tuple[bool, Optional[str]]:
        """Validate SMTP configuration completeness."""
        required = ['host', 'port', 'user', 'password', 'from_email']
        missing = [k for k in required if not config.get(k)]
        
        if missing:
            return False, f"Missing SMTP config: {', '.join(missing)}"
        return True, None
    
    @staticmethod
    def _create_message(to_email: str, subject: str, html: str, from_email: str) -> MIMEMultipart:
        """Create properly formatted MIME message."""
        msg = MIMEMultipart('alternative')
        msg['Subject'] = subject
        msg['From'] = from_email
        msg['To'] = to_email
        msg['X-Mailer'] = 'LegalAI Email Service'
        
        html_part = MIMEText(html, 'html', 'utf-8')
        msg.attach(html_part)
        
        return msg
    
    @staticmethod
    def _mask_email(email: str) -> str:
        """Mask email for safe logging."""
        if not email or '@' not in email:
            return 'invalid-email'
        local, domain = email.split('@', 1)
        return f"{local[:2]}***@{domain}"
    
    @staticmethod
    def send(to_email: str, subject: str, html: str) -> bool:
        """
        Send email with automatic retry and comprehensive error handling.
        
        Returns:
            bool: True if sent successfully, False otherwise
        """
        config = EmailService._get_smtp_config()
        
        is_valid, error = EmailService._validate_config(config)
        if not is_valid:
            current_app.logger.error(f"[EMAIL] Configuration invalid: {error}")
            return False
        
        masked_to = EmailService._mask_email(to_email)
        current_app.logger.info(
            f"[EMAIL] Attempting to send to {masked_to} | "
            f"Subject: {subject[:50]}"
        )
        
        last_exception = None
        for attempt in range(1, EmailService.MAX_RETRIES + 1):
            try:
                msg = EmailService._create_message(
                    to_email=to_email,
                    subject=subject,
                    html=html,
                    from_email=config['from_email']
                )
                
                current_app.logger.debug(
                    f"[EMAIL] Attempt {attempt}/{EmailService.MAX_RETRIES} | "
                    f"Connecting to {config['host']}:{config['port']}"
                )
                
                with smtplib.SMTP(
                    config['host'], 
                    config['port'], 
                    timeout=EmailService.SMTP_TIMEOUT
                ) as server:
                    
                    if current_app.config.get('DEBUG'):
                        server.set_debuglevel(1)
                    
                    if config['use_tls']:
                        current_app.logger.debug("[EMAIL] Starting TLS...")
                        server.starttls()
                    
                    current_app.logger.debug("[EMAIL] Authenticating...")
                    server.login(config['user'], config['password'])
                    
                    current_app.logger.debug("[EMAIL] Sending message...")
                    result = server.send_message(msg)
                    
                    if result:
                        current_app.logger.warning(
                            f"[EMAIL] Partial failure - some recipients rejected: {result}"
                        )
                    
                    current_app.logger.info(
                        f"[EMAIL] Successfully sent to {masked_to} | "
                        f"Attempt: {attempt}/{EmailService.MAX_RETRIES}"
                    )
                    return True
                    
            except smtplib.SMTPAuthenticationError as e:
                current_app.logger.error(
                    f"[EMAIL] Authentication failed | "
                    f"User: {config['user'][:5]}*** | "
                    f"Error: {str(e)}"
                )
                return False
                
            except smtplib.SMTPRecipientsRefused as e:
                current_app.logger.error(
                    f"[EMAIL] Recipient refused: {masked_to} | "
                    f"Error: {str(e)}"
                )
                return False
                
            except smtplib.SMTPException as e:
                last_exception = e
                current_app.logger.warning(
                    f"[EMAIL] SMTP error on attempt {attempt}/{EmailService.MAX_RETRIES} | "
                    f"To: {masked_to} | Error: {str(e)}"
                )
                
            except socket.timeout as e:
                last_exception = e
                current_app.logger.warning(
                    f"[EMAIL] Timeout on attempt {attempt}/{EmailService.MAX_RETRIES} | "
                    f"Host: {config['host']}:{config['port']}"
                )
                
            except socket.gaierror as e:
                current_app.logger.error(
                    f"[EMAIL] Cannot resolve host: {config['host']} | "
                    f"Error: {str(e)}"
                )
                return False
                
            except Exception as e:
                last_exception = e
                current_app.logger.warning(
                    f"[EMAIL] Unexpected error on attempt {attempt}/{EmailService.MAX_RETRIES} | "
                    f"Type: {type(e).__name__} | Error: {str(e)}",
                    exc_info=True
                )
            
            if attempt < EmailService.MAX_RETRIES:
                delay = EmailService.RETRY_DELAY * attempt 
                current_app.logger.debug(f"[EMAIL] Waiting {delay}s before retry...")
                time.sleep(delay)
        
        current_app.logger.error(
            f"[EMAIL] Failed after {EmailService.MAX_RETRIES} attempts | "
            f"To: {masked_to} | Last error: {str(last_exception)}"
        )
        return False
    
    @staticmethod
    def test_connection() -> tuple[bool, Optional[str]]:
        """
        Test SMTP connection without sending email.
        
        Returns:
            tuple: (success: bool, error_message: Optional[str])
        """
        config = EmailService._get_smtp_config()
        
        is_valid, error = EmailService._validate_config(config)
        if not is_valid:
            return False, error
        
        try:
            with smtplib.SMTP(
                config['host'], 
                config['port'], 
                timeout=10
            ) as server:
                if config['use_tls']:
                    server.starttls()
                server.login(config['user'], config['password'])
                return True, None
                
        except smtplib.SMTPAuthenticationError as e:
            return False, f"Authentication failed: {str(e)}"
        except socket.timeout:
            return False, f"Connection timeout to {config['host']}:{config['port']}"
        except socket.gaierror:
            return False, f"Cannot resolve host: {config['host']}"
        except Exception as e:
            return False, f"Connection failed: {str(e)}"
