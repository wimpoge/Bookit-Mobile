from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from sqlalchemy import and_, or_
from typing import List, Optional
from database import get_db
import models
import schemas
from auth.auth import get_current_user

router = APIRouter()

@router.get("/", response_model=List[schemas.FavoriteHotelResponse])
def get_user_favorite_hotels(
    skip: int = 0,
    limit: int = 100,
    city: Optional[str] = None,
    min_price: Optional[float] = None,
    max_price: Optional[float] = None,
    amenities: Optional[str] = None,
    amenities_match_all: bool = False,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    # Get user's favorite hotels with filters
    query = db.query(models.UserFavoriteHotel).join(
        models.Hotel, models.UserFavoriteHotel.hotel_id == models.Hotel.id
    ).filter(models.UserFavoriteHotel.user_id == current_user.id)
    
    # Apply filters
    if city:
        query = query.filter(models.Hotel.city.ilike(f"%{city}%"))
    
    if min_price:
        query = query.filter(models.Hotel.price_per_night >= min_price)
    
    if max_price:
        query = query.filter(models.Hotel.price_per_night <= max_price)
    
    favorites = query.offset(skip).limit(limit).all()
    
    # Apply amenities filter if specified
    if amenities:
        amenity_list = [amenity.strip() for amenity in amenities.split(",")]
        filtered_favorites = []
        
        for favorite in favorites:
            if favorite.hotel.amenities:
                hotel_amenities = favorite.hotel.amenities if isinstance(favorite.hotel.amenities, list) else []
                
                if amenities_match_all:
                    if all(amenity in hotel_amenities for amenity in amenity_list):
                        filtered_favorites.append(favorite)
                else:
                    if any(amenity in hotel_amenities for amenity in amenity_list):
                        filtered_favorites.append(favorite)
        
        return filtered_favorites
    
    return favorites

@router.post("/add/{hotel_id}")
def add_hotel_to_favorites(
    hotel_id: str,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    # Check if hotel exists
    hotel = db.query(models.Hotel).filter(models.Hotel.id == hotel_id).first()
    if not hotel:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Hotel not found"
        )
    
    # Check if already in favorites
    existing_favorite = db.query(models.UserFavoriteHotel).filter(
        and_(
            models.UserFavoriteHotel.user_id == current_user.id,
            models.UserFavoriteHotel.hotel_id == hotel_id
        )
    ).first()
    
    if existing_favorite:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Hotel is already in favorites"
        )
    
    # Add to favorites
    favorite = models.UserFavoriteHotel(
        user_id=current_user.id,
        hotel_id=hotel_id
    )
    db.add(favorite)
    db.commit()
    db.refresh(favorite)
    
    return {"message": "Hotel added to favorites successfully"}

@router.delete("/remove/{hotel_id}")
def remove_hotel_from_favorites(
    hotel_id: str,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    # Find the favorite
    favorite = db.query(models.UserFavoriteHotel).filter(
        and_(
            models.UserFavoriteHotel.user_id == current_user.id,
            models.UserFavoriteHotel.hotel_id == hotel_id
        )
    ).first()
    
    if not favorite:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Hotel not found in favorites"
        )
    
    db.delete(favorite)
    db.commit()
    
    return {"message": "Hotel removed from favorites successfully"}

@router.get("/check/{hotel_id}")
def check_if_hotel_is_favorite(
    hotel_id: str,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    # Check if hotel is in user's favorites
    favorite = db.query(models.UserFavoriteHotel).filter(
        and_(
            models.UserFavoriteHotel.user_id == current_user.id,
            models.UserFavoriteHotel.hotel_id == hotel_id
        )
    ).first()
    
    return {"is_favorite": favorite is not None}

@router.get("/hotels", response_model=List[schemas.HotelResponse])
def get_favorite_hotels_only(
    skip: int = 0,
    limit: int = 100,
    city: Optional[str] = None,
    min_price: Optional[float] = None,
    max_price: Optional[float] = None,
    amenities: Optional[str] = None,
    amenities_match_all: bool = False,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    # Get just the hotels that are favorites (without favorite metadata)
    query = db.query(models.Hotel).join(
        models.UserFavoriteHotel, models.Hotel.id == models.UserFavoriteHotel.hotel_id
    ).filter(models.UserFavoriteHotel.user_id == current_user.id)
    
    # Apply filters
    if city:
        query = query.filter(models.Hotel.city.ilike(f"%{city}%"))
    
    if min_price:
        query = query.filter(models.Hotel.price_per_night >= min_price)
    
    if max_price:
        query = query.filter(models.Hotel.price_per_night <= max_price)
    
    hotels = query.offset(skip).limit(limit).all()
    
    # Set owner names for each hotel
    for hotel in hotels:
        owner = db.query(models.User).filter(models.User.id == hotel.owner_id).first()
        hotel.owner_name = owner.full_name if owner and owner.full_name else (owner.username if owner else "Unknown Owner")
    
    # Apply amenities filter if specified
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