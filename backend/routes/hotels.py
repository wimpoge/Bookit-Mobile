from fastapi import APIRouter, Depends, HTTPException, status, Query, UploadFile, File
from fastapi.responses import FileResponse
from sqlalchemy.orm import Session
from sqlalchemy import and_, or_
from typing import List, Optional
from pathlib import Path
import uuid
import shutil
import os
from database import get_db
import models
import schemas
from auth.auth import get_current_user, get_current_owner

router = APIRouter()

@router.get("/", response_model=List[schemas.HotelResponse])
def get_hotels(
    skip: int = 0,
    limit: int = 100,
    city: Optional[str] = None,
    min_price: Optional[float] = None,
    max_price: Optional[float] = None,
    amenities: Optional[str] = None,
    amenities_match_all: bool = False,
    db: Session = Depends(get_db)
):
    query = db.query(models.Hotel).join(models.User, models.Hotel.owner_id == models.User.id)
    
    if city:
        query = query.filter(models.Hotel.city.ilike(f"%{city}%"))
    
    if min_price:
        query = query.filter(models.Hotel.price_per_night >= min_price)
    
    if max_price:
        query = query.filter(models.Hotel.price_per_night <= max_price)
    
    hotels = query.offset(skip).limit(limit).all()
    
    # Set owner names
    for hotel in hotels:
        owner = db.query(models.User).filter(models.User.id == hotel.owner_id).first()
        hotel.owner_name = owner.full_name if owner and owner.full_name else (owner.username if owner else "Unknown Owner")
    
    if amenities:
        amenity_list = [amenity.strip() for amenity in amenities.split(",")]
        filtered_hotels = []
        
        for hotel in hotels:
            if hotel.amenities:
                hotel_amenities = hotel.amenities if isinstance(hotel.amenities, list) else []
                
                if amenities_match_all:
                    if all(amenity in hotel_amenities for amenity in amenity_list):
                        filtered_hotels.append(hotel)
                else:
                    if any(amenity in hotel_amenities for amenity in amenity_list):
                        filtered_hotels.append(hotel)
        
        return filtered_hotels
    
    return hotels

@router.get("/search")
def search_hotels(
    q: str = Query(..., description="Search query"),
    db: Session = Depends(get_db)
):
    hotels = db.query(models.Hotel).filter(
        or_(
            models.Hotel.name.ilike(f"%{q}%"),
            models.Hotel.city.ilike(f"%{q}%"),
            models.Hotel.country.ilike(f"%{q}%"),
            models.Hotel.description.ilike(f"%{q}%")
        )
    ).all()
    return hotels

@router.get("/{hotel_id}", response_model=schemas.HotelResponse)
def get_hotel(hotel_id: int, db: Session = Depends(get_db)):
    hotel = db.query(models.Hotel).filter(models.Hotel.id == hotel_id).first()
    if not hotel:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Hotel not found"
        )
    
    # Set owner name
    owner = db.query(models.User).filter(models.User.id == hotel.owner_id).first()
    hotel.owner_name = owner.full_name if owner and owner.full_name else (owner.username if owner else "Unknown Owner")
    
    return hotel

@router.post("/", response_model=schemas.HotelResponse)
def create_hotel(
    hotel: schemas.HotelCreate,
    current_user: models.User = Depends(get_current_owner),
    db: Session = Depends(get_db)
):
    # Validate image count
    if hotel.images and len(hotel.images) > 10:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Maximum 10 images allowed per hotel"
        )
    
    db_hotel = models.Hotel(
        **hotel.dict(),
        owner_id=current_user.id,
        available_rooms=hotel.total_rooms
    )
    db.add(db_hotel)
    db.commit()
    db.refresh(db_hotel)
    return db_hotel

@router.put("/{hotel_id}", response_model=schemas.HotelResponse)
def update_hotel(
    hotel_id: int,
    hotel_update: schemas.HotelUpdate,
    current_user: models.User = Depends(get_current_owner),
    db: Session = Depends(get_db)
):
    hotel = db.query(models.Hotel).filter(
        and_(models.Hotel.id == hotel_id, models.Hotel.owner_id == current_user.id)
    ).first()
    
    if not hotel:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Hotel not found"
        )
    
    # Validate image count if images are being updated
    update_data = hotel_update.dict(exclude_unset=True)
    if 'images' in update_data and update_data['images'] and len(update_data['images']) > 10:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Maximum 10 images allowed per hotel"
        )
    
    for field, value in update_data.items():
        setattr(hotel, field, value)
    
    db.commit()
    db.refresh(hotel)
    return hotel

@router.delete("/{hotel_id}")
def delete_hotel(
    hotel_id: int,
    current_user: models.User = Depends(get_current_owner),
    db: Session = Depends(get_db)
):
    hotel = db.query(models.Hotel).filter(
        and_(models.Hotel.id == hotel_id, models.Hotel.owner_id == current_user.id)
    ).first()
    
    if not hotel:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Hotel not found"
        )
    
    db.delete(hotel)
    db.commit()
    return {"message": "Hotel deleted successfully"}

@router.get("/owner/my-hotels", response_model=List[schemas.HotelResponse])
def get_owner_hotels(
    current_user: models.User = Depends(get_current_owner),
    db: Session = Depends(get_db)
):
    hotels = db.query(models.Hotel).filter(models.Hotel.owner_id == current_user.id).all()
    return hotels

@router.post("/upload-image")
async def upload_hotel_image(
    file: UploadFile = File(...),
    current_user: models.User = Depends(get_current_owner)
):
    # Validate file type
    if not file.content_type or not file.content_type.startswith('image/'):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="File must be an image"
        )
    
    # Create uploads directory if it doesn't exist
    upload_dir = Path("uploads/hotels")
    upload_dir.mkdir(parents=True, exist_ok=True)
    
    # Generate unique filename
    file_extension = os.path.splitext(file.filename)[1] if file.filename else '.jpg'
    unique_filename = f"{uuid.uuid4()}{file_extension}"
    file_path = upload_dir / unique_filename
    
    # Save file
    try:
        with open(file_path, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to save file: {str(e)}"
        )
    
    # Return the URL for the uploaded image
    image_url = f"/uploads/hotels/{unique_filename}"
    return {"image_url": image_url, "filename": unique_filename}

@router.post("/upload-images")
async def upload_hotel_images(
    files: List[UploadFile] = File(...),
    current_user: models.User = Depends(get_current_owner)
):
    # Strict limit enforcement
    if len(files) > 10:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Maximum 10 images allowed per upload. Please select fewer images."
        )
    
    if len(files) == 0:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="At least one image is required"
        )
    
    uploaded_images = []
    upload_dir = Path("uploads/hotels")
    upload_dir.mkdir(parents=True, exist_ok=True)
    
    for file in files:
        # Validate file type
        if not file.content_type or not file.content_type.startswith('image/'):
            continue  # Skip non-image files
        
        # Generate unique filename
        file_extension = os.path.splitext(file.filename)[1] if file.filename else '.jpg'
        unique_filename = f"{uuid.uuid4()}{file_extension}"
        file_path = upload_dir / unique_filename
        
        # Save file
        try:
            with open(file_path, "wb") as buffer:
                shutil.copyfileobj(file.file, buffer)
            
            image_url = f"/uploads/hotels/{unique_filename}"
            uploaded_images.append({
                "image_url": image_url,
                "filename": unique_filename,
                "original_filename": file.filename
            })
        except Exception as e:
            continue  # Skip files that fail to upload
    
    return {"uploaded_images": uploaded_images}