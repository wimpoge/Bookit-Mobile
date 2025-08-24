# BookIt Backend API

FastAPI-based hotel booking system backend with real-time chat, secure authentication, and Google OAuth.

## Features

- User registration/authentication with JWT and Google OAuth
- Hotel management with image uploads
- Booking system with status tracking and QR codes
- Review system with owner replies
- Real-time WebSocket chat
- Payment processing
- Role-based access control (User/Owner)

## Tech Stack

- FastAPI with SQLAlchemy ORM
- SQLite database
- JWT authentication with bcrypt
- WebSocket for real-time chat
- Google OAuth2 integration

## API Endpoints

### Authentication (`/api/auth`)
- `POST /register` - User registration
- `POST /login` - User login
- `POST /owner/register` - Hotel owner registration
- `POST /google` - Google OAuth login

### Users (`/api/users`)
- User profile management endpoints

### Hotels (`/api/hotels`)
- `GET /` - List hotels with filtering
- `POST /` - Create hotel (owner only)
- `GET /{id}` - Get hotel details
- `PUT /{id}` - Update hotel (owner only)
- `DELETE /{id}` - Delete hotel (owner only)

### Bookings (`/api/bookings`)
- `POST /` - Create booking
- `GET /user` - Get user bookings
- `GET /owner` - Get owner bookings
- `PUT /{id}/status` - Update booking status

### Payments (`/api/payments`)
- Payment method and transaction management

### Reviews (`/api/reviews`)
- Hotel review and rating system

### Chat (`/api/chat`)
- `WebSocket /ws/user/{hotel_id}` - User chat connection
- `WebSocket /ws/owner/{hotel_id}/{user_id}` - Owner chat connection
- `GET /hotel/{hotel_id}` - Get chat messages
- `GET /owner/conversations` - Get owner conversations

## Database Schema

### Core Models
- **User**: User accounts with role-based access
- **Hotel**: Hotel listings with amenities and location
- **Booking**: Reservation records with status tracking
- **Payment**: Payment transactions and methods
- **Review**: User reviews with owner replies
- **ChatMessage**: Real-time chat messages

## Setup Instructions

### Prerequisites
- Python 3.10+
- pip package manager

### Quick Start

1. **Setup environment**
   ```bash
   python -m venv venv
   source venv/bin/activate  # Windows: venv\Scripts\activate
   pip install -r requirements.txt
   ```

2. **Configure environment**
   ```bash
   cp .env.example .env
   # Edit .env with your settings
   ```

3. **Run server**
   ```bash
   python main.py
   ```

Server runs at `http://localhost:8000`
API docs: `http://localhost:8000/docs`

## Environment Variables

Required variables in `.env`:
```env
DATABASE_URL=sqlite:///./hotel_booking.db
SECRET_KEY=your-secret-key-change-in-production
GOOGLE_CLIENT_ID=your-google-client-id
DEBUG=true
HOST=0.0.0.0
PORT=8000
```