# BookIt Backend API

A comprehensive hotel booking platform backend built with FastAPI, featuring real-time chat, AI assistance, payment processing, and advanced analytics.

## Features

### Core Functionality
- **User Management**: Registration, authentication, profiles with role-based access (User/Owner/Admin)
- **Hotel Management**: Complete hotel listing with room types, amenities, pricing, and media
- **Booking System**: Full booking lifecycle with QR code check-in and status tracking
- **Payment Processing**: Stripe integration with multiple payment methods and refund support
- **Review System**: Detailed reviews with owner responses and rating analytics
- **Real-time Chat**: WebSocket-based messaging between guests and hotel owners

### Advanced Features
- **AI Assistant**: GPT-4o-mini powered chatbot for hotel recommendations and assistance
- **Analytics Dashboard**: Revenue trends, booking analytics, and business metrics
- **Google OAuth**: Social login integration
- **QR Code System**: Contactless check-in with QR codes
- **Email Service**: Automated emails with HTML templates
- **Advanced Search**: Location-based, text search, and filtering capabilities
- **Favorites System**: User wishlist functionality

## Tech Stack

- **Framework**: FastAPI 0.110.0+
- **Database**: SQLite with SQLAlchemy ORM
- **Authentication**: JWT tokens with bcrypt password hashing
- **Payment**: Stripe integration with webhooks
- **AI**: OpenAI GPT-4o-mini integration
- **Real-time**: WebSocket for chat functionality
- **Email**: SMTP with Jinja2 templates
- **File Storage**: Image upload with validation

## API Endpoints

### Authentication (`/api/auth`)
- `POST /register` - User registration
- `POST /login` - User authentication
- `POST /owner/register` - Hotel owner registration
- `POST /google` - Google OAuth login
- `POST /forgot-password` - Password reset request
- `POST /reset-password` - Complete password reset

### Hotels (`/api/hotels`)
- `GET /` - List hotels with filtering and sorting
- `GET /{hotel_id}` - Get hotel details
- `GET /search` - Text-based hotel search
- `GET /nearby` - Location-based proximity search
- `GET /deals` - Special deals and discounts
- `POST /` - Create hotel (owners only)
- `PUT /{hotel_id}` - Update hotel (owners only)
- `DELETE /{hotel_id}` - Delete hotel (owners only)
- `GET /owner/my-hotels` - Owner hotel management
- `POST /upload-image` - Single image upload
- `POST /upload-images` - Multiple image upload

### Bookings (`/api/bookings`)
- `GET /` - User booking history
- `GET /{booking_id}` - Booking details
- `POST /` - Create booking
- `POST /book-with-payment` - One-step booking with payment
- `PUT /{booking_id}/confirm` - Confirm booking
- `PUT /{booking_id}/check-in` - Check-in guest
- `PUT /{booking_id}/check-out` - Check-out guest
- `PUT /{booking_id}/self-checkin` - Guest self check-in
- `PUT /qr-checkin/{qr_code}` - QR code check-in
- `GET /owner/hotel-bookings` - Owner booking management

### Payments (`/api/payments`)
- `GET /config` - Stripe configuration
- `GET /methods` - User payment methods
- `POST /setup-intent` - Setup for saving cards
- `POST /methods` - Add payment method
- `POST /create-booking-payment-link` - Stripe hosted checkout
- `POST /process-stripe` - Direct payment processing
- `POST /confirm-payment-link-success/{booking_id}` - Payment confirmation

### Reviews (`/api/reviews`)
- `GET /hotel/{hotel_id}` - Hotel reviews with pagination
- `POST /` - Create review (post-checkout)
- `PUT /{review_id}` - Update review
- `PUT /{review_id}/reply` - Owner reply to review
- `GET /user/my-reviews` - User review history
- `GET /owner/my-hotels-reviews` - Owner review management

### Chat (`/api/chat`)
- `WebSocket /ws/user/{hotel_id}` - Guest chat connection
- `WebSocket /ws/owner/{hotel_id}/{user_id}` - Owner chat connection
- `GET /hotel/{hotel_id}` - Chat message history
- `POST /hotel/{hotel_id}` - Send message
- `GET /owner/conversations` - Owner conversations
- `GET /owner/chats/{hotel_id}/{user_id}` - Specific chat messages

### AI Assistant (`/api/ai`)
- `POST /chat` - Send message to AI assistant
- `GET /chat/history` - AI conversation history

### Analytics (`/api/analytics`)
- `GET /overview` - Business metrics overview
- `GET /revenue-trend` - Revenue trend analysis
- `GET /bookings-trend` - Booking trend analysis
- `GET /guest-ratings` - Rating distribution analytics
- `GET /revenue-breakdown` - Revenue categorization
- `GET /checkout-performance` - Checkout-based analytics
- `GET /guest-lifecycle` - Booking funnel analysis

### Favorites (`/api/favorites`)
- `GET /` - User favorite hotels
- `POST /add/{hotel_id}` - Add to favorites
- `DELETE /remove/{hotel_id}` - Remove from favorites
- `GET /check/{hotel_id}` - Check favorite status

### Users (`/api/users`)
- `GET /me` - Current user profile
- `PUT /me` - Update profile
- `GET /{user_id}` - User profile
- `GET /me/statistics` - User statistics
- `DELETE /me` - Deactivate account

## Database Models

### Core Models
- **User**: Comprehensive user profiles with roles, contact info, preferences, and payment integration
- **Hotel**: Detailed hotel information with location, pricing, amenities, and media
- **RoomType**: Flexible room management with dynamic pricing and specifications
- **Booking**: Complete booking lifecycle with QR codes and status tracking
- **Payment**: Multi-provider payment system with Stripe integration
- **Review**: Detailed review system with owner responses and analytics

### Supporting Models
- **ChatMessage**: Real-time messaging system
- **PaymentMethod**: Stored payment methods with tokenization
- **BookingGuest**: Additional guest information
- **UserFavoriteHotel**: Favorites system
- **AIChatHistory**: AI conversation tracking
- **BookingStatusHistory**: Status change audit trail
- **Amenity**: Centralized amenity management

## Services

### Stripe Service
- Customer and payment method management
- Payment intent creation and confirmation
- Hosted checkout with Payment Links
- Refund processing and webhook handling

### QR Service
- Booking QR code generation
- QR verification and data extraction
- Base64 encoding for mobile integration

### AI Service
- OpenAI GPT-4o-mini integration
- Context-aware hotel assistance
- Conversation history management
- Intelligent hotel recommendations

### Email Service
- SMTP integration with HTML templates
- Password reset and welcome emails
- Template-based messaging system

## Setup Instructions

### Prerequisites
- Python 3.10+
- pip package manager

### Installation

1. **Setup environment**
   ```bash
   python -m venv venv
   source venv/bin/activate  # Windows: venv\Scripts\activate
   pip install -r requirements.txt
   ```

2. **Configure environment**
   ```bash
   cp .env.example .env
   # Edit .env with your configuration
   ```

3. **Run the server**
   ```bash
   python main.py
   ```

The server will start at `http://localhost:8000`
- API Documentation: `http://localhost:8000/docs`
- Alternative docs: `http://localhost:8000/redoc`

## Environment Variables

Required configuration in `.env`:

```env
# Database
DATABASE_URL=sqlite:///./hotel_booking.db

# Security
SECRET_KEY=your-secret-key-change-in-production
JWT_SECRET_KEY=your-jwt-secret-key

# Server
DEBUG=true
HOST=0.0.0.0
PORT=8000

# Google OAuth
GOOGLE_CLIENT_ID=your-google-client-id
GOOGLE_CLIENT_SECRET=your-google-client-secret

# Stripe
STRIPE_SECRET_KEY=your-stripe-secret-key
STRIPE_PUBLISHABLE_KEY=your-stripe-publishable-key
STRIPE_WEBHOOK_SECRET=your-webhook-secret

# OpenAI
OPENAI_API_KEY=your-openai-api-key

# Email (Optional)
SMTP_SERVER=smtp.gmail.com
SMTP_PORT=587
SMTP_USERNAME=your-email@gmail.com
SMTP_PASSWORD=your-app-password
```

## Key Features

### Booking Workflow
1. **Search & Filter**: Advanced hotel search with location, price, and amenity filters
2. **Booking Creation**: Secure booking with guest information and special requests
3. **Payment Processing**: Multiple payment options with Stripe integration
4. **QR Check-in**: Contactless check-in using generated QR codes
5. **Real-time Chat**: Communication between guests and hotel owners
6. **Review System**: Post-checkout reviews with detailed ratings

### Security Features
- JWT token authentication with 24-hour expiration
- bcrypt password hashing
- Role-based access control
- Input validation and sanitization
- CORS middleware configuration
- Secure password reset flow

### Analytics Capabilities
- Revenue tracking and trend analysis
- Booking conversion funnel
- Guest rating distribution
- Occupancy rate calculations
- Performance metrics by time periods
- Business intelligence dashboard

## Mobile Integration

The API is designed for mobile applications with:
- RESTful API design with JSON responses
- Base64 QR code images for mobile scanning
- Cross-platform authentication support
- Optimized response formats
- WebSocket support for real-time features