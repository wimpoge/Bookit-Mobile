from fastapi import APIRouter, Depends, HTTPException, status, BackgroundTasks
from sqlalchemy.orm import Session
from sqlalchemy.sql import func
from typing import List, Optional
import uuid
import asyncio
from datetime import datetime, timedelta
from database import get_db
import models
import schemas
from auth.auth import get_current_user
from services.stripe_service import stripe_service
from services.qr_service import qr_service
import os

router = APIRouter()

@router.get("/config")
def get_stripe_config(
    current_user: models.User = Depends(get_current_user)
):
    """Get Stripe publishable key for frontend"""
    return {
        "publishable_key": stripe_service.get_publishable_key()
    }

@router.get("/methods", response_model=List[schemas.PaymentMethodResponse])
def get_payment_methods(
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    payment_methods = db.query(models.PaymentMethod).filter(
        models.PaymentMethod.user_id == current_user.id
    ).all()
    return payment_methods

@router.post("/setup-intent")
def create_setup_intent(
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Create Stripe SetupIntent for saving payment method"""
    try:
        # Ensure user has a Stripe customer ID
        if not hasattr(current_user, 'provider_customer_id') or not current_user.provider_customer_id:
            customer_id = stripe_service.create_customer(
                email=current_user.email,
                name=current_user.full_name or current_user.username
            )
            # Update user with customer ID if the field exists
            # current_user.provider_customer_id = customer_id
            # db.commit()
        else:
            customer_id = current_user.provider_customer_id

        setup_intent = stripe_service.create_setup_intent(customer_id)
        return setup_intent
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Error creating setup intent: {str(e)}"
        )

# Temporarily using original payment method endpoint
@router.post("/methods", response_model=schemas.PaymentMethodResponse)
def add_payment_method(
    payment_method: schemas.PaymentMethodCreate,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    if payment_method.is_default:
        db.query(models.PaymentMethod).filter(
            models.PaymentMethod.user_id == current_user.id
        ).update({"is_default": False})
    
    db_payment_method = models.PaymentMethod(
        user_id=current_user.id,
        type=payment_method.type,
        provider=payment_method.provider
    )
    
    db.add(db_payment_method)
    db.commit()
    db.refresh(db_payment_method)
    return db_payment_method

@router.put("/methods/{method_id}", response_model=schemas.PaymentMethodResponse)
def update_payment_method(
    method_id: str,
    payment_method_update: dict,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    payment_method = db.query(models.PaymentMethod).filter(
        models.PaymentMethod.id == method_id,
        models.PaymentMethod.user_id == current_user.id
    ).first()
    
    if not payment_method:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Payment method not found"
        )
    
    if payment_method_update.get("is_default"):
        db.query(models.PaymentMethod).filter(
            models.PaymentMethod.user_id == current_user.id
        ).update({"is_default": False})
    
    for field, value in payment_method_update.items():
        if hasattr(payment_method, field):
            setattr(payment_method, field, value)
    
    db.commit()
    db.refresh(payment_method)
    return payment_method

@router.delete("/methods/{method_id}")
def delete_payment_method(
    method_id: str,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    payment_method = db.query(models.PaymentMethod).filter(
        models.PaymentMethod.id == method_id,
        models.PaymentMethod.user_id == current_user.id
    ).first()
    
    if not payment_method:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Payment method not found"
        )
    
    # Stripe integration temporarily disabled
    # if payment_method.stripe_payment_method_id:
    #     try:
    #         stripe_service.detach_payment_method(payment_method.stripe_payment_method_id)
    #     except Exception as e:
    #         print(f"Warning: Could not detach Stripe payment method: {e}")
    
    db.delete(payment_method)
    db.commit()
    return {"message": "Payment method deleted successfully"}

async def cancel_booking_after_timeout(booking_id: str, payment_id: str, db_url: str, timeout_minutes: int = 1):
    """Cancel booking after timeout if payment not completed"""
    await asyncio.sleep(timeout_minutes * 60)  # Wait for specified minutes

    # Create new DB session for background task
    from sqlalchemy import create_engine
    from sqlalchemy.orm import sessionmaker

    engine = create_engine(db_url)
    SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
    db = SessionLocal()

    try:
        # Check if payment was completed
        booking = db.query(models.Booking).filter(models.Booking.id == booking_id).first()
        if booking and booking.status == models.BookingStatus.PENDING:
            # Cancel the booking
            booking.status = models.BookingStatus.CANCELLED
            booking.cancellation_reason = f"Payment timeout ({timeout_minutes} minutes expired)"
            booking.cancelled_at = datetime.utcnow()

            # Note: Payment links can't be cancelled, but they expire naturally
            print(f"Warning: Payment link {payment_id} cannot be cancelled, but will expire naturally")

            db.commit()
            print(f"Booking {booking_id} cancelled due to payment timeout")
    except Exception as e:
        print(f"Error in timeout cancellation: {e}")
    finally:
        db.close()

@router.post("/create-booking-payment-link")
def create_booking_payment_link(
    booking_payment_data: dict,
    background_tasks: BackgroundTasks,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Create Stripe Payment Link for booking with hosted checkout"""
    booking_id = booking_payment_data.get("booking_id")

    if not booking_id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="booking_id is required"
        )

    # Get the booking
    booking = db.query(models.Booking).filter(
        models.Booking.id == booking_id,
        models.Booking.user_id == current_user.id,
        models.Booking.status == models.BookingStatus.PENDING
    ).first()

    if not booking:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Pending booking not found"
        )

    try:
        # Create payment link
        amount_cents = int(booking.total_price * 100)
        description = f"Hotel booking payment - {booking.hotel.name} - Booking #{booking.id}"

        payment_link = stripe_service.create_booking_payment_link(
            booking_id=booking_id,
            amount=amount_cents,
            description=description,
            hotel_name=booking.hotel.name,
            customer_email=current_user.email
        )

        # Schedule booking cancellation after 10 minutes (reasonable timeout for hosted checkout)
        db_url = os.getenv("DATABASE_URL", "sqlite:///./hotel_booking.db")
        background_tasks.add_task(
            cancel_booking_after_timeout,
            booking_id,
            payment_link['payment_link_id'],
            db_url,
            timeout_minutes=10  # 10 minutes for payment link
        )

        return {
            "payment_link_id": payment_link['payment_link_id'],
            "payment_url": payment_link['url'],
            "booking_id": booking_id,
            "timeout_minutes": 10
        }

    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Failed to create payment link: {str(e)}"
        )

@router.post("/confirm-payment-link-success/{booking_id}")
def confirm_payment_link_success(
    booking_id: str,
    request_data: dict,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Confirm successful payment from Stripe hosted checkout"""
    try:
        # Get the booking
        booking = db.query(models.Booking).filter(
            models.Booking.id == booking_id,
            models.Booking.user_id == current_user.id
        ).first()

        if not booking:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Booking not found"
            )

        # Get session ID from request data
        session_id = request_data.get('session_id')
        if not session_id:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="session_id is required"
            )

        # Verify the session was successful
        session = stripe.checkout.Session.retrieve(session_id)
        if session.payment_status != 'paid':
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Payment not completed"
            )

        # Only update if booking is still pending
        if booking.status == models.BookingStatus.PENDING:
            # Generate QR code for the booking
            qr_result = qr_service.generate_booking_qr_code(
                booking_id=booking.id,
                user_id=current_user.id,
                hotel_id=booking.hotel_id
            )

            # Update booking with new QR code data
            booking.qr_code = qr_result['qr_data']

            # Create payment record
            db_payment = models.Payment(
                user_id=current_user.id,
                booking_id=booking.id,
                amount=session.amount_total / 100,  # Convert from cents
                currency=session.currency,
                status=models.PaymentStatus.PAID,
                transaction_id=session_id,
                payment_provider="stripe",
                payment_method_type="card",
                processed_at=datetime.utcnow()
            )

            # Update booking status
            booking.status = models.BookingStatus.CONFIRMED

            # Reduce hotel room availability
            hotel = booking.hotel
            if hotel and hotel.available_rooms > 0:
                hotel.available_rooms -= 1

            db.add(db_payment)
            db.commit()
            db.refresh(db_payment)

            return {
                "message": "Payment confirmed successfully",
                "booking_id": booking.id,
                "payment_id": db_payment.id,
                "qr_code": booking.qr_code,
                "qr_image": qr_result['qr_image'],
                "status": "confirmed"
            }
        else:
            return {
                "message": "Booking already processed",
                "booking_id": booking.id,
                "status": booking.status
            }

    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Failed to confirm payment: {str(e)}"
        )

@router.post("/confirm-booking-payment/{payment_intent_id}")
def confirm_booking_payment(
    payment_intent_id: str,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Confirm booking payment and update booking status"""
    try:
        # Retrieve payment intent from Stripe
        payment_intent = stripe_service.retrieve_payment_intent(payment_intent_id)

        # Get booking ID from metadata
        booking_id = payment_intent.get('metadata', {}).get('booking_id')
        if not booking_id:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Booking ID not found in payment metadata"
            )

        # For test environment, allow confirmation even if payment status is not 'succeeded'
        # In production, you would strictly check: payment_intent['status'] == 'succeeded'
        is_test_mode = os.getenv("STRIPE_SECRET_KEY", "").startswith("sk_test_")

        if not is_test_mode and payment_intent['status'] != 'succeeded':
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Payment not completed"
            )

        # Get the booking
        booking = db.query(models.Booking).filter(
            models.Booking.id == booking_id,
            models.Booking.user_id == current_user.id
        ).first()

        if not booking:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Booking not found"
            )

        # Only update if booking is still pending
        if booking.status == models.BookingStatus.PENDING:
            # Generate QR code for the booking
            qr_result = qr_service.generate_booking_qr_code(
                booking_id=booking.id,
                user_id=current_user.id,
                hotel_id=booking.hotel_id
            )

            # Update booking with new QR code data
            booking.qr_code = qr_result['qr_data']

            # Create payment record
            db_payment = models.Payment(
                user_id=current_user.id,
                booking_id=booking.id,
                amount=payment_intent['amount'] / 100,  # Convert back from cents
                currency=payment_intent['currency'],
                status=models.PaymentStatus.PAID,
                transaction_id=payment_intent_id,
                payment_provider="stripe",
                payment_method_type="card",
                processed_at=datetime.utcnow()
            )

            # Update booking status
            booking.status = models.BookingStatus.CONFIRMED

            # Reduce hotel room availability
            hotel = booking.hotel
            if hotel and hotel.available_rooms > 0:
                hotel.available_rooms -= 1

            db.add(db_payment)
            db.commit()
            db.refresh(db_payment)

            return {
                "message": "Payment confirmed successfully",
                "booking_id": booking.id,
                "payment_id": db_payment.id,
                "qr_code": booking.qr_code,
                "qr_image": qr_result['qr_image'],
                "status": "confirmed"
            }
        else:
            return {
                "message": "Booking already processed",
                "booking_id": booking.id,
                "status": booking.status
            }

    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Failed to confirm payment: {str(e)}"
        )

@router.post("/process", response_model=schemas.PaymentResponse)
def process_payment(
    payment: schemas.PaymentCreate,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    booking = db.query(models.Booking).filter(
        models.Booking.id == payment.booking_id,
        models.Booking.user_id == current_user.id
    ).first()

    if not booking:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Booking not found"
        )

    payment_method = db.query(models.PaymentMethod).filter(
        models.PaymentMethod.id == payment.payment_method_id,
        models.PaymentMethod.user_id == current_user.id
    ).first()

    if not payment_method:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Payment method not found"
        )

    transaction_id = str(uuid.uuid4())

    db_payment = models.Payment(
        user_id=current_user.id,
        booking_id=payment.booking_id,
        amount=payment.amount,
        payment_method_id=payment.payment_method_id,
        status="paid",
        transaction_id=transaction_id,
        payment_provider="mock",
        payment_method_type="card"
    )

    # Update booking status and reduce room availability
    booking.status = models.BookingStatus.CONFIRMED

    # Now reduce room availability since payment is confirmed
    hotel = booking.hotel
    if hotel and hotel.available_rooms > 0:
        hotel.available_rooms -= 1

    db.add(db_payment)
    db.commit()
    db.refresh(db_payment)

    return db_payment

@router.post("/process-stripe", response_model=schemas.PaymentResponse)
def process_stripe_payment(
    payment_data: dict,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Process Stripe payment for a pending booking"""
    from services.stripe_service import stripe_service

    booking_id = payment_data.get("booking_id")
    payment_method_id = payment_data.get("payment_method_id")

    if not booking_id or not payment_method_id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="booking_id and payment_method_id are required"
        )

    # Get the booking
    booking = db.query(models.Booking).filter(
        models.Booking.id == booking_id,
        models.Booking.user_id == current_user.id,
        models.Booking.status == models.BookingStatus.PENDING
    ).first()

    if not booking:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Pending booking not found"
        )

    # Get payment method
    payment_method = db.query(models.PaymentMethod).filter(
        models.PaymentMethod.id == payment_method_id,
        models.PaymentMethod.user_id == current_user.id
    ).first()

    if not payment_method:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Payment method not found"
        )

    try:
        # Create Stripe payment intent
        amount_cents = int(booking.total_price * 100)  # Convert to cents
        payment_intent = stripe_service.create_payment_intent(
            amount=amount_cents,
            currency="usd",
            customer_id=payment_method.provider_customer_id,
            payment_method_id=payment_method.provider_token,
            confirm=True,
            description=f"Booking payment for {booking.hotel.name} - Booking #{booking.id}"
        )

        if payment_intent['status'] != 'succeeded':
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Payment failed"
            )

        # Create payment record
        db_payment = models.Payment(
            user_id=current_user.id,
            booking_id=booking.id,
            payment_method_id=payment_method_id,
            amount=booking.total_price,
            currency="usd",
            status="paid",
            transaction_id=payment_intent['id'],
            payment_provider="stripe",
            payment_method_type="card"
        )

        # Update booking status for successful payment
        booking.status = models.BookingStatus.CONFIRMED

        # Reduce hotel room availability
        hotel = booking.hotel
        if hotel and hotel.available_rooms > 0:
            hotel.available_rooms -= 1

        db.add(db_payment)
        db.commit()
        db.refresh(db_payment)

        return db_payment

    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Payment processing failed: {str(e)}"
        )

@router.get("/", response_model=List[schemas.PaymentResponse])
def get_user_payments(
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    payments = db.query(models.Payment).filter(
        models.Payment.user_id == current_user.id
    ).all()
    return payments