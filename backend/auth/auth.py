from datetime import datetime, timedelta
from typing import Optional
from jose import JWTError, jwt
from passlib.context import CryptContext
from fastapi import HTTPException, status, Depends
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.orm import Session
from database import get_db
import models
import os
from dotenv import load_dotenv

load_dotenv()

SECRET_KEY = os.getenv("SECRET_KEY", "your-secret-key-here-change-in-production")
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 60 * 24  # 24 hours instead of 30 minutes

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
security = HTTPBearer(auto_error=False)

def verify_password(plain_password, hashed_password):
    return pwd_context.verify(plain_password, hashed_password)

def get_password_hash(password):
    return pwd_context.hash(password)

def create_access_token(data: dict, expires_delta: Optional[timedelta] = None):
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt

def verify_token(credentials: HTTPAuthorizationCredentials = Depends(security)):
    print(f"verify_token called with credentials: {credentials}")
    if not credentials:
        print("No credentials provided")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Could not validate credentials - No authorization header",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    try:
        print(f"Attempting to decode token: {credentials.credentials[:20]}...")
        print(f"Using secret key: {SECRET_KEY[:10]}...")
        print(f"Using algorithm: {ALGORITHM}")
        
        payload = jwt.decode(credentials.credentials, SECRET_KEY, algorithms=[ALGORITHM])
        print(f"Token decoded successfully. Payload: {payload}")
        
        email: str = payload.get("sub")
        if email is None:
            print("No email found in token payload")
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Could not validate credentials - Invalid token payload",
                headers={"WWW-Authenticate": "Bearer"},
            )
        print(f"Email extracted from token: {email}")
        return email
    except JWTError as e:
        print(f"JWT Error: {e}")
        print(f"Token that failed: {credentials.credentials}")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"Could not validate credentials - {str(e)}",
            headers={"WWW-Authenticate": "Bearer"},
        )

def get_current_user(email: str = Depends(verify_token), db: Session = Depends(get_db)):
    print(f"get_current_user called for email: {email}")
    user = db.query(models.User).filter(models.User.email == email).first()
    if user is None:
        print(f"User not found for email: {email}")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="User not found"
        )
    if not user.is_active:
        print(f"User {email} is inactive")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Inactive user"
        )
    print(f"User found: {user.id} - {user.email}")
    return user

def get_current_owner(current_user: models.User = Depends(get_current_user)):
    if current_user.role != models.UserRole.OWNER:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not enough permissions"
        )
    return current_user

async def get_user_from_token(token: str, db: Session):
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        email: str = payload.get("sub")
        if email is None:
            return None
    except JWTError:
        return None
    
    user = db.query(models.User).filter(models.User.email == email).first()
    return user