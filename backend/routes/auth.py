from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import HTTPBearer
from sqlalchemy.orm import Session
from datetime import timedelta
from database import get_db
import models
import schemas
from auth.auth import verify_password, get_password_hash, create_access_token, ACCESS_TOKEN_EXPIRE_MINUTES
from google.auth.transport import requests
from google.oauth2 import id_token
from services.email_service import email_service
from utils.token_utils import create_reset_token_with_expiry, is_token_expired
import logging
import asyncio

router = APIRouter()
security = HTTPBearer()

@router.post("/register", response_model=schemas.Token)
def register(user: schemas.UserCreate, db: Session = Depends(get_db)):
    db_user = db.query(models.User).filter(
        (models.User.email == user.email) | (models.User.username == user.username)
    ).first()
    if db_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email or username already registered"
        )
    
    hashed_password = get_password_hash(user.password)
    db_user = models.User(
        email=user.email,
        username=user.username,
        hashed_password=hashed_password,
        full_name=user.full_name,
        phone=user.phone,
        role=models.UserRole.USER
    )
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    
    access_token_expires = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(
        data={"sub": db_user.email}, expires_delta=access_token_expires
    )
    
    return {
        "access_token": access_token,
        "token_type": "bearer",
        "user": db_user
    }

@router.post("/login", response_model=schemas.Token)
def login(user_credentials: schemas.UserLogin, db: Session = Depends(get_db)):
    user = db.query(models.User).filter(models.User.email == user_credentials.email).first()
    
    if not user or not verify_password(user_credentials.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password"
        )
    
    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Inactive user"
        )
    
    access_token_expires = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(
        data={"sub": user.email}, expires_delta=access_token_expires
    )
    
    return {
        "access_token": access_token,
        "token_type": "bearer",
        "user": user
    }

@router.post("/owner/register", response_model=schemas.UserResponse)
def register_owner(owner: schemas.OwnerCreate, db: Session = Depends(get_db)):
    db_user = db.query(models.User).filter(
        (models.User.email == owner.email) | (models.User.username == owner.username)
    ).first()
    if db_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email or username already registered"
        )
    
    hashed_password = get_password_hash(owner.password)
    db_user = models.User(
        email=owner.email,
        username=owner.username,
        hashed_password=hashed_password,
        full_name=owner.full_name,
        phone=owner.phone,
        role=models.UserRole.OWNER
    )
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    
    return db_user

@router.post("/google", response_model=schemas.Token)
def google_login(google_data: schemas.GoogleLogin, db: Session = Depends(get_db)):
    try:
        # Verify the Google ID token
        idinfo = id_token.verify_oauth2_token(
            google_data.id_token, 
            requests.Request(),
            audience=None  # Skip audience verification for mobile apps
        )
        
        # Extract user information from the token
        email = idinfo['email']
        name = idinfo.get('name', '')
        google_id = idinfo['sub']
        
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Invalid Google token: {str(e)}"
        )
    
    # Check if user already exists
    user = db.query(models.User).filter(models.User.email == email).first()
    
    if not user:
        # Create new user with Google account
        # Generate a username from email
        username = email.split('@')[0]
        # Check if username exists and append number if needed
        base_username = username
        counter = 1
        while db.query(models.User).filter(models.User.username == username).first():
            username = f"{base_username}{counter}"
            counter += 1
            
        user = models.User(
            email=email,
            username=username,
            full_name=name,
            hashed_password="",  # No password for OAuth users
            role=models.UserRole.USER,
            is_active=True
        )
        db.add(user)
        db.commit()
        db.refresh(user)
    
    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Inactive user"
        )
    
    access_token_expires = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(
        data={"sub": user.email}, expires_delta=access_token_expires
    )
    
    return {
        "access_token": access_token,
        "token_type": "bearer",
        "user": user
    }

@router.post("/forgot-password")
async def forgot_password(request: schemas.ForgotPassword, db: Session = Depends(get_db)):
    # Check if user exists
    user = db.query(models.User).filter(models.User.email == request.email).first()
    
    if not user:
        # For security reasons, we don't reveal if the email exists or not
        # Return success even if email doesn't exist
        return {"message": "If the email exists, a password reset link has been sent"}
    
    try:
        # Generate a secure reset token with 1-hour expiry
        reset_token, expiry_time = create_reset_token_with_expiry(expiry_hours=1)
        
        # Store the token in the database
        user.reset_token = reset_token
        user.reset_token_expires = expiry_time
        db.commit()
        
        # Send the password reset email
        user_name = user.full_name or user.email.split('@')[0]
        email_sent = await email_service.send_password_reset_email(
            to_email=user.email,
            reset_token=reset_token,
            user_name=user_name
        )
        
        if email_sent:
            logging.info(f"Password reset email sent successfully to {request.email}")
        else:
            logging.error(f"Failed to send password reset email to {request.email}")
            # Even if email fails, we don't reveal this to the user for security
        
        return {"message": "If the email exists, a password reset link has been sent"}
        
    except Exception as e:
        logging.error(f"Error in forgot_password for {request.email}: {str(e)}")
        # For security, still return success message
        return {"message": "If the email exists, a password reset link has been sent"}

@router.post("/reset-password")
def reset_password(request: schemas.ResetPassword, db: Session = Depends(get_db)):
    # Find user by reset token
    user = db.query(models.User).filter(models.User.reset_token == request.token).first()
    
    if not user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid or expired reset token"
        )
    
    # Check if token has expired
    if not user.reset_token_expires or is_token_expired(user.reset_token_expires):
        # Clear the expired token
        user.reset_token = None
        user.reset_token_expires = None
        db.commit()
        
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid or expired reset token"
        )
    
    # Validate new password (you can add more validation here)
    if len(request.new_password) < 6:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Password must be at least 6 characters long"
        )
    
    # Update the user's password
    user.hashed_password = get_password_hash(request.new_password)
    user.reset_token = None  # Clear the reset token
    user.reset_token_expires = None
    db.commit()
    
    logging.info(f"Password reset successful for user: {user.email}")
    
    return {"message": "Password reset successful"}