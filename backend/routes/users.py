from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy import func, distinct
from database import get_db
import models
import schemas
from auth.auth import get_current_user

router = APIRouter()

@router.get("/me", response_model=schemas.UserResponse)
def get_current_user_profile(current_user: models.User = Depends(get_current_user)):
    return current_user

@router.put("/me", response_model=schemas.UserResponse)
def update_current_user(
    user_update: dict,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    for field, value in user_update.items():
        if hasattr(current_user, field) and field != "id":
            setattr(current_user, field, value)
    
    db.commit()
    db.refresh(current_user)
    return current_user

@router.get("/{user_id}", response_model=schemas.UserResponse)
def get_user(user_id: str, db: Session = Depends(get_db)):
    user = db.query(models.User).filter(models.User.id == user_id).first()
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    return user

@router.get("/me/statistics", response_model=schemas.UserStatisticsResponse)
def get_user_statistics(
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    # Count total bookings
    total_bookings = db.query(models.Booking).filter(
        models.Booking.user_id == current_user.id,
        models.Booking.status != models.BookingStatus.CANCELLED
    ).count()
    
    # Count countries visited (distinct countries from completed bookings)
    countries_query = db.query(distinct(models.Hotel.country)).join(
        models.Booking, models.Hotel.id == models.Booking.hotel_id
    ).filter(
        models.Booking.user_id == current_user.id,
        models.Booking.status == models.BookingStatus.CHECKED_OUT
    ).all()
    
    countries_list = [country[0] for country in countries_query if country[0]]
    countries_visited = len(countries_list)
    
    # Count total reviews
    total_reviews = db.query(models.Review).filter(
        models.Review.user_id == current_user.id
    ).count()
    
    return schemas.UserStatisticsResponse(
        total_bookings=total_bookings,
        countries_visited=countries_visited,
        total_reviews=total_reviews,
        countries_list=countries_list
    )

@router.delete("/me")
def delete_current_user(
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    current_user.is_active = False
    db.commit()
    return {"message": "User deactivated successfully"}