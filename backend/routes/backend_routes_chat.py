from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
import openai
import os
from database import get_db
import models
import schemas
from auth.auth import get_current_user

router = APIRouter()

openai.api_key = os.getenv("OPENAI_API_KEY")

@router.get("/hotel/{hotel_id}", response_model=List[schemas.ChatMessageResponse])
def get_chat_messages(
    hotel_id: int,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    messages = db.query(models.ChatMessage).filter(
        models.ChatMessage.hotel_id == hotel_id,
        models.ChatMessage.user_id == current_user.id
    ).order_by(models.ChatMessage.created_at).all()
    return messages

@router.post("/hotel/{hotel_id}", response_model=schemas.ChatMessageResponse)
def send_message(
    hotel_id: int,
    message: schemas.ChatMessageCreate,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    hotel = db.query(models.Hotel).filter(models.Hotel.id == hotel_id).first()
    if not hotel:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Hotel not found"
        )
    
    user_message = models.ChatMessage(
        user_id=current_user.id,
        hotel_id=hotel_id,
        message=message.message,
        is_from_user=True,
        is_ai_response=False
    )
    
    db.add(user_message)
    db.commit()
    db.refresh(user_message)
    
    owner = hotel.owner
    if owner and owner.is_active:
        ai_response = generate_ai_response(message.message, hotel)
        
        ai_message = models.ChatMessage(
            user_id=current_user.id,
            hotel_id=hotel_id,
            message=ai_response,
            is_from_user=False,
            is_ai_response=True
        )
        
        db.add(ai_message)
        db.commit()
        db.refresh(ai_message)
    
    return user_message

@router.post("/hotel/{hotel_id}/owner-reply", response_model=schemas.ChatMessageResponse)
def owner_reply(
    hotel_id: int,
    message: schemas.ChatMessageCreate,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    hotel = db.query(models.Hotel).filter(
        models.Hotel.id == hotel_id,
        models.Hotel.owner_id == current_user.id
    ).first()
    
    if not hotel:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Hotel not found or you don't own this hotel"
        )
    
    owner_message = models.ChatMessage(
        user_id=current_user.id,
        hotel_id=hotel_id,
        message=message.message,
        is_from_user=False,
        is_ai_response=False
    )
    
    db.add(owner_message)
    db.commit()
    db.refresh(owner_message)
    return owner_message

def generate_ai_response(user_message: str, hotel: models.Hotel) -> str:
    try:
        if not openai.api_key:
            return f"Thank you for your message about {hotel.name}. Our team will get back to you soon!"
        
        system_prompt = f"""You are a helpful assistant for {hotel.name}, a hotel located in {hotel.city}, {hotel.country}. 
        
        Hotel details:
        - Name: {hotel.name}
        - Location: {hotel.address}, {hotel.city}, {hotel.country}
        - Price per night: ${hotel.price_per_night}
        - Rating: {hotel.rating}/5
        - Amenities: {', '.join(hotel.amenities or [])}
        - Available rooms: {hotel.available_rooms}
        
        You can help with:
        - Hotel information and amenities
        - Booking inquiries
        - Local area information
        - General hospitality questions
        
        Be friendly, professional, and helpful. If you can't answer something specific, politely direct them to contact the hotel directly."""
        
        response = openai.ChatCompletion.create(
            model="gpt-4o-mini",
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": user_message}
            ],
            max_tokens=200,
            temperature=0.7
        )
        
        return response.choices[0].message.content.strip()
    except Exception as e:
        return f"Thank you for your message about {hotel.name}. Our team will get back to you soon!"

@router.delete("/message/{message_id}")
def delete_message(
    message_id: int,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    message = db.query(models.ChatMessage).filter(
        models.ChatMessage.id == message_id,
        models.ChatMessage.user_id == current_user.id
    ).first()
    
    if not message:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Message not found"
        )
    
    db.delete(message)
    db.commit()
    return {"message": "Message deleted successfully"}