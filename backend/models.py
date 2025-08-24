from sqlalchemy import Column, Integer, String, Float, Boolean, DateTime, Text, ForeignKey, JSON, Enum as SQLEnum, Numeric, Date
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from database import Base
from enum import Enum
import uuid

class UserRole(str, Enum):
    USER = "user"
    OWNER = "owner"
    ADMIN = "admin"

class BookingStatus(str, Enum):
    PENDING = "pending"
    CONFIRMED = "confirmed"
    CHECKED_IN = "checked_in"
    CHECKED_OUT = "checked_out"
    CANCELLED = "cancelled"
    NO_SHOW = "no_show"

class PaymentStatus(str, Enum):
    PENDING = "pending"
    PAID = "paid"
    FAILED = "failed"
    REFUNDED = "refunded"
    PARTIALLY_REFUNDED = "partially_refunded"

class RoomTypeEnum(str, Enum):
    SINGLE = "single"
    DOUBLE = "double"
    TWIN = "twin"
    TRIPLE = "triple"
    QUAD = "quad"
    SUITE = "suite"
    DELUXE = "deluxe"
    PREMIUM = "premium"

class User(Base):
    __tablename__ = "users"
    
    id = Column(Integer, primary_key=True, index=True)
    email = Column(String, unique=True, index=True)
    username = Column(String, unique=True, index=True)
    hashed_password = Column(String)
    
    # Personal Information
    first_name = Column(String)
    last_name = Column(String)
    full_name = Column(String)  # Keep for backward compatibility
    date_of_birth = Column(Date)
    nationality = Column(String)
    
    # Contact Information
    phone = Column(String)
    phone_country_code = Column(String, default="+1")
    emergency_contact_name = Column(String)
    emergency_contact_phone = Column(String)
    
    # Address Information
    address_line1 = Column(String)
    address_line2 = Column(String)
    city = Column(String)
    state_province = Column(String)
    postal_code = Column(String)
    country = Column(String)
    
    # Preferences
    language = Column(String, default="en")
    currency = Column(String, default="USD")
    time_zone = Column(String)
    dietary_restrictions = Column(JSON)
    accessibility_needs = Column(JSON)
    
    # Account Information
    role = Column(String, default=UserRole.USER)
    is_active = Column(Boolean, default=True)
    is_verified = Column(Boolean, default=False)
    profile_image = Column(String)
    loyalty_points = Column(Integer, default=0)
    
    # Timestamps
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    last_login = Column(DateTime(timezone=True))
    
    # Relationships
    bookings = relationship("Booking", back_populates="user")
    reviews = relationship("Review", back_populates="user")
    payment_methods = relationship("PaymentMethod", back_populates="user")
    hotels = relationship("Hotel", back_populates="owner")
    chat_messages = relationship("ChatMessage", back_populates="user")

class Hotel(Base):
    __tablename__ = "hotels"
    
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, index=True)
    description = Column(Text)
    short_description = Column(String(500))
    
    # Location Information
    address_line1 = Column(String)
    address_line2 = Column(String)
    address = Column(String)  # Keep for backward compatibility
    city = Column(String, index=True)
    state_province = Column(String)
    postal_code = Column(String)
    country = Column(String, index=True)
    latitude = Column(Float)  # Keep as Float for compatibility
    longitude = Column(Float)  # Keep as Float for compatibility
    
    # Property Details
    star_rating = Column(Integer)  # 1-5 stars
    property_type = Column(String, default="Hotel")  # Hotel, Resort, Apartment, etc.
    total_rooms = Column(Integer)
    available_rooms = Column(Integer)  # Keep for backward compatibility
    total_floors = Column(Integer)
    year_built = Column(Integer)
    year_renovated = Column(Integer)
    
    # Pricing
    price_per_night = Column(Float)  # Keep for backward compatibility
    base_price_per_night = Column(Numeric(10, 2))
    currency = Column(String, default="USD")
    tax_rate = Column(Numeric(5, 4))  # e.g., 0.1250 for 12.5%
    service_fee_rate = Column(Numeric(5, 4))
    
    # Ratings and Reviews
    rating = Column(Float, default=0.0)  # Keep for backward compatibility
    average_rating = Column(Numeric(3, 2), default=0.0)
    total_reviews = Column(Integer, default=0)
    
    # Features and Amenities
    amenities = Column(JSON)  # List of amenity IDs
    policies = Column(JSON)  # Check-in/out times, cancellation policies, etc.
    languages_spoken = Column(JSON)  # Languages spoken by staff
    
    # Media
    images = Column(JSON)  # List of image URLs with metadata
    virtual_tour_url = Column(String)
    
    # Business Information
    owner_id = Column(Integer, ForeignKey("users.id"))
    business_registration = Column(String)
    tax_id = Column(String)
    
    # Contact Information
    phone = Column(String)
    website = Column(String)
    email = Column(String)
    
    # Status
    is_active = Column(Boolean, default=True)
    is_verified = Column(Boolean, default=False)
    
    # Timestamps
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    
    # Relationships
    owner = relationship("User", back_populates="hotels")
    room_types = relationship("RoomType", back_populates="hotel")
    bookings = relationship("Booking", back_populates="hotel")
    reviews = relationship("Review", back_populates="hotel")
    chat_messages = relationship("ChatMessage", back_populates="hotel")

class RoomType(Base):
    __tablename__ = "room_types"
    
    id = Column(Integer, primary_key=True, index=True)
    hotel_id = Column(Integer, ForeignKey("hotels.id"))
    
    # Room Details
    name = Column(String, nullable=False)  # "Deluxe King Room"
    type = Column(String, nullable=False)  # SINGLE, DOUBLE, etc.
    description = Column(Text)
    
    # Capacity
    max_guests = Column(Integer, nullable=False)
    max_adults = Column(Integer, nullable=False)
    max_children = Column(Integer, default=0)
    
    # Room Features
    size_sqm = Column(Integer)  # Room size in square meters
    bed_type = Column(String)  # King, Queen, Twin, etc.
    bed_count = Column(Integer, default=1)
    
    # Pricing
    base_price = Column(Numeric(10, 2), nullable=False)
    weekend_price = Column(Numeric(10, 2))
    holiday_price = Column(Numeric(10, 2))
    
    # Inventory
    total_rooms = Column(Integer)
    
    # Features
    amenities = Column(JSON)  # Room-specific amenities
    images = Column(JSON)
    
    # Status
    is_active = Column(Boolean, default=True)
    
    # Timestamps
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    
    # Relationships
    hotel = relationship("Hotel", back_populates="room_types")
    bookings = relationship("Booking", back_populates="room_type")

class Booking(Base):
    __tablename__ = "bookings"
    
    id = Column(Integer, primary_key=True, index=True)
    
    # Booking Identification
    booking_reference = Column(String, unique=True, index=True)  # e.g., "BK123456789"
    confirmation_code = Column(String, unique=True, index=True)  # e.g., "ABC123"
    qr_code = Column(String, unique=True, index=True)  # QR code data for check-in
    
    # Primary Relations
    user_id = Column(Integer, ForeignKey("users.id"))
    hotel_id = Column(Integer, ForeignKey("hotels.id"))
    room_type_id = Column(Integer, ForeignKey("room_types.id"))
    
    # Stay Details
    check_in_date = Column(DateTime)  # Keep as DateTime for compatibility
    check_out_date = Column(DateTime)  # Keep as DateTime for compatibility
    nights = Column(Integer)  # Computed field
    
    # Guest Information
    guests = Column(Integer)  # Keep for backward compatibility
    total_guests = Column(Integer)
    adults = Column(Integer, default=1)
    children = Column(Integer, default=0)
    infants = Column(Integer, default=0)
    
    # Primary Guest Details (from booking user)
    primary_guest_first_name = Column(String)
    primary_guest_last_name = Column(String)
    primary_guest_email = Column(String)
    primary_guest_phone = Column(String)
    
    # Pricing Breakdown
    total_price = Column(Float)  # Keep for backward compatibility
    room_rate = Column(Numeric(10, 2))  # Per night rate
    subtotal = Column(Numeric(10, 2))  # Room rate * nights
    taxes = Column(Numeric(10, 2), default=0)
    service_fees = Column(Numeric(10, 2), default=0)
    discount_amount = Column(Numeric(10, 2), default=0)
    total_amount = Column(Numeric(10, 2))
    currency = Column(String, default="USD")
    
    # Special Requests and Preferences
    special_requests = Column(Text)
    arrival_time = Column(String)  # Expected arrival time
    dietary_restrictions = Column(JSON)
    accessibility_needs = Column(JSON)
    
    # Status and Tracking
    status = Column(String, default=BookingStatus.PENDING)
    booking_source = Column(String, default="web")  # "web", "mobile", "phone", etc.
    
    # Check-in/out Details
    actual_check_in = Column(DateTime(timezone=True))
    actual_check_out = Column(DateTime(timezone=True))
    early_checkin_requested = Column(Boolean, default=False)
    late_checkout_requested = Column(Boolean, default=False)
    
    # Cancellation
    cancellation_reason = Column(String)
    cancelled_at = Column(DateTime(timezone=True))
    refund_amount = Column(Numeric(10, 2))
    
    # Payment
    payment_id = Column(Integer, ForeignKey("payments.id"))  # Keep for backward compatibility
    payment_status = Column(String, default=PaymentStatus.PENDING)
    paid_amount = Column(Numeric(10, 2), default=0)
    
    # Timestamps
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    
    # Relationships
    user = relationship("User", back_populates="bookings")
    hotel = relationship("Hotel", back_populates="bookings")
    room_type = relationship("RoomType", back_populates="bookings")
    guest_details = relationship("BookingGuest", back_populates="booking")  # Renamed from 'guests' to avoid conflict
    payments = relationship("Payment", back_populates="booking", foreign_keys="[Payment.booking_id]")
    payment = relationship("Payment", foreign_keys=[payment_id], post_update=True, overlaps="payments")  # Keep for backward compatibility
    review = relationship("Review", back_populates="booking", uselist=False)

class BookingGuest(Base):
    __tablename__ = "booking_guests"
    
    id = Column(Integer, primary_key=True, index=True)
    booking_id = Column(Integer, ForeignKey("bookings.id"))
    
    # Guest Information
    first_name = Column(String, nullable=False)
    last_name = Column(String, nullable=False)
    date_of_birth = Column(Date)
    nationality = Column(String)
    passport_number = Column(String)
    id_document_type = Column(String)  # passport, national_id, driver_license
    id_document_number = Column(String)
    
    # Guest Type
    is_primary = Column(Boolean, default=False)
    guest_type = Column(String)  # adult, child, infant
    
    # Additional Information
    dietary_restrictions = Column(JSON)
    accessibility_needs = Column(JSON)
    
    # Timestamps
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    # Relationships
    booking = relationship("Booking", back_populates="guest_details")

class Payment(Base):
    __tablename__ = "payments"
    
    id = Column(Integer, primary_key=True, index=True)
    
    # Payment Identification
    payment_reference = Column(String, unique=True, index=True)
    transaction_id = Column(String, unique=True)  # External payment provider ID
    
    # Relations
    user_id = Column(Integer, ForeignKey("users.id"))
    booking_id = Column(Integer, ForeignKey("bookings.id"))
    payment_method_id = Column(Integer, ForeignKey("payment_methods.id"))
    
    # Payment Details
    amount = Column(Float)  # Keep for backward compatibility
    currency = Column(String, default="USD")
    exchange_rate = Column(Numeric(10, 6))  # If currency conversion applied
    
    # Payment Type
    payment_type = Column(String, default="full_payment")  # "full_payment", "deposit", "refund"
    
    # Status and Processing
    status = Column(String, default=PaymentStatus.PENDING)
    payment_method_type = Column(String)  # "card", "bank_transfer", "paypal", etc.
    payment_provider = Column(String)  # "stripe", "paypal", "square", etc.
    
    # Additional Information
    description = Column(String)
    failure_reason = Column(String)
    processed_at = Column(DateTime(timezone=True))
    
    # Refund Information
    refund_amount = Column(Numeric(10, 2))
    refunded_at = Column(DateTime(timezone=True))
    refund_reason = Column(String)
    
    # Timestamps
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    
    # Relationships
    user = relationship("User")
    booking = relationship("Booking", back_populates="payments", foreign_keys=[booking_id])
    payment_method = relationship("PaymentMethod", back_populates="payments")

class PaymentMethod(Base):
    __tablename__ = "payment_methods"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    
    # Payment Method Details
    type = Column(String, nullable=False)  # "card", "bank_account", "digital_wallet"
    provider = Column(String, nullable=False)  # "visa", "mastercard", "paypal", etc.
    account_info = Column(JSON)  # Keep for backward compatibility
    
    # Card Information (encrypted/tokenized)
    last_four_digits = Column(String)
    expiry_month = Column(Integer)
    expiry_year = Column(Integer)
    cardholder_name = Column(String)
    
    # External References
    provider_token = Column(String)  # Token from payment provider
    provider_customer_id = Column(String)
    
    # Settings
    is_default = Column(Boolean, default=False)
    is_active = Column(Boolean, default=True)
    
    # Billing Address
    billing_address_line1 = Column(String)
    billing_address_line2 = Column(String)
    billing_city = Column(String)
    billing_state = Column(String)
    billing_postal_code = Column(String)
    billing_country = Column(String)
    
    # Timestamps
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    
    # Relationships
    user = relationship("User", back_populates="payment_methods")
    payments = relationship("Payment", back_populates="payment_method")

class Review(Base):
    __tablename__ = "reviews"
    
    id = Column(Integer, primary_key=True, index=True)
    
    # Relations
    user_id = Column(Integer, ForeignKey("users.id"))
    hotel_id = Column(Integer, ForeignKey("hotels.id"))
    booking_id = Column(Integer, ForeignKey("bookings.id"))
    
    # Review Details
    rating = Column(Integer)  # Keep for backward compatibility
    overall_rating = Column(Integer)  # 1-5 stars
    
    # Detailed Ratings
    cleanliness_rating = Column(Integer)
    service_rating = Column(Integer)
    location_rating = Column(Integer)
    value_rating = Column(Integer)
    facilities_rating = Column(Integer)
    
    # Review Content
    title = Column(String)
    comment = Column(Text)
    pros = Column(JSON)  # List of positive aspects
    cons = Column(JSON)  # List of negative aspects
    
    # Guest Information
    reviewer_name = Column(String)  # May be different from user name for privacy
    stay_type = Column(String)  # "business", "leisure", "family", etc.
    room_type_stayed = Column(String)
    
    # Owner Response
    owner_reply = Column(Text)
    owner_reply_date = Column(DateTime(timezone=True))
    
    # Verification
    is_verified_stay = Column(Boolean, default=True)
    
    # Moderation
    is_published = Column(Boolean, default=True)
    is_flagged = Column(Boolean, default=False)
    moderation_notes = Column(Text)
    
    # Timestamps
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    
    # Relationships
    user = relationship("User", back_populates="reviews")
    hotel = relationship("Hotel", back_populates="reviews")
    booking = relationship("Booking", back_populates="review")

class ChatMessage(Base):
    __tablename__ = "chat_messages"
    
    id = Column(Integer, primary_key=True, index=True)
    
    # Relations
    user_id = Column(Integer, ForeignKey("users.id"))
    hotel_id = Column(Integer, ForeignKey("hotels.id"))
    booking_id = Column(Integer, ForeignKey("bookings.id"))  # Optional: link to specific booking
    
    # Message Details
    message = Column(Text, nullable=False)
    message_type = Column(String, default="text")  # "text", "image", "file", "system"
    
    # Message Source
    is_from_user = Column(Boolean, default=True)
    is_from_owner = Column(Boolean, default=False)
    is_from_system = Column(Boolean, default=False)
    is_ai_response = Column(Boolean, default=False)
    
    # Message Status
    is_read = Column(Boolean, default=False)
    read_at = Column(DateTime(timezone=True))
    
    # File Attachments (if any)
    attachment_url = Column(String)
    attachment_type = Column(String)  # "image", "pdf", "document"
    attachment_name = Column(String)
    
    # System Message Details
    system_message_type = Column(String)  # "booking_confirmed", "check_in_reminder", etc.
    
    # Timestamps
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    
    # Relationships
    user = relationship("User", back_populates="chat_messages")
    hotel = relationship("Hotel", back_populates="chat_messages")

# Amenities table for better organization
class Amenity(Base):
    __tablename__ = "amenities"
    
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, nullable=False, unique=True)
    category = Column(String, nullable=False)  # "general", "room", "bathroom", "business", etc.
    icon = Column(String)
    description = Column(String)
    is_active = Column(Boolean, default=True)
    
    created_at = Column(DateTime(timezone=True), server_default=func.now())

# Table for tracking booking status changes
class BookingStatusHistory(Base):
    __tablename__ = "booking_status_history"
    
    id = Column(Integer, primary_key=True, index=True)
    booking_id = Column(Integer, ForeignKey("bookings.id"))
    
    from_status = Column(String)
    to_status = Column(String, nullable=False)
    changed_by = Column(Integer, ForeignKey("users.id"))
    reason = Column(String)
    notes = Column(Text)
    
    created_at = Column(DateTime(timezone=True), server_default=func.now())