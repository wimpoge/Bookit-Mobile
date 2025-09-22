from fastapi import APIRouter, HTTPException, Depends, Query
from sqlalchemy.orm import Session
from sqlalchemy import func, and_, extract
from datetime import datetime, timedelta
from typing import Optional, List, Dict, Any
import calendar

from database import get_db
from models import User, Hotel, Booking, Review
from auth.auth import get_current_user, get_current_owner

router = APIRouter()

@router.get("/overview")
async def get_analytics_overview(
    period: str = Query("this_month", description="Period: today, this_week, this_month, last_month, this_year, etc."),
    hotel_id: Optional[int] = Query(None, description="Specific hotel ID, if not provided, returns all hotels for owner"),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_owner)
):
    """Get analytics overview for hotel owner"""
    
    # Get date range based on period
    start_date, end_date = get_date_range(period)
    
    # Base query - filter by owner and optional hotel_id
    base_query = db.query(Booking).join(Hotel).filter(Hotel.owner_id == current_user.id)
    if hotel_id:
        base_query = base_query.filter(Hotel.id == hotel_id)
    
    # Filter by date range
    bookings_query = base_query.filter(
        Booking.created_at >= start_date,
        Booking.created_at <= end_date
    )
    
    # Calculate metrics
    total_revenue = bookings_query.filter(Booking.status == "confirmed").with_entities(
        func.sum(Booking.total_price)
    ).scalar() or 0
    
    total_bookings = bookings_query.filter(Booking.status == "confirmed").count()
    
    # Get previous period for growth calculation
    prev_start, prev_end = get_previous_period_range(period)
    prev_bookings_query = base_query.filter(
        Booking.created_at >= prev_start,
        Booking.created_at <= prev_end
    )
    
    prev_revenue = prev_bookings_query.filter(Booking.status == "confirmed").with_entities(
        func.sum(Booking.total_price)
    ).scalar() or 0
    
    prev_bookings = prev_bookings_query.filter(Booking.status == "confirmed").count()
    
    # Calculate growth rates
    revenue_growth = calculate_growth(total_revenue, prev_revenue)
    bookings_growth = calculate_growth(total_bookings, prev_bookings)
    
    # Get occupancy rate (simplified calculation)
    total_rooms = db.query(Hotel).filter(Hotel.owner_id == current_user.id).with_entities(
        func.sum(Hotel.total_rooms)
    ).scalar() or 1
    
    days_in_period = (end_date - start_date).days + 1
    total_room_nights = total_rooms * days_in_period
    booked_room_nights = bookings_query.filter(Booking.status == "confirmed").with_entities(
        func.sum(func.datediff(Booking.check_out, Booking.check_in))
    ).scalar() or 0
    
    occupancy_rate = (booked_room_nights / total_room_nights * 100) if total_room_nights > 0 else 0
    
    # Get total guests
    total_guests = bookings_query.filter(Booking.status == "confirmed").with_entities(
        func.sum(Booking.guests)
    ).scalar() or 0
    
    prev_guests = prev_bookings_query.filter(Booking.status == "confirmed").with_entities(
        func.sum(Booking.guests)
    ).scalar() or 0
    
    guests_growth = calculate_growth(total_guests, prev_guests)
    
    return {
        "period": period,
        "start_date": start_date.isoformat(),
        "end_date": end_date.isoformat(),
        "metrics": {
            "revenue": {
                "total": float(total_revenue),
                "growth": revenue_growth
            },
            "bookings": {
                "total": total_bookings,
                "growth": bookings_growth
            },
            "occupancy_rate": {
                "rate": round(occupancy_rate, 2),
                "growth": 0  # Would need historical data to calculate
            },
            "guests": {
                "total": total_guests,
                "growth": guests_growth
            }
        }
    }

@router.get("/revenue-trend")
async def get_revenue_trend(
    period: str = Query("this_month"),
    hotel_id: Optional[int] = Query(None),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_owner)
):
    """Get revenue trend data for charts"""
    
    start_date, end_date = get_date_range(period)
    
    # Base query
    base_query = db.query(Booking).join(Hotel).filter(
        Hotel.owner_id == current_user.id,
        Booking.status == "confirmed",
        Booking.created_at >= start_date,
        Booking.created_at <= end_date
    )
    
    if hotel_id:
        base_query = base_query.filter(Hotel.id == hotel_id)
    
    # Group by date
    if period in ["today", "yesterday"]:
        # Hourly data
        revenue_data = base_query.with_entities(
            extract('hour', Booking.created_at).label('period'),
            func.sum(Booking.total_price).label('revenue')
        ).group_by(extract('hour', Booking.created_at)).all()
        
        # Fill missing hours
        data_dict = {int(row.period): float(row.revenue) for row in revenue_data}
        chart_data = [{"period": hour, "value": data_dict.get(hour, 0)} for hour in range(24)]
        
    elif period in ["this_week", "last_week"]:
        # Daily data for week
        revenue_data = base_query.with_entities(
            func.date(Booking.created_at).label('date'),
            func.sum(Booking.total_price).label('revenue')
        ).group_by(func.date(Booking.created_at)).all()
        
        # Fill missing days
        chart_data = []
        current_date = start_date
        data_dict = {row.date: float(row.revenue) for row in revenue_data}
        
        while current_date <= end_date:
            chart_data.append({
                "period": current_date.strftime("%a"),
                "value": data_dict.get(current_date.date(), 0)
            })
            current_date += timedelta(days=1)
            
    else:
        # Monthly data
        revenue_data = base_query.with_entities(
            extract('day', Booking.created_at).label('day'),
            func.sum(Booking.total_price).label('revenue')
        ).group_by(extract('day', Booking.created_at)).all()
        
        data_dict = {int(row.day): float(row.revenue) for row in revenue_data}
        days_in_month = calendar.monthrange(start_date.year, start_date.month)[1]
        chart_data = [{"period": day, "value": data_dict.get(day, 0)} for day in range(1, days_in_month + 1)]
    
    return {
        "period": period,
        "chart_data": chart_data
    }

@router.get("/bookings-trend")
async def get_bookings_trend(
    period: str = Query("this_month"),
    hotel_id: Optional[int] = Query(None),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_owner)
):
    """Get bookings trend data for charts"""
    
    start_date, end_date = get_date_range(period)
    
    base_query = db.query(Booking).join(Hotel).filter(
        Hotel.owner_id == current_user.id,
        Booking.status == "confirmed",
        Booking.created_at >= start_date,
        Booking.created_at <= end_date
    )
    
    if hotel_id:
        base_query = base_query.filter(Hotel.id == hotel_id)
    
    if period in ["this_week", "last_week"]:
        # Daily data
        bookings_data = base_query.with_entities(
            func.date(Booking.created_at).label('date'),
            func.count(Booking.id).label('bookings')
        ).group_by(func.date(Booking.created_at)).all()
        
        chart_data = []
        current_date = start_date
        data_dict = {row.date: int(row.bookings) for row in bookings_data}
        
        while current_date <= end_date:
            chart_data.append({
                "period": current_date.strftime("%a"),
                "value": data_dict.get(current_date.date(), 0)
            })
            current_date += timedelta(days=1)
    else:
        # Monthly data
        bookings_data = base_query.with_entities(
            extract('day', Booking.created_at).label('day'),
            func.count(Booking.id).label('bookings')
        ).group_by(extract('day', Booking.created_at)).all()
        
        data_dict = {int(row.day): int(row.bookings) for row in bookings_data}
        days_in_month = calendar.monthrange(start_date.year, start_date.month)[1]
        chart_data = [{"period": day, "value": data_dict.get(day, 0)} for day in range(1, days_in_month + 1)]
    
    return {
        "period": period,
        "chart_data": chart_data
    }

@router.get("/guest-ratings")
async def get_guest_ratings(
    period: str = Query("this_month"),
    hotel_id: Optional[int] = Query(None),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_owner)
):
    """Get guest ratings distribution"""
    
    start_date, end_date = get_date_range(period)
    
    base_query = db.query(Review).join(Booking).join(Hotel).filter(
        Hotel.owner_id == current_user.id,
        Review.created_at >= start_date,
        Review.created_at <= end_date
    )
    
    if hotel_id:
        base_query = base_query.filter(Hotel.id == hotel_id)
    
    # Get ratings distribution
    ratings_data = base_query.with_entities(
        Review.rating,
        func.count(Review.id).label('count')
    ).group_by(Review.rating).all()
    
    # Format for chart
    ratings_distribution = []
    for rating in range(1, 6):
        count = next((row.count for row in ratings_data if row.rating == rating), 0)
        ratings_distribution.append({
            "rating": rating,
            "count": count
        })
    
    total_reviews = sum(item["count"] for item in ratings_distribution)
    average_rating = base_query.with_entities(func.avg(Review.rating)).scalar() or 0
    
    return {
        "period": period,
        "average_rating": round(float(average_rating), 2),
        "total_reviews": total_reviews,
        "ratings_distribution": ratings_distribution
    }

@router.get("/revenue-breakdown")
async def get_revenue_breakdown(
    period: str = Query("this_month"),
    hotel_id: Optional[int] = Query(None),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_owner)
):
    """Get revenue breakdown by different categories"""

    start_date, end_date = get_date_range(period)

    base_query = db.query(Booking).join(Hotel).filter(
        Hotel.owner_id == current_user.id,
        Booking.status == "confirmed",
        Booking.created_at >= start_date,
        Booking.created_at <= end_date
    )

    if hotel_id:
        base_query = base_query.filter(Hotel.id == hotel_id)

    # Get total revenue
    total_revenue = base_query.with_entities(func.sum(Booking.total_price)).scalar() or 0

    # Simple breakdown (in real app, you might have more detailed pricing structure)
    room_revenue = total_revenue * 0.85  # 85% room bookings
    service_fees = total_revenue * 0.10  # 10% service fees
    extras = total_revenue * 0.04        # 4% extra services
    cancellation_fees = total_revenue * 0.01  # 1% cancellation fees

    breakdown = [
        {"category": "Room Bookings", "amount": float(room_revenue), "percentage": 0.85},
        {"category": "Service Fees", "amount": float(service_fees), "percentage": 0.10},
        {"category": "Extra Services", "amount": float(extras), "percentage": 0.04},
        {"category": "Cancellation Fees", "amount": float(cancellation_fees), "percentage": 0.01},
    ]

    return {
        "period": period,
        "total_revenue": float(total_revenue),
        "breakdown": breakdown
    }

@router.get("/checkout-performance")
async def get_checkout_performance(
    period: str = Query("this_month"),
    hotel_id: Optional[int] = Query(None),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_owner)
):
    """Get checkout-based performance analytics"""

    start_date, end_date = get_date_range(period)

    # Base query for checkout analysis
    base_query = db.query(Booking).join(Hotel).filter(
        Hotel.owner_id == current_user.id,
        Booking.status == "checked_out",
        Booking.actual_check_out >= start_date,
        Booking.actual_check_out <= end_date
    )

    if hotel_id:
        base_query = base_query.filter(Hotel.id == hotel_id)

    # Get checkout metrics
    total_checkouts = base_query.count()

    # Revenue from completed stays only
    checkout_revenue = base_query.with_entities(func.sum(Booking.total_price)).scalar() or 0

    # Average stay duration for checked out guests
    avg_stay_duration = base_query.with_entities(
        func.avg(func.julianday(Booking.actual_check_out) - func.julianday(Booking.actual_check_in))
    ).scalar() or 0

    # Guest satisfaction (only from completed stays)
    checkout_reviews = db.query(Review).join(Booking).join(Hotel).filter(
        Hotel.owner_id == current_user.id,
        Booking.status == "checked_out",
        Booking.actual_check_out >= start_date,
        Booking.actual_check_out <= end_date
    )

    if hotel_id:
        checkout_reviews = checkout_reviews.filter(Hotel.id == hotel_id)

    avg_checkout_rating = checkout_reviews.with_entities(func.avg(Review.overall_rating)).scalar() or 0
    total_checkout_reviews = checkout_reviews.count()

    # Checkout trends by day of week
    checkout_by_day = base_query.with_entities(
        func.strftime('%w', Booking.actual_check_out).label('day_of_week'),
        func.count(Booking.id).label('checkout_count')
    ).group_by(func.strftime('%w', Booking.actual_check_out)).all()

    day_names = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday']
    checkout_trends = []
    for day_num in range(7):
        count = next((row.checkout_count for row in checkout_by_day if int(row.day_of_week) == day_num), 0)
        checkout_trends.append({
            "day": day_names[day_num],
            "checkouts": count
        })

    # Early vs late checkouts
    early_checkouts = base_query.filter(
        func.time(Booking.actual_check_out) < '11:00:00'
    ).count()

    late_checkouts = base_query.filter(
        func.time(Booking.actual_check_out) > '12:00:00'
    ).count()

    return {
        "period": period,
        "checkout_metrics": {
            "total_checkouts": total_checkouts,
            "checkout_revenue": float(checkout_revenue),
            "avg_stay_duration": round(float(avg_stay_duration), 2),
            "avg_rating": round(float(avg_checkout_rating), 2),
            "total_reviews": total_checkout_reviews
        },
        "checkout_trends": checkout_trends,
        "checkout_timing": {
            "early_checkouts": early_checkouts,
            "late_checkouts": late_checkouts,
            "on_time_checkouts": max(0, total_checkouts - early_checkouts - late_checkouts)
        }
    }

@router.get("/guest-lifecycle")
async def get_guest_lifecycle(
    period: str = Query("this_month"),
    hotel_id: Optional[int] = Query(None),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_owner)
):
    """Get guest lifecycle analytics from booking to checkout"""

    start_date, end_date = get_date_range(period)

    base_query = db.query(Booking).join(Hotel).filter(
        Hotel.owner_id == current_user.id,
        Booking.created_at >= start_date,
        Booking.created_at <= end_date
    )

    if hotel_id:
        base_query = base_query.filter(Hotel.id == hotel_id)

    # Booking funnel analysis
    total_bookings = base_query.count()
    confirmed_bookings = base_query.filter(Booking.status.in_(["confirmed", "checked_in", "checked_out"])).count()
    checked_in = base_query.filter(Booking.status.in_(["checked_in", "checked_out"])).count()
    checked_out = base_query.filter(Booking.status == "checked_out").count()
    cancelled = base_query.filter(Booking.status == "cancelled").count()
    no_shows = base_query.filter(Booking.status == "no_show").count()

    # Conversion rates
    confirmation_rate = (confirmed_bookings / total_bookings * 100) if total_bookings > 0 else 0
    checkin_rate = (checked_in / confirmed_bookings * 100) if confirmed_bookings > 0 else 0
    completion_rate = (checked_out / checked_in * 100) if checked_in > 0 else 0

    # Revenue by status
    confirmed_revenue = base_query.filter(
        Booking.status.in_(["confirmed", "checked_in", "checked_out"])
    ).with_entities(func.sum(Booking.total_price)).scalar() or 0

    checkout_revenue = base_query.filter(
        Booking.status == "checked_out"
    ).with_entities(func.sum(Booking.total_price)).scalar() or 0

    return {
        "period": period,
        "booking_funnel": {
            "total_bookings": total_bookings,
            "confirmed_bookings": confirmed_bookings,
            "checked_in": checked_in,
            "checked_out": checked_out,
            "cancelled": cancelled,
            "no_shows": no_shows
        },
        "conversion_rates": {
            "confirmation_rate": round(confirmation_rate, 2),
            "checkin_rate": round(checkin_rate, 2),
            "completion_rate": round(completion_rate, 2)
        },
        "revenue_tracking": {
            "total_revenue_confirmed": float(confirmed_revenue),
            "total_revenue_completed": float(checkout_revenue),
            "revenue_completion_rate": round((checkout_revenue / confirmed_revenue * 100) if confirmed_revenue > 0 else 0, 2)
        }
    }

@router.get("/hotels")
async def get_owner_hotels(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_owner)
):
    """Get list of hotels for the owner"""
    
    hotels = db.query(Hotel).filter(Hotel.owner_id == current_user.id).all()
    
    return {
        "hotels": [
            {
                "id": hotel.id,
                "name": hotel.name,
                "location": hotel.location,
                "total_rooms": hotel.total_rooms
            }
            for hotel in hotels
        ]
    }

def get_date_range(period: str) -> tuple[datetime, datetime]:
    """Get start and end date for the given period"""
    now = datetime.now()
    
    if period == "today":
        start = now.replace(hour=0, minute=0, second=0, microsecond=0)
        end = now.replace(hour=23, minute=59, second=59, microsecond=999999)
    elif period == "yesterday":
        yesterday = now - timedelta(days=1)
        start = yesterday.replace(hour=0, minute=0, second=0, microsecond=0)
        end = yesterday.replace(hour=23, minute=59, second=59, microsecond=999999)
    elif period == "this_week":
        days_since_monday = now.weekday()
        start = (now - timedelta(days=days_since_monday)).replace(hour=0, minute=0, second=0, microsecond=0)
        end = now
    elif period == "last_week":
        days_since_monday = now.weekday()
        start = (now - timedelta(days=days_since_monday + 7)).replace(hour=0, minute=0, second=0, microsecond=0)
        end = (now - timedelta(days=days_since_monday + 1)).replace(hour=23, minute=59, second=59, microsecond=999999)
    elif period == "this_month":
        start = now.replace(day=1, hour=0, minute=0, second=0, microsecond=0)
        end = now
    elif period == "last_month":
        first_this_month = now.replace(day=1)
        end = first_this_month - timedelta(days=1)
        start = end.replace(day=1, hour=0, minute=0, second=0, microsecond=0)
        end = end.replace(hour=23, minute=59, second=59, microsecond=999999)
    elif period == "this_year":
        start = now.replace(month=1, day=1, hour=0, minute=0, second=0, microsecond=0)
        end = now
    elif period == "last_year":
        start = now.replace(year=now.year-1, month=1, day=1, hour=0, minute=0, second=0, microsecond=0)
        end = now.replace(year=now.year-1, month=12, day=31, hour=23, minute=59, second=59, microsecond=999999)
    else:
        # Default to this month
        start = now.replace(day=1, hour=0, minute=0, second=0, microsecond=0)
        end = now
    
    return start, end

def get_previous_period_range(period: str) -> tuple[datetime, datetime]:
    """Get the previous period range for growth calculation"""
    now = datetime.now()
    
    if period == "today":
        yesterday = now - timedelta(days=1)
        start = yesterday.replace(hour=0, minute=0, second=0, microsecond=0)
        end = yesterday.replace(hour=23, minute=59, second=59, microsecond=999999)
    elif period == "this_week":
        days_since_monday = now.weekday()
        start = (now - timedelta(days=days_since_monday + 7)).replace(hour=0, minute=0, second=0, microsecond=0)
        end = (now - timedelta(days=days_since_monday + 1)).replace(hour=23, minute=59, second=59, microsecond=999999)
    elif period == "this_month":
        first_this_month = now.replace(day=1)
        end = first_this_month - timedelta(days=1)
        start = end.replace(day=1, hour=0, minute=0, second=0, microsecond=0)
        end = end.replace(hour=23, minute=59, second=59, microsecond=999999)
    else:
        # Default calculation
        start = now - timedelta(days=30)
        end = now - timedelta(days=15)
    
    return start, end

def calculate_growth(current: float, previous: float) -> float:
    """Calculate growth percentage"""
    if previous == 0:
        return 100.0 if current > 0 else 0.0
    return round(((current - previous) / previous) * 100, 2)