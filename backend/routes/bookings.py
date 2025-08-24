from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy import and_, or_
from typing import List
from datetime import datetime, timedelta
from database import get_db
import models
import schemas
from auth.auth import get_current_user, get_current_owner
import uuid

router = APIRouter()

@router.get("/", response_model=List[schemas.BookingResponse])
def get_user_bookings(
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    try:
        print(f"Getting bookings for user {current_user.id}")
        
        # Test basic database connection
        total_bookings = db.query(models.Booking).count()
        print(f"Total bookings in database: {total_bookings}")
        
        # Get user's bookings with hotel and review relationships
        bookings = db.query(models.Booking).filter(
            models.Booking.user_id == current_user.id
        ).all()
        print(f"Found {len(bookings)} bookings for user {current_user.id}")
        
        # If there are bookings, check if they have hotels loaded and set review status
        valid_bookings = []
        for booking in bookings:
            print(f"Booking {booking.id}: hotel_id={booking.hotel_id}, hotel={booking.hotel}")
            # Skip bookings with missing hotel_id or hotel data
            if booking.hotel_id is None:
                print(f"Skipping booking {booking.id} - missing hotel_id")
                continue
            if booking.hotel is None:
                print(f"Skipping booking {booking.id} - hotel not found")
                continue
            
            # Check if booking has a review
            has_review = db.query(models.Review).filter(
                models.Review.booking_id == booking.id
            ).first() is not None
            booking.has_review = has_review
            
            valid_bookings.append(booking)
        
        print(f"Returning {len(valid_bookings)} valid bookings")
        return valid_bookings
    except Exception as e:
        print(f"Error getting bookings: {e}")
        import traceback
        traceback.print_exc()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error retrieving bookings: {str(e)}"
        )

@router.get("/{booking_id}", response_model=schemas.BookingResponse)
def get_booking(
    booking_id: int,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    from sqlalchemy.orm import joinedload
    
    booking = db.query(models.Booking).options(
        joinedload(models.Booking.review)
    ).filter(
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
    
    # Check if booking has a review
    has_review = db.query(models.Review).filter(
        models.Review.booking_id == booking.id
    ).first() is not None
    booking.has_review = has_review
    
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
    
    # Generate QR code data for check-in
    qr_code_data = f"BOOKING_{uuid.uuid4().hex[:12].upper()}"
    
    db_booking = models.Booking(
        user_id=current_user.id,
        hotel_id=booking.hotel_id,
        check_in_date=booking.check_in_date,
        check_out_date=booking.check_out_date,
        guests=booking.guests,
        total_price=total_price,
        qr_code=qr_code_data,
        status=models.BookingStatus.PENDING  # FIXED: Explicitly set initial status
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

# NEW: Endpoint for owner to confirm pending bookings
@router.put("/{booking_id}/confirm")
def confirm_booking(
    booking_id: int,
    current_user: models.User = Depends(get_current_owner),
    db: Session = Depends(get_db)
):
    booking = db.query(models.Booking).join(models.Hotel).filter(
        and_(
            models.Booking.id == booking_id,
            models.Hotel.owner_id == current_user.id,
            models.Booking.status == models.BookingStatus.PENDING
        )
    ).first()
    
    if not booking:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Booking not found or not pending"
        )
    
    booking.status = models.BookingStatus.CONFIRMED
    db.commit()
    return {"message": "Booking confirmed successfully"}

# NEW: Endpoint for owner to reject pending bookings
@router.put("/{booking_id}/reject")
def reject_booking(
    booking_id: int,
    current_user: models.User = Depends(get_current_owner),
    db: Session = Depends(get_db)
):
    booking = db.query(models.Booking).join(models.Hotel).filter(
        and_(
            models.Booking.id == booking_id,
            models.Hotel.owner_id == current_user.id,
            models.Booking.status == models.BookingStatus.PENDING
        )
    ).first()
    
    if not booking:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Booking not found or not pending"
        )
    
    booking.status = models.BookingStatus.CANCELLED
    # Return the room to availability
    hotel = booking.hotel
    hotel.available_rooms += 1
    
    db.commit()
    return {"message": "Booking rejected successfully"}

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

@router.put("/{booking_id}/self-checkin")
def self_check_in_booking(
    booking_id: int,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    booking = db.query(models.Booking).filter(
        and_(
            models.Booking.id == booking_id,
            models.Booking.user_id == current_user.id,
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
    return {"message": "Self check-in completed successfully"}

@router.put("/{booking_id}/self-checkout")
def self_check_out_booking(
    booking_id: int,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    booking = db.query(models.Booking).filter(
        and_(
            models.Booking.id == booking_id,
            models.Booking.user_id == current_user.id,
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
    return {"message": "Self checkout completed successfully"}

@router.put("/qr-checkin/{qr_code}")
def qr_check_in_booking(
    qr_code: str,
    current_user: models.User = Depends(get_current_owner),
    db: Session = Depends(get_db)
):
    booking = db.query(models.Booking).join(models.Hotel).filter(
        and_(
            models.Booking.qr_code == qr_code,
            models.Hotel.owner_id == current_user.id,
            models.Booking.status == models.BookingStatus.CONFIRMED
        )
    ).first()
    
    if not booking:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Booking not found, not confirmed, or not for your hotel"
        )
    
    booking.status = models.BookingStatus.CHECKED_IN
    db.commit()
    return {"message": "Guest checked in successfully via QR code", "booking_id": booking.id}