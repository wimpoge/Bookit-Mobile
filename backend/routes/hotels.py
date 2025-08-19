from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from sqlalchemy import and_, or_
from typing import List, Optional
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
    db: Session = Depends(get_db)
):
    query = db.query(models.Hotel)
    
    if city:
        query = query.filter(models.Hotel.city.ilike(f"%{city}%"))
    
    if min_price:
        query = query.filter(models.Hotel.price_per_night >= min_price)
    
    if max_price:
        query = query.filter(models.Hotel.price_per_night <= max_price)
    
    if amenities:
        amenity_list = amenities.split(",")
        for amenity in amenity_list:
            query = query.filter(models.Hotel.amenities.contains([amenity.strip()]))
    
    hotels = query.offset(skip).limit(limit).all()
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
    return hotel

@router.post("/", response_model=schemas.HotelResponse)
def create_hotel(
    hotel: schemas.HotelCreate,
    current_user: models.User = Depends(get_current_owner),
    db: Session = Depends(get_db)
):
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
    
    update_data = hotel_update.dict(exclude_unset=True)
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