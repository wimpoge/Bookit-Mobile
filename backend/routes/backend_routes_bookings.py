from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy import and_, or_
from typing import List
from datetime import datetime, timedelta
from database import get_db
import models
import schemas
from auth.auth import get_current_user, get_current_owner

router = APIRouter()

@router.get("/", response_model=List[schemas.BookingResponse])
def get_user_bookings(
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    bookings = db.query(models.Booking).filter(
        models.Booking.user_id == current_user.id
    ).all()
    return bookings

@router.get("/{booking_id}", response_model=schemas.BookingResponse)
def get_booking(
    booking_id: int,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    booking = db.query(models.Booking).filter(
        and_(
            models.Booking.id == booking_id,
            or_(
                models.Booking.user_id == current_user.id,
                models.Booking.hotel.has(models.Hotel.owner_id == current_user.id)
            )
        )
    ).first()
    
    if not booking:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Booking not found"
        )
    return booking

@router.post("/", response_model=schemas.BookingResponse)
def create_booking(
    booking: schemas.BookingCreate,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    hotel = db.query(models.Hotel).filter(models.Hotel.id == booking.hotel_id).first()
    if not hotel:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Hotel not found"
        )
    
    if hotel.available_rooms < 1:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="No rooms available"
        )
    
    days = (booking.check_out_date - booking.check_in_date).days
    if days <= 0:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid date range"
        )
    
    total_price = hotel.price_per_night * days
    
    db_booking = models.Booking(
        user_id=current_user.id,
        hotel_id=booking.hotel_id,
        check_in_date=booking.check_in_date,
        check_out_date=booking.check_out_date,
        guests=booking.guests,
        total_price=total_price
    )
    
    hotel.available_rooms -= 1
    
    db.add(db_booking)
    db.commit()
    db.refresh(db_booking)
    return db_booking

@router.put("/{booking_id}", response_model=schemas.BookingResponse)
def update_booking(
    booking_id: int,
    booking_update: schemas.BookingUpdate,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    booking = db.query(models.Booking).filter(
        and_(
            models.Booking.id == booking_id,
            or_(
                models.Booking.user_id == current_user.id,
                models.Booking.hotel.has(models.Hotel.owner_id == current_user.id)
            )
        )
    ).first()
    
    if not booking:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Booking not found"
        )
    
    update_data = booking_update.dict(exclude_unset=True)
    for field, value in update_data.items():
        setattr(booking, field, value)
    
    db.commit()
    db.refresh(booking)
    return booking

@router.delete("/{booking_id}")
def cancel_booking(
    booking_id: int,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    booking = db.query(models.Booking).filter(
        and_(
            models.Booking.id == booking_id,
            or_(
                models.Booking.user_id == current_user.id,
                models.Booking.hotel.has(models.Hotel.owner_id == current_user.id)
            )
        )
    ).first()
    
    if not booking:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Booking not found"
        )
    
    if booking.status in [models.BookingStatus.CHECKED_IN, models.BookingStatus.CHECKED_OUT]:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Cannot cancel booking that has already started or completed"
        )
    
    booking.status = models.BookingStatus.CANCELLED
    hotel = booking.hotel
    hotel.available_rooms += 1
    
    db.commit()
    return {"message": "Booking cancelled successfully"}

@router.get("/owner/hotel-bookings", response_model=List[schemas.BookingResponse])
def get_hotel_bookings(
    current_user: models.User = Depends(get_current_owner),
    db: Session = Depends(get_db)
):
    bookings = db.query(models.Booking).join(models.Hotel).filter(
        models.Hotel.owner_id == current_user.id
    ).all()
    return bookings

@router.put("/{booking_id}/check-in")
def check_in_booking(
    booking_id: int,
    current_user: models.User = Depends(get_current_owner),
    db: Session = Depends(get_db)
):
    booking = db.query(models.Booking).join(models.Hotel).filter(
        and_(
            models.Booking.id == booking_id,
            models.Hotel.owner_id == current_user.id,
            models.Booking.status == models.BookingStatus.CONFIRMED
        )
    ).first()
    
    if not booking:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Booking not found or not confirmed"
        )
    
    booking.status = models.BookingStatus.CHECKED_IN
    db.commit()
    return {"message": "Booking checked in successfully"}

@router.put("/{booking_id}/check-out")
def check_out_booking(
    booking_id: int,
    current_user: models.User = Depends(get_current_owner),
    db: Session = Depends(get_db)
):
    booking = db.query(models.Booking).join(models.Hotel).filter(
        and_(
            models.Booking.id == booking_id,
            models.Hotel.owner_id == current_user.id,
            models.Booking.status == models.BookingStatus.CHECKED_IN
        )
    ).first()
    
    if not booking:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Booking not found or not checked in"
        )
    
    booking.status = models.BookingStatus.CHECKED_OUT
    db.commit()
    return {"message": "Booking checked out successfully"}