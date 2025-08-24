from fastapi import FastAPI, Depends, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from fastapi.security import HTTPBearer
from sqlalchemy.orm import Session
from pathlib import Path
import os
from database import engine, get_db, init_database
import models
from routes import auth, users, hotels, bookings, payments, reviews, chat, analytics

models.Base.metadata.create_all(bind=engine)
init_database()

app = FastAPI(
    title="Hotel Booking API",
    version="1.0.0",
    description="A comprehensive hotel booking API with image upload support"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

UPLOAD_DIR = Path("uploads")
UPLOAD_DIR.mkdir(exist_ok=True)
(UPLOAD_DIR / "hotels").mkdir(exist_ok=True)

app.mount("/uploads", StaticFiles(directory="uploads"), name="uploads")

security = HTTPBearer()

@app.middleware("http")
async def log_requests(request, call_next):
    print(f"Incoming request: {request.method} {request.url}")
    response = await call_next(request)
    print(f"Response status: {response.status_code}")
    return response
app.include_router(auth.router, prefix="/api/auth", tags=["Authentication"])
app.include_router(users.router, prefix="/api/users", tags=["Users"])
app.include_router(hotels.router, prefix="/api/hotels", tags=["Hotels"])
app.include_router(bookings.router, prefix="/api/bookings", tags=["Bookings"])
app.include_router(payments.router, prefix="/api/payments", tags=["Payments"])
app.include_router(reviews.router, prefix="/api/reviews", tags=["Reviews"])
app.include_router(chat.router, prefix="/api/chat", tags=["Chat"])
app.include_router(analytics.router, prefix="/api/analytics", tags=["Analytics"])

@app.get("/")
def read_root():
    return {
        "message": "Hotel Booking API",
        "version": "1.0.0",
        "docs": "/docs",
        "health": "OK"
    }

@app.get("/health")
def health_check():
    return {"status": "healthy", "message": "API is running"}

if __name__ == "__main__":
    import uvicorn
    
    host = os.getenv("HOST", "0.0.0.0")
    port = int(os.getenv("PORT", 8000))
    debug = os.getenv("DEBUG", "true").lower() == "true"
    
    uvicorn.run(
        "main:app" if not debug else app,
        host=host,
        port=port,
        reload=debug
    )