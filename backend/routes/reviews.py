from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy import and_, func
from typing import List
from database import get_db
import models
import schemas
from auth.auth import get_current_user, get_current_owner

router = APIRouter()

@router.get("/hotel/{hotel_id}", response_model=List[schemas.ReviewResponse])
def get_hotel_reviews(hotel_id: int, db: Session = Depends(get_db)):
    reviews = db.query(models.Review).filter(
        models.Review.hotel_id == hotel_id
    ).all()
    return reviews

@router.post("/", response_model=schemas.ReviewResponse)
def create_review(
    review: schemas.ReviewCreate,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    booking = db.query(models.Booking).filter(
        and_(
            models.Booking.id == review.booking_id,
            models.Booking.user_id == current_user.id,
            models.Booking.status == models.BookingStatus.CHECKED_OUT
        )
    ).first()
    
    if not booking:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Booking not found or not eligible for review"
        )
    
    existing_review = db.query(models.Review).filter(
        models.Review.booking_id == review.booking_id
    ).first()
    
    if existing_review:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Review already exists for this booking"
        )
    
    if review.rating < 1 or review.rating > 5:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Rating must be between 1 and 5"
        )
    
    db_review = models.Review(
        user_id=current_user.id,
        hotel_id=booking.hotel_id,
        booking_id=review.booking_id,
        rating=review.rating,
        comment=review.comment
    )
    
    db.add(db_review)
    db.commit()
    
    avg_rating = db.query(func.avg(models.Review.rating)).filter(
        models.Review.hotel_id == booking.hotel_id
    ).scalar()
    
    hotel = db.query(models.Hotel).filter(models.Hotel.id == booking.hotel_id).first()
    hotel.rating = round(avg_rating, 1) if avg_rating else 0.0
    
    db.commit()
    db.refresh(db_review)
    return db_review

@router.put("/{review_id}", response_model=schemas.ReviewResponse)
def update_review(
    review_id: int,
    review_update: schemas.ReviewBase,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    review = db.query(models.Review).filter(
        and_(
            models.Review.id == review_id,
            models.Review.user_id == current_user.id
        )
    ).first()
    
    if not review:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Review not found"
        )
    
    if review_update.rating < 1 or review_update.rating > 5:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Rating must be between 1 and 5"
        )
    
    review.rating = review_update.rating
    review.comment = review_update.comment
    
    db.commit()
    
    avg_rating = db.query(func.avg(models.Review.rating)).filter(
        models.Review.hotel_id == review.hotel_id
    ).scalar()
    
    hotel = db.query(models.Hotel).filter(models.Hotel.id == review.hotel_id).first()
    hotel.rating = round(avg_rating, 1) if avg_rating else 0.0
    
    db.commit()
    db.refresh(review)
    return review

@router.put("/{review_id}/reply", response_model=schemas.ReviewResponse)
def reply_to_review(
    review_id: int,
    reply: schemas.ReviewUpdate,
    current_user: models.User = Depends(get_current_owner),
    db: Session = Depends(get_db)
):
    review = db.query(models.Review).join(models.Hotel).filter(
        and_(
            models.Review.id == review_id,
            models.Hotel.owner_id == current_user.id
        )
    ).first()
    
    if not review:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Review not found"
        )
    
    review.owner_reply = reply.owner_reply
    db.commit()
    db.refresh(review)
    return review

@router.delete("/{review_id}")
def delete_review(
    review_id: int,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    review = db.query(models.Review).filter(
        and_(
            models.Review.id == review_id,
            models.Review.user_id == current_user.id
        )
    ).first()
    
    if not review:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Review not found"
        )
    
    hotel_id = review.hotel_id
    db.delete(review)
    db.commit()
    
    avg_rating = db.query(func.avg(models.Review.rating)).filter(
        models.Review.hotel_id == hotel_id
    ).scalar()
    
    hotel = db.query(models.Hotel).filter(models.Hotel.id == hotel_id).first()
    hotel.rating = round(avg_rating, 1) if avg_rating else 0.0
    
    db.commit()
    return {"message": "Review deleted successfully"}

@router.get("/user/my-reviews", response_model=List[schemas.ReviewResponse])
def get_user_reviews(
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    reviews = db.query(models.Review).filter(
        models.Review.user_id == current_user.id
    ).all()
    return reviews