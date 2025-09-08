from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session, joinedload
from sqlalchemy import and_, func, desc, asc
from typing import List, Optional
from database import get_db
import models
import schemas
from auth.auth import get_current_user, get_current_owner

router = APIRouter()

@router.get("/hotel/{hotel_id}")
def get_hotel_reviews(
    hotel_id: str,
    page: int = Query(1, ge=1, description="Page number"),
    limit: int = Query(5, ge=1, le=50, description="Number of reviews per page"),
    sort_by: str = Query("newest", description="Sort by: newest, oldest, rating_high, rating_low"),
    rating_filter: Optional[int] = Query(None, ge=1, le=5, description="Filter by rating"),
    db: Session = Depends(get_db)
):
    """Get hotel reviews with pagination and filters"""
    
    # Verify hotel exists
    hotel = db.query(models.Hotel).filter(models.Hotel.id == hotel_id).first()
    if not hotel:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Hotel not found"
        )
    
    # Base query with eager loading
    query = db.query(models.Review).options(
        joinedload(models.Review.user),
        joinedload(models.Review.booking)
    ).filter(models.Review.hotel_id == hotel_id)
    
    # Apply rating filter
    if rating_filter is not None:
        query = query.filter(models.Review.rating == rating_filter)
    
    # Apply sorting
    if sort_by == "newest":
        query = query.order_by(desc(models.Review.created_at))
    elif sort_by == "oldest":
        query = query.order_by(asc(models.Review.created_at))
    elif sort_by == "rating_high":
        query = query.order_by(desc(models.Review.rating), desc(models.Review.created_at))
    elif sort_by == "rating_low":
        query = query.order_by(asc(models.Review.rating), desc(models.Review.created_at))
    else:
        query = query.order_by(desc(models.Review.created_at))
    
    # Get total count for pagination
    total_reviews = query.count()
    
    # Apply pagination
    offset = (page - 1) * limit
    reviews = query.offset(offset).limit(limit).all()
    
    # Get rating summary
    rating_summary = db.query(
        models.Review.rating,
        func.count(models.Review.id).label('count')
    ).filter(models.Review.hotel_id == hotel_id).group_by(models.Review.rating).all()
    
    rating_distribution = {i: 0 for i in range(1, 6)}
    for rating, count in rating_summary:
        rating_distribution[rating] = count
    
    average_rating = db.query(func.avg(models.Review.rating)).filter(
        models.Review.hotel_id == hotel_id
    ).scalar() or 0.0
    
    # Format reviews response
    formatted_reviews = []
    for review in reviews:
        formatted_reviews.append({
            "id": review.id,
            "rating": review.rating,
            "comment": review.comment,
            "owner_reply": review.owner_reply,
            "created_at": review.created_at.isoformat(),
            "user": {
                "id": review.user.id,
                "full_name": review.user.full_name,
                "profile_image": review.user.profile_image
            },
            "booking_id": review.booking_id
        })
    
    return {
        "reviews": formatted_reviews,
        "pagination": {
            "current_page": page,
            "total_pages": (total_reviews + limit - 1) // limit,
            "total_reviews": total_reviews,
            "limit": limit,
            "has_next": page * limit < total_reviews,
            "has_prev": page > 1
        },
        "summary": {
            "average_rating": round(float(average_rating), 1),
            "total_reviews": total_reviews,
            "rating_distribution": rating_distribution
        }
    }

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
    review_id: str,
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
    review_id: str,
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
    review_id: str,
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

@router.get("/user/my-reviews")
def get_user_reviews(
    page: int = Query(1, ge=1, description="Page number"),
    limit: int = Query(5, ge=1, le=50, description="Number of reviews per page"),
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get user's reviews with pagination"""
    
    # Base query
    query = db.query(models.Review).options(
        joinedload(models.Review.booking).joinedload(models.Booking.hotel)
    ).filter(models.Review.user_id == current_user.id)
    
    query = query.order_by(desc(models.Review.created_at))
    
    # Get total count
    total_reviews = query.count()
    
    # Apply pagination
    offset = (page - 1) * limit
    reviews = query.offset(offset).limit(limit).all()
    
    # Format response
    formatted_reviews = []
    for review in reviews:
        formatted_reviews.append({
            "id": review.id,
            "rating": review.rating,
            "comment": review.comment,
            "owner_reply": review.owner_reply,
            "created_at": review.created_at.isoformat(),
            "hotel": {
                "id": review.booking.hotel.id,
                "name": review.booking.hotel.name,
                "location": review.booking.hotel.location,
                "image_url": review.booking.hotel.images[0] if review.booking.hotel.images else None
            },
            "booking_id": review.booking_id
        })
    
    return {
        "reviews": formatted_reviews,
        "pagination": {
            "current_page": page,
            "total_pages": (total_reviews + limit - 1) // limit,
            "total_reviews": total_reviews,
            "limit": limit,
            "has_next": page * limit < total_reviews,
            "has_prev": page > 1
        }
    }

@router.get("/owner/my-hotels-reviews")
def get_owner_reviews(
    page: int = Query(1, ge=1, description="Page number"),
    limit: int = Query(10, ge=1, le=50, description="Number of reviews per page"),
    hotel_id: Optional[int] = Query(None, description="Filter by specific hotel"),
    rating_filter: Optional[int] = Query(None, ge=1, le=5, description="Filter by rating"),
    needs_reply: bool = Query(False, description="Show only reviews that need replies"),
    sort_by: str = Query("newest", description="Sort by: newest, oldest, rating_high, rating_low"),
    current_user: models.User = Depends(get_current_owner),
    db: Session = Depends(get_db)
):
    """Get all reviews for owner's hotels with pagination and filters"""
    
    # Base query for owner's hotel reviews
    query = db.query(models.Review).join(models.Hotel).options(
        joinedload(models.Review.user),
        joinedload(models.Review.booking),
        joinedload(models.Review.hotel)
    ).filter(models.Hotel.owner_id == current_user.id)
    
    # Apply filters
    if hotel_id is not None:
        query = query.filter(models.Review.hotel_id == hotel_id)
        
    if rating_filter is not None:
        query = query.filter(models.Review.rating == rating_filter)
        
    if needs_reply:
        query = query.filter(models.Review.owner_reply.is_(None))
    
    # Apply sorting
    if sort_by == "newest":
        query = query.order_by(desc(models.Review.created_at))
    elif sort_by == "oldest":
        query = query.order_by(asc(models.Review.created_at))
    elif sort_by == "rating_high":
        query = query.order_by(desc(models.Review.rating), desc(models.Review.created_at))
    elif sort_by == "rating_low":
        query = query.order_by(asc(models.Review.rating), desc(models.Review.created_at))
    else:
        query = query.order_by(desc(models.Review.created_at))
    
    # Get total count
    total_reviews = query.count()
    
    # Apply pagination
    offset = (page - 1) * limit
    reviews = query.offset(offset).limit(limit).all()
    
    # Get owner hotels for filter dropdown
    owner_hotels = db.query(models.Hotel).filter(
        models.Hotel.owner_id == current_user.id
    ).all()
    
    # Get summary stats
    total_unreplied = db.query(models.Review).join(models.Hotel).filter(
        models.Hotel.owner_id == current_user.id,
        models.Review.owner_reply.is_(None)
    ).count()
    
    # Format response
    formatted_reviews = []
    for review in reviews:
        formatted_reviews.append({
            "id": review.id,
            "rating": review.rating,
            "comment": review.comment,
            "owner_reply": review.owner_reply,
            "created_at": review.created_at.isoformat(),
            "hotel": {
                "id": review.hotel.id,
                "name": review.hotel.name,
                "location": review.hotel.location
            },
            "user": {
                "id": review.user.id,
                "full_name": review.user.full_name,
                "profile_image": review.user.profile_image
            },
            "booking_id": review.booking_id,
            "needs_reply": review.owner_reply is None
        })
    
    return {
        "reviews": formatted_reviews,
        "pagination": {
            "current_page": page,
            "total_pages": (total_reviews + limit - 1) // limit,
            "total_reviews": total_reviews,
            "limit": limit,
            "has_next": page * limit < total_reviews,
            "has_prev": page > 1
        },
        "summary": {
            "total_reviews": total_reviews,
            "total_unreplied": total_unreplied
        },
        "hotels": [
            {"id": hotel.id, "name": hotel.name} 
            for hotel in owner_hotels
        ]
    }