from fastapi import APIRouter, Depends, HTTPException, status, Query, UploadFile, File, Form
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

@router.get("/", response_model=List[schemas.HotelResponse])
def get_hotels(
    skip: int = 0,
    limit: int = 100,
    city: Optional[str] = None,
    min_price: Optional[float] = None,
    max_price: Optional[float] = None,
    min_rating: Optional[float] = None,
    search: Optional[str] = None,
    sort_by: Optional[str] = None,  # 'name', 'rating', 'price', 'city'
    sort_desc: bool = False,
    db: Session = Depends(get_db)
):
    query = db.query(models.Hotel)
    
    # Search filter
    if search:
        query = query.filter(
            or_(
                models.Hotel.name.ilike(f"%{search}%"),
                models.Hotel.city.ilike(f"%{search}%"),
                models.Hotel.country.ilike(f"%{search}%"),
                models.Hotel.description.ilike(f"%{search}%")
            )
        )
    
    # City filter
    if city:
        query = query.filter(models.Hotel.city.ilike(f"%{city}%"))
        
    # Price range filter
    if min_price:
        query = query.filter(models.Hotel.price_per_night >= min_price)
    if max_price:
        query = query.filter(models.Hotel.price_per_night <= max_price)
        
    # Rating filter
    if min_rating:
        query = query.filter(models.Hotel.rating >= min_rating)
    
    # Sorting
    if sort_by:
        if sort_by.lower() == 'name':
            order_col = models.Hotel.name
        elif sort_by.lower() == 'rating':
            order_col = models.Hotel.rating
        elif sort_by.lower() == 'price':
            order_col = models.Hotel.price_per_night
        elif sort_by.lower() == 'city':
            order_col = models.Hotel.city
        else:
            order_col = models.Hotel.name
            
        if sort_desc:
            query = query.order_by(order_col.desc())
        else:
            query = query.order_by(order_col.asc())
    else:
        query = query.order_by(models.Hotel.created_at.desc())  # Default sort by newest
        
    hotels = query.offset(skip).limit(limit).all()
    
    # Set owner names
    for hotel in hotels:
        owner = db.query(models.User).filter(models.User.id == hotel.owner_id).first()
        hotel.owner_name = owner.full_name if owner and owner.full_name else (owner.username if owner else "Unknown Owner")
        
    return hotels

@router.get("/{hotel_id}", response_model=schemas.HotelResponse)
def get_hotel(hotel_id: str, db: Session = Depends(get_db)):
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
    hotel_id: str,
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
    hotel_id: str,
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
    skip: int = 0,
    limit: int = 100,
    city: Optional[str] = None,
    status: Optional[str] = None,  # 'active', 'full', 'recent'
    sort_by: Optional[str] = None,  # 'name', 'rating', 'rooms', 'price', 'date'
    sort_desc: bool = False,
    search: Optional[str] = None,
    min_price: Optional[float] = None,
    max_price: Optional[float] = None,
    min_rating: Optional[float] = None,
    current_user: models.User = Depends(get_current_owner),
    db: Session = Depends(get_db)
):
    from datetime import datetime, timedelta
    
    try:
        query = db.query(models.Hotel).filter(models.Hotel.owner_id == current_user.id)
        
        # Search filter
        if search:
            query = query.filter(
                or_(
                    models.Hotel.name.ilike(f"%{search}%"),
                    models.Hotel.city.ilike(f"%{search}%"),
                    models.Hotel.country.ilike(f"%{search}%"),
                    models.Hotel.description.ilike(f"%{search}%")
                )
            )
        
        # City filter
        if city:
            query = query.filter(models.Hotel.city.ilike(f"%{city}%"))
            
        # Price range filter
        if min_price:
            query = query.filter(models.Hotel.price_per_night >= min_price)
        if max_price:
            query = query.filter(models.Hotel.price_per_night <= max_price)
            
        # Rating filter
        if min_rating:
            query = query.filter(models.Hotel.rating >= min_rating)
            
        # Status filter
        if status:
            if status.lower() == 'active':
                query = query.filter(models.Hotel.available_rooms > 0)
            elif status.lower() == 'full':
                query = query.filter(models.Hotel.available_rooms == 0)
            elif status.lower() == 'recent':
                one_week_ago = datetime.now() - timedelta(days=7)
                query = query.filter(models.Hotel.created_at >= one_week_ago)
        
        # Sorting
        if sort_by:
            if sort_by.lower() == 'name':
                order_col = models.Hotel.name
            elif sort_by.lower() == 'rating':
                order_col = models.Hotel.rating
            elif sort_by.lower() == 'rooms':
                order_col = models.Hotel.available_rooms
            elif sort_by.lower() == 'price':
                order_col = models.Hotel.price_per_night
            elif sort_by.lower() == 'date':
                order_col = models.Hotel.created_at
            else:
                order_col = models.Hotel.name
                
            if sort_desc:
                query = query.order_by(order_col.desc())
            else:
                query = query.order_by(order_col.asc())
        else:
            query = query.order_by(models.Hotel.created_at.desc())  # Default sort by newest
            
        hotels = query.offset(skip).limit(limit).all()
        
        # Set owner names
        for hotel in hotels:
            hotel.owner_name = current_user.full_name if current_user.full_name else current_user.username
            
        return hotels
        
    except Exception as e:
        print(f"Error in get_owner_hotels: {e}")
        raise HTTPException(status_code=500, detail="Failed to retrieve hotels")

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
    hotel_name: str = Form(None),
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
    
    from datetime import datetime
    import re
    
    
    # Create new directory structure: uploads/hotels/owner_name_hotel/DD-MM-YYYY/name_hotel_uuid/
    # Clean owner name for directory (replace @ and . with _)
    owner_name_clean = re.sub(r'[^\w\-_]', '_', current_user.full_name or current_user.email.split('@')[0])
    
    # Clean hotel name for directory structure
    hotel_name_clean = re.sub(r'[^\w\-_]', '_', hotel_name) if hotel_name else "unnamed_hotel"
    
    # Create date folder in DD-MM-YYYY format
    current_date = datetime.now().strftime("%d-%m-%Y")
    
    # Generate unique folder name with hotel name and UUID
    import uuid
    hotel_uuid = str(uuid.uuid4())[:8]  # Use first 8 characters of UUID
    folder_name = f"{hotel_name_clean}_{hotel_uuid}"
    
    # Create the full directory structure
    upload_dir = Path(f"uploads/hotels/{owner_name_clean}/{current_date}/{folder_name}")
    upload_dir.mkdir(parents=True, exist_ok=True)
    
    uploaded_images = []
    
    for i, file in enumerate(files):
        
        # Validate file type - check both content type and file extension
        is_image_by_content_type = file.content_type and file.content_type.startswith('image/')
        is_image_by_extension = False
        file_ext_check = None
        if file.filename:
            file_ext_check = os.path.splitext(file.filename)[1].lower()
            is_image_by_extension = file_ext_check in ['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp']
        
        if not (is_image_by_content_type or is_image_by_extension):
            continue  # Skip non-image files
        
        # Generate filename with simple structure
        file_extension = os.path.splitext(file.filename)[1] if file.filename else '.jpg'
        unique_filename = f"image_{i+1}{file_extension}"
        file_path = upload_dir / unique_filename
        
        # Save file
        try:
            with open(file_path, "wb") as buffer:
                shutil.copyfileobj(file.file, buffer)
            
            image_url = f"/uploads/hotels/{owner_name_clean}/{current_date}/{folder_name}/{unique_filename}"
            uploaded_images.append({
                "image_url": image_url,
                "filename": unique_filename,
                "original_filename": file.filename
            })
        except Exception as e:
            continue  # Skip files that fail to upload
    
    return {"uploaded_images": uploaded_images}

@router.get("/nearby", response_model=List[schemas.HotelResponse])
def get_nearby_hotels(
    lat: float = Query(..., description="User's latitude"),
    lon: float = Query(..., description="User's longitude"), 
    radius_km: float = Query(10.0, description="Search radius in kilometers"),
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db)
):
    """
    Get hotels near a given location using Haversine formula
    """
    import math
    
    # Convert radius from km to degrees (approximation)
    # 1 degree ≈ 111 km
    radius_deg = radius_km / 111.0
    
    # Query hotels within bounding box first (for performance)
    hotels = db.query(models.Hotel).filter(
        and_(
            models.Hotel.latitude.between(lat - radius_deg, lat + radius_deg),
            models.Hotel.longitude.between(lon - radius_deg, lon + radius_deg)
        )
    ).all()
    
    # Filter by actual distance using Haversine formula
    nearby_hotels = []
    for hotel in hotels:
        if hotel.latitude and hotel.longitude:
            distance = _calculate_distance(lat, lon, hotel.latitude, hotel.longitude)
            if distance <= radius_km:
                hotel.distance_km = round(distance, 2)
                nearby_hotels.append(hotel)
    
    # Sort by distance
    nearby_hotels.sort(key=lambda x: getattr(x, 'distance_km', float('inf')))
    
    # Apply pagination
    return nearby_hotels[skip:skip + limit]

@router.get("/deals", response_model=List[schemas.HotelResponse])
def get_hotel_deals(
    max_price: Optional[float] = Query(None, description="Maximum price filter"),
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db)
):
    """
    Get hotels with good deals - prioritize discounted hotels and good ratings
    """
    query = db.query(models.Hotel)
    
    # Filter by available rooms
    query = query.filter(models.Hotel.available_rooms > 0)
    
    # Filter by maximum price (consider both original and discount price)
    if max_price:
        query = query.filter(
            or_(
                and_(models.Hotel.is_deal == True, models.Hotel.discount_price <= max_price),
                and_(models.Hotel.is_deal != True, models.Hotel.price_per_night <= max_price)
            )
        )
    
    # Prioritize deals and good ratings
    # Order by: deals first (is_deal), then by discount percentage (desc), then by rating (desc)
    deals = query.filter(
        and_(
            models.Hotel.rating >= 3.5,  # Lower threshold to show more options
            models.Hotel.price_per_night.isnot(None)
        )
    ).order_by(
        models.Hotel.is_deal.desc(),  # Deals first
        models.Hotel.discount_percentage.desc(),  # Higher discounts first
        models.Hotel.rating.desc(),  # Better ratings first
        models.Hotel.price_per_night.asc()  # Lower prices first
    ).offset(skip).limit(limit).all()
    
    return deals

def _calculate_distance(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    """
    Calculate the great circle distance between two points 
    on the earth (specified in decimal degrees) using Haversine formula
    Returns distance in kilometers
    """
    import math
    
    # Convert decimal degrees to radians
    lat1, lon1, lat2, lon2 = map(math.radians, [lat1, lon1, lat2, lon2])
    
    # Haversine formula
    dlat = lat2 - lat1
    dlon = lon2 - lon1
    a = math.sin(dlat/2)**2 + math.cos(lat1) * math.cos(lat2) * math.sin(dlon/2)**2
    c = 2 * math.asin(math.sqrt(a))
    
    # Radius of earth in kilometers
    r = 6371
    
    return c * r

@router.patch("/owner/{hotel_id}/discount")
def update_hotel_discount(
    hotel_id: str,
    discount_percentage: float = Query(..., ge=0, le=100, description="Discount percentage (0-100)"),
    current_user: models.User = Depends(get_current_owner),
    db: Session = Depends(get_db)
):
    """
    Update discount for a hotel owned by the current user
    """
    # Verify hotel belongs to the owner
    hotel = db.query(models.Hotel).filter(
        and_(
            models.Hotel.id == hotel_id,
            models.Hotel.owner_id == current_user.id
        )
    ).first()
    
    if not hotel:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Hotel not found or you don't have permission to update it"
        )
    
    # Calculate discount price
    original_price = float(hotel.price_per_night or hotel.base_price_per_night or 0)
    if discount_percentage > 0:
        discount_price = original_price * (1 - discount_percentage / 100)
        is_deal = True
    else:
        discount_price = None
        is_deal = False
    
    # Update hotel
    hotel.discount_percentage = discount_percentage
    hotel.discount_price = discount_price
    hotel.is_deal = is_deal
    
    try:
        db.commit()
        db.refresh(hotel)
        
        return {
            "message": "Hotel discount updated successfully",
            "hotel_id": hotel_id,
            "discount_percentage": discount_percentage,
            "original_price": original_price,
            "discount_price": discount_price,
            "is_deal": is_deal
        }
    except Exception as e:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to update hotel discount: {str(e)}"
        )