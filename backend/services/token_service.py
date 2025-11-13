from datetime import datetime, timedelta
from typing import Optional, List
from sqlalchemy.orm import Session
from models.user import User
from models.token import UserToken, TokenType, TokenStatus, TokenUsageLog
import uuid
import logging

logger = logging.getLogger(__name__)

class TokenService:
    def __init__(self):
        pass
    
    def create_trial_token(self, db: Session, user: User) -> UserToken:
        """Create a 30-day trial token for new users"""
        try:
            # Check if user already has a trial token
            existing_trial = db.query(UserToken).filter(
                UserToken.user_id == user.id,
                UserToken.token_type == TokenType.TRIAL
            ).first()
            
            if existing_trial:
                logger.warning(f"User {user.email} already has a trial token")
                return existing_trial
            
            # Create new trial token
            trial_token = UserToken(
                user_id=user.id,
                token_key=self._generate_token_key(),
                token_type=TokenType.TRIAL,
                status=TokenStatus.ACTIVE,
                expires_at=datetime.utcnow() + timedelta(days=30),
                max_servers=3  # Trial limitation
            )
            
            db.add(trial_token)
            db.commit()
            db.refresh(trial_token)
            
            logger.info(f"Created trial token for user {user.email}")
            return trial_token
            
        except Exception as e:
            db.rollback()
            logger.error(f"Failed to create trial token: {e}")
            raise
    
    def create_license_token(
        self, 
        db: Session, 
        user: User, 
        token_type: TokenType, 
        duration_days: int, 
        max_servers: int = 10,
        purchase_reference: str = None
    ) -> UserToken:
        """Create a licensed token for users"""
        try:
            license_token = UserToken(
                user_id=user.id,
                token_key=self._generate_token_key(),
                token_type=token_type,
                status=TokenStatus.ACTIVE,
                expires_at=datetime.utcnow() + timedelta(days=duration_days),
                max_servers=max_servers,
                purchase_reference=purchase_reference
            )
            
            db.add(license_token)
            db.commit()
            db.refresh(license_token)
            
            logger.info(f"Created {token_type.value} token for user {user.email}")
            return license_token
            
        except Exception as e:
            db.rollback()
            logger.error(f"Failed to create license token: {e}")
            raise
    
    def validate_token(self, db: Session, token_key: str) -> Optional[UserToken]:
        """Validate a token and return it if valid"""
        try:
            token = db.query(UserToken).filter(
                UserToken.token_key == token_key,
                UserToken.status == TokenStatus.ACTIVE
            ).first()
            
            if not token:
                return None
            
            if not token.is_valid:
                # Token expired, update status
                token.status = TokenStatus.EXPIRED
                db.commit()
                return None
            
            # Update last used timestamp
            token.last_used = datetime.utcnow()
            db.commit()
            
            return token
            
        except Exception as e:
            logger.error(f"Failed to validate token: {e}")
            return None
    
    def get_user_tokens(self, db: Session, user_id: int) -> List[UserToken]:
        """Get all tokens for a user"""
        return db.query(UserToken).filter(UserToken.user_id == user_id).all()
    
    def revoke_token(self, db: Session, token_key: str) -> bool:
        """Revoke a token"""
        try:
            token = db.query(UserToken).filter(
                UserToken.token_key == token_key
            ).first()
            
            if token:
                token.status = TokenStatus.REVOKED
                db.commit()
                logger.info(f"Revoked token {token_key}")
                return True
            
            return False
            
        except Exception as e:
            db.rollback()
            logger.error(f"Failed to revoke token: {e}")
            return False
    
    def log_token_usage(
        self,
        db: Session,
        token: UserToken,
        action: str,
        ip_address: str = None,
        user_agent: str = None,
        server_name: str = None,
        server_type: str = None
    ):
        """Log token usage for analytics"""
        try:
            usage_log = TokenUsageLog(
                token_id=token.id,
                user_id=token.user_id,
                action=action,
                ip_address=ip_address,
                user_agent=user_agent,
                server_name=server_name,
                server_type=server_type
            )
            
            db.add(usage_log)
            db.commit()
            
        except Exception as e:
            db.rollback()
            logger.error(f"Failed to log token usage: {e}")
    
    def _generate_token_key(self) -> str:
        """Generate a unique token key"""
        return f"ZSM-{uuid.uuid4().hex[:16].upper()}"
    
    def get_token_stats(self, db: Session, user_id: int) -> dict:
        """Get token statistics for a user"""
        tokens = self.get_user_tokens(db, user_id)
        
        stats = {
            "total_tokens": len(tokens),
            "active_tokens": len([t for t in tokens if t.is_valid]),
            "trial_tokens": len([t for t in tokens if t.token_type == TokenType.TRIAL]),
            "licensed_tokens": len([t for t in tokens if t.token_type != TokenType.TRIAL]),
            "expired_tokens": len([t for t in tokens if t.status == TokenStatus.EXPIRED]),
        }
        
        active_token = next((t for t in tokens if t.is_valid), None)
        if active_token:
            stats["current_token"] = {
                "type": active_token.token_type.value,
                "expires_at": active_token.expires_at.isoformat(),
                "days_remaining": active_token.days_remaining,
                "max_servers": active_token.max_servers,
                "current_servers": active_token.current_servers
            }
        
        return stats

# Create global instance
token_service = TokenService()