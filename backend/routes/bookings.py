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
        # Get user's bookings with hotel and review relationships
        bookings = db.query(models.Booking).filter(
            models.Booking.user_id == current_user.id
        ).all()
        
        # Filter valid bookings and set review status
        valid_bookings = []
        for booking in bookings:
            # Skip bookings with missing hotel_id or hotel data
            if booking.hotel_id is None or booking.hotel is None:
                continue
            
            # Check if booking has a review
            has_review = db.query(models.Review).filter(
                models.Review.booking_id == booking.id
            ).first() is not None
            booking.has_review = has_review
            
            valid_bookings.append(booking)
        
        return valid_bookings
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error retrieving bookings: {str(e)}"
        )

@router.get("/{booking_id}", response_model=schemas.BookingResponse)
def get_booking(
    booking_id: str,
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
    """Create a booking that requires Stripe payment to be confirmed.
    This endpoint creates a PENDING booking that must be paid for via Stripe before confirmation."""
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

    # DO NOT generate QR code yet - only generate after successful payment
    db_booking = models.Booking(
        user_id=current_user.id,
        hotel_id=booking.hotel_id,
        check_in_date=booking.check_in_date,
        check_out_date=booking.check_out_date,
        guests=booking.guests,
        total_price=total_price,
        qr_code=None,  # QR code will be generated after successful payment
        status=models.BookingStatus.PENDING  # REQUIRES STRIPE PAYMENT - will not be confirmed until paid
    )

    # Don't reduce room availability yet - wait for Stripe payment confirmation
    # hotel.available_rooms -= 1  # Will reduce after successful Stripe payment

    db.add(db_booking)
    db.commit()
    db.refresh(db_booking)

    # Return booking with payment requirement info
    return db_booking

@router.post("/book-with-payment", response_model=schemas.BookingResponse)
def create_booking_with_payment(
    booking: schemas.BookingCreate,
    payment_method_id: str,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Create booking and process payment in one step"""
    # First create the booking
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
    qr_code_data = f"BOOKING_{uuid.uuid4().hex[:12].upper()}"
    
    # Create booking
    db_booking = models.Booking(
        user_id=current_user.id,
        hotel_id=booking.hotel_id,
        check_in_date=booking.check_in_date,
        check_out_date=booking.check_out_date,
        guests=booking.guests,
        total_price=total_price,
        qr_code=qr_code_data,
        status=models.BookingStatus.PENDING
        # payment_status=models.PaymentStatus.PENDING  # Temporarily commented
    )
    
    db.add(db_booking)
    db.commit()
    db.refresh(db_booking)
    
    # Now process payment with Stripe
    try:
        from services.stripe_service import stripe_service

        # Get payment method
        payment_method = db.query(models.PaymentMethod).filter(
            models.PaymentMethod.id == payment_method_id,
            models.PaymentMethod.user_id == current_user.id
        ).first()

        if not payment_method:
            # Rollback booking
            db.delete(db_booking)
            db.commit()
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Payment method not found"
            )

        # Create Stripe payment intent
        amount_cents = int(total_price * 100)  # Convert to cents
        payment_intent = stripe_service.create_payment_intent(
            amount=amount_cents,
            currency="usd",
            customer_id=payment_method.provider_customer_id,
            payment_method_id=payment_method.provider_token,
            confirm=True,
            description=f"Booking payment for {booking.hotel.name} - Booking #{db_booking.id}"
        )

        if payment_intent['status'] != 'succeeded':
            # Rollback booking
            db.delete(db_booking)
            db.commit()
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Payment failed"
            )

        # Create payment record
        db_payment = models.Payment(
            user_id=current_user.id,
            booking_id=db_booking.id,
            payment_method_id=payment_method_id,
            amount=total_price,
            currency="usd",
            status="paid",
            transaction_id=payment_intent['id'],
            payment_provider="stripe",
            payment_method_type="card"
        )

        # Update booking status for successful payment
        db_booking.status = models.BookingStatus.CONFIRMED
        hotel.available_rooms -= 1  # Reduce availability on successful payment

        db.add(db_payment)
        db.commit()
        db.refresh(db_booking)

        return db_booking
        
    except Exception as e:
        # Rollback booking if payment fails
        db.delete(db_booking)
        db.commit()
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Payment failed: {str(e)}"
        )

@router.put("/{booking_id}", response_model=schemas.BookingResponse)
def update_booking(
    booking_id: str,
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
    booking_id: str,
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
    
    # Check if booking was confirmed before cancelling
    was_confirmed = booking.status == models.BookingStatus.CONFIRMED
    
    booking.status = models.BookingStatus.CANCELLED
    hotel = booking.hotel
    
    # Only increase room availability if the booking was confirmed (payment was made)
    if was_confirmed:
        hotel.available_rooms += 1
    
    db.commit()
    return {"message": "Booking cancelled successfully"}

@router.get("/{booking_id}/payment-required")
def check_payment_required(
    booking_id: str,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Check if a booking requires payment"""
    booking = db.query(models.Booking).filter(
        models.Booking.id == booking_id,
        models.Booking.user_id == current_user.id
    ).first()
    
    if not booking:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Booking not found"
        )
    
    return {
        "booking_id": booking.id,
        "requires_payment": booking.status == models.BookingStatus.PENDING,
        "total_amount": booking.total_price,
        "status": booking.status
    }

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
    booking_id: str,
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
    booking_id: str,
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
    booking_id: str,
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
    booking_id: str,
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
    booking_id: str,
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
    booking_id: str,
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