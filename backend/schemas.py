from pydantic import BaseModel, EmailStr
from typing import Optional, List
from datetime import datetime
from models import UserRole, BookingStatus

class UserBase(BaseModel):
    email: EmailStr
    username: str
    full_name: Optional[str] = None
    phone: Optional[str] = None

class UserCreate(UserBase):
    password: str

class OwnerCreate(UserBase):
    password: str
    role: UserRole = UserRole.OWNER

class UserResponse(UserBase):
    id: int
    role: str
    is_active: bool
    profile_image: Optional[str] = None
    created_at: datetime
   
    class Config:
        from_attributes = True

class UserLogin(BaseModel):
    email: EmailStr
    password: str

class GoogleLogin(BaseModel):
    id_token: str

class Token(BaseModel):
    access_token: str
    token_type: str
    user: UserResponse

class HotelBase(BaseModel):
    name: str
    description: Optional[str] = None
    address: str
    city: str
    country: str
    price_per_night: float
    amenities: Optional[List[str]] = []
    total_rooms: int
    latitude: Optional[float] = None
    longitude: Optional[float] = None

class HotelCreate(HotelBase):
    images: Optional[List[str]] = []

class HotelUpdate(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None
    address: Optional[str] = None
    city: Optional[str] = None
    country: Optional[str] = None
    price_per_night: Optional[float] = None
    amenities: Optional[List[str]] = None
    total_rooms: Optional[int] = None
    images: Optional[List[str]] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None

class HotelResponse(HotelBase):
    id: int
    rating: float
    images: List[str]
    available_rooms: int
    owner_id: int
    owner_name: Optional[str] = None
    created_at: datetime
    
    @property
    def has_images(self) -> bool:
        return bool(self.images)
    
    @property
    def main_image(self) -> str:
        return self.images[0] if self.images else ""
   
    class Config:
        from_attributes = True

class BookingBase(BaseModel):
    hotel_id: int
    check_in_date: datetime
    check_out_date: datetime
    guests: int

class BookingCreate(BookingBase):
    pass

class BookingUpdate(BaseModel):
    check_in_date: Optional[datetime] = None
    check_out_date: Optional[datetime] = None
    guests: Optional[int] = None
    status: Optional[BookingStatus] = None

class ReviewBase(BaseModel):
    rating: int
    comment: Optional[str] = None

class ReviewCreate(ReviewBase):
    booking_id: int

class ReviewUpdate(BaseModel):
    owner_reply: str

class ReviewResponse(ReviewBase):
    id: int
    user_id: int
    hotel_id: int
    booking_id: int
    owner_reply: Optional[str] = None
    created_at: datetime
    user: UserResponse
   
    class Config:
        from_attributes = True

class BookingResponse(BaseModel):
    id: int
    hotel_id: Optional[int] = None
    check_in_date: datetime
    check_out_date: datetime
    guests: int
    user_id: int
    total_price: float
    status: str
    qr_code: Optional[str] = None
    has_review: bool = False
    created_at: datetime
    hotel: Optional[HotelResponse] = None
    review: Optional[ReviewResponse] = None
   
    class Config:
        from_attributes = True

class PaymentMethodBase(BaseModel):
    type: str
    provider: str
    account_info: dict

class PaymentMethodCreate(PaymentMethodBase):
    is_default: Optional[bool] = False

class PaymentMethodResponse(PaymentMethodBase):
    id: int
    user_id: int
    is_default: bool
    created_at: datetime
   
    class Config:
        from_attributes = True

class PaymentCreate(BaseModel):
    booking_id: int
    payment_method_id: int
    amount: float

class PaymentResponse(BaseModel):
    id: int
    amount: float
    currency: str
    status: str
    transaction_id: Optional[str] = None
    created_at: datetime
   
    class Config:
        from_attributes = True


class ChatMessageBase(BaseModel):
    message: str

class ChatMessageCreate(BaseModel):
    message: str

class ChatMessageResponse(BaseModel):
    id: int
    user_id: int
    hotel_id: int
    message: str
    is_from_user: bool
    is_from_owner: bool
    is_ai_response: bool
    is_read: bool
    created_at: datetime
   
    class Config:
        from_attributes = True

class ChatConversationResponse(BaseModel):
    hotel_id: int
    user_id: int
    hotel: HotelResponse
    guest_name: str
    last_message: ChatMessageResponse
    unread_count: int
    has_unread_messages: bool
    
    class Config:
        from_attributes = True