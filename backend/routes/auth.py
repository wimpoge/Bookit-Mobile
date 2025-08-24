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