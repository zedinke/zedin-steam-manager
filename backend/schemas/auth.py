from pydantic import BaseModel, EmailStr, validator
from datetime import datetime, date
from typing import Optional
from models.user import UserRole

class UserRegistration(BaseModel):
    first_name: str
    last_name: str
    email: EmailStr
    password: str
    password_confirm: str
    birth_date: date
    
    @validator('first_name', 'last_name')
    def validate_names(cls, v):
        if not v or len(v.strip()) < 2:
            raise ValueError('A név legalább 2 karakter hosszú legyen')
        if len(v) > 100:
            raise ValueError('A név maximum 100 karakter hosszú lehet')
        return v.strip()
    
    @validator('password')
    def validate_password(cls, v):
        if len(v) < 8:
            raise ValueError('A jelszó legalább 8 karakter hosszú legyen')
        if len(v) > 128:
            raise ValueError('A jelszó maximum 128 karakter hosszú lehet')
        
        # Check for at least one uppercase, one lowercase, one digit
        has_upper = any(c.isupper() for c in v)
        has_lower = any(c.islower() for c in v)
        has_digit = any(c.isdigit() for c in v)
        
        if not (has_upper and has_lower and has_digit):
            raise ValueError('A jelszónak tartalmaznia kell legalább egy nagybetűt, kisbetűt és számot')
        
        return v
    
    @validator('password_confirm')
    def passwords_match(cls, v, values):
        if 'password' in values and v != values['password']:
            raise ValueError('A jelszavak nem egyeznek')
        return v
    
    @validator('birth_date')
    def validate_birth_date(cls, v):
        if v >= date.today():
            raise ValueError('A születési dátum nem lehet jövőbeli')
        
        # Check minimum age (13 years)
        min_age_date = date.today().replace(year=date.today().year - 13)
        if v > min_age_date:
            raise ValueError('Minimum 13 évesnek kell lenned a regisztrációhoz')
        
        # Check maximum age (120 years)
        max_age_date = date.today().replace(year=date.today().year - 120)
        if v < max_age_date:
            raise ValueError('Kérlek add meg a helyes születési dátumot')
        
        return v

class UserLogin(BaseModel):
    email: EmailStr
    password: str

class UserResponse(BaseModel):
    id: int
    first_name: str
    last_name: str
    email: str
    role: UserRole
    is_active: bool
    is_verified: bool
    created_at: datetime
    last_login: Optional[datetime] = None
    
    class Config:
        from_attributes = True

class UserUpdate(BaseModel):
    first_name: Optional[str] = None
    last_name: Optional[str] = None
    email: Optional[EmailStr] = None
    
class PasswordChange(BaseModel):
    current_password: str
    new_password: str
    new_password_confirm: str
    
    @validator('new_password')
    def validate_new_password(cls, v):
        if len(v) < 8:
            raise ValueError('A jelszó legalább 8 karakter hosszú legyen')
        return v
    
    @validator('new_password_confirm')
    def passwords_match(cls, v, values):
        if 'new_password' in values and v != values['new_password']:
            raise ValueError('A jelszavak nem egyeznek')
        return v

class EmailVerificationRequest(BaseModel):
    token: str

class PasswordResetRequest(BaseModel):
    email: EmailStr

class PasswordReset(BaseModel):
    token: str
    new_password: str
    new_password_confirm: str
    
    @validator('new_password_confirm')
    def passwords_match(cls, v, values):
        if 'new_password' in values and v != values['new_password']:
            raise ValueError('A jelszavak nem egyeznek')
        return v