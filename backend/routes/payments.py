from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
import uuid
from database import get_db
import models
import schemas
from auth.auth import get_current_user

router = APIRouter()

@router.get("/methods", response_model=List[schemas.PaymentMethodResponse])
def get_payment_methods(
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    payment_methods = db.query(models.PaymentMethod).filter(
        models.PaymentMethod.user_id == current_user.id
    ).all()
    return payment_methods

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
        provider=payment_method.provider,
        account_info=payment_method.account_info,
        is_default=payment_method.is_default
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
    
    db.delete(payment_method)
    db.commit()
    return {"message": "Payment method deleted successfully"}

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
        amount=payment.amount,
        payment_method_id=payment.payment_method_id,
        status="completed",
        transaction_id=transaction_id
    )
    
    booking.payment_id = db_payment.id
    booking.status = models.BookingStatus.CONFIRMED
    
    db.add(db_payment)
    db.commit()
    db.refresh(db_payment)
    
    return db_payment

@router.get("/", response_model=List[schemas.PaymentResponse])
def get_user_payments(
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    payments = db.query(models.Payment).filter(
        models.Payment.user_id == current_user.id
    ).all()
    return payments