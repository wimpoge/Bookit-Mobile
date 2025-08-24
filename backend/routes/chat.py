from fastapi import APIRouter, Depends, HTTPException, status, WebSocket, WebSocketDisconnect
from sqlalchemy.orm import Session
from sqlalchemy import and_, desc, func, case
from typing import List, Dict
import json
import asyncio
from database import get_db
import models
import schemas
from auth.auth import get_current_user, get_current_owner, get_user_from_token

router = APIRouter()

class ConnectionManager:
    def __init__(self):
        self.active_connections: Dict[str, WebSocket] = {}
        
    async def connect(self, websocket: WebSocket, user_id: int, hotel_id: int, is_owner: bool = False):
        await websocket.accept()
        connection_key = f"{user_id}_{hotel_id}_{'owner' if is_owner else 'user'}"
        self.active_connections[connection_key] = websocket
        
    def disconnect(self, user_id: int, hotel_id: int, is_owner: bool = False):
        connection_key = f"{user_id}_{hotel_id}_{'owner' if is_owner else 'user'}"
        if connection_key in self.active_connections:
            del self.active_connections[connection_key]
    
    async def send_personal_message(self, message: dict, user_id: int, hotel_id: int, is_owner: bool = False):
        connection_key = f"{user_id}_{hotel_id}_{'owner' if is_owner else 'user'}"
        if connection_key in self.active_connections:
            try:
                await self.active_connections[connection_key].send_text(json.dumps(message))
            except:
                self.disconnect(user_id, hotel_id, is_owner)
    
    async def broadcast_to_chat(self, message: dict, hotel_id: int, sender_user_id: int, sender_is_owner: bool):
        if sender_is_owner:
            await self.send_personal_message(message, sender_user_id, hotel_id, False)
        else:
            if 'owner_id' in message:
                await self.send_personal_message(message, message['owner_id'], hotel_id, True)

manager = ConnectionManager()

@router.websocket("/ws/user/{hotel_id}")
async def websocket_user_chat(websocket: WebSocket, hotel_id: int, token: str, db: Session = Depends(get_db)):
    try:
        user = await get_user_from_token(token, db)
        if not user:
            await websocket.close(code=4001)
            return
            
        await manager.connect(websocket, user.id, hotel_id, False)
        
        try:
            while True:
                data = await websocket.receive_text()
                message_data = json.loads(data)
                
                db_message = models.ChatMessage(
                    hotel_id=hotel_id,
                    user_id=user.id,
                    message=message_data['message'],
                    is_from_user=True,
                    is_from_owner=False,
                    is_ai_response=False,
                    is_read=False
                )
                
                db.add(db_message)
                db.commit()
                db.refresh(db_message)
                
                hotel = db.query(models.Hotel).filter(models.Hotel.id == hotel_id).first()
                
                broadcast_message = {
                    "type": "new_message",
                    "message": {
                        "id": db_message.id,
                        "message": db_message.message,
                        "hotel_id": db_message.hotel_id,
                        "user_id": db_message.user_id,
                        "is_from_user": db_message.is_from_user,
                        "is_from_owner": db_message.is_from_owner,
                        "is_ai_response": db_message.is_ai_response,
                        "is_read": db_message.is_read,
                        "created_at": db_message.created_at.isoformat()
                    },
                    "owner_id": hotel.owner_id if hotel else None
                }
                
                await manager.broadcast_to_chat(broadcast_message, hotel_id, user.id, False)
                
        except WebSocketDisconnect:
            manager.disconnect(user.id, hotel_id, False)
    except Exception as e:
        await websocket.close(code=4000)

@router.websocket("/ws/owner/{hotel_id}/{user_id}")
async def websocket_owner_chat(websocket: WebSocket, hotel_id: int, user_id: int, token: str, db: Session = Depends(get_db)):
    try:
        owner = await get_user_from_token(token, db)
        if not owner:
            await websocket.close(code=4001)
            return
            
        hotel = db.query(models.Hotel).filter(
            and_(models.Hotel.id == hotel_id, models.Hotel.owner_id == owner.id)
        ).first()
        
        if not hotel:
            await websocket.close(code=4003)
            return
            
        await manager.connect(websocket, owner.id, hotel_id, True)
        
        try:
            while True:
                data = await websocket.receive_text()
                message_data = json.loads(data)
                
                db_message = models.ChatMessage(
                    hotel_id=hotel_id,
                    user_id=user_id,
                    message=message_data['message'],
                    is_from_user=False,
                    is_from_owner=True,
                    is_ai_response=False,
                    is_read=True
                )
                
                db.add(db_message)
                db.commit()
                db.refresh(db_message)
                
                broadcast_message = {
                    "type": "new_message",
                    "message": {
                        "id": db_message.id,
                        "message": db_message.message,
                        "hotel_id": db_message.hotel_id,
                        "user_id": db_message.user_id,
                        "is_from_user": db_message.is_from_user,
                        "is_from_owner": db_message.is_from_owner,
                        "is_ai_response": db_message.is_ai_response,
                        "is_read": db_message.is_read,
                        "created_at": db_message.created_at.isoformat()
                    }
                }
                
                await manager.broadcast_to_chat(broadcast_message, hotel_id, user_id, True)
                
        except WebSocketDisconnect:
            manager.disconnect(owner.id, hotel_id, True)
    except Exception as e:
        await websocket.close(code=4000)

@router.get("/hotel/{hotel_id}", response_model=List[schemas.ChatMessageResponse])
def get_chat_messages(
    hotel_id: int,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    hotel = db.query(models.Hotel).filter(models.Hotel.id == hotel_id).first()
    if not hotel:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Hotel not found"
        )
    
    messages = db.query(models.ChatMessage).filter(
        and_(
            models.ChatMessage.hotel_id == hotel_id,
            models.ChatMessage.user_id == current_user.id
        )
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
    
    db_message = models.ChatMessage(
        hotel_id=hotel_id,
        user_id=current_user.id,
        message=message.message,
        is_from_user=True,
        is_from_owner=False,
        is_ai_response=False,
        is_read=False
    )
    
    db.add(db_message)
    db.commit()
    db.refresh(db_message)
    
    return db_message

@router.get("/owner/conversations", response_model=List[schemas.ChatConversationResponse])
def get_owner_conversations(
    current_user: models.User = Depends(get_current_owner),
    db: Session = Depends(get_db)
):
    owner_hotels = db.query(models.Hotel).filter(
        models.Hotel.owner_id == current_user.id
    ).all()
    
    if not owner_hotels:
        return []
    
    hotel_ids = [hotel.id for hotel in owner_hotels]
    
    conversations_query = db.query(
        models.ChatMessage.hotel_id,
        models.ChatMessage.user_id,
        func.max(models.ChatMessage.created_at).label('last_message_time'),
        func.sum(
            case(
                (and_(
                    models.ChatMessage.is_from_user == True,
                    models.ChatMessage.is_read == False
                ), 1),
                else_=0
            )
        ).label('unread_count')
    ).filter(
        models.ChatMessage.hotel_id.in_(hotel_ids)
    ).group_by(
        models.ChatMessage.hotel_id,
        models.ChatMessage.user_id
    ).order_by(desc('last_message_time'))
    
    conversations_data = conversations_query.all()
    
    if not conversations_data:
        return []
    
    conversations = []
    for conv_data in conversations_data:
        hotel = db.query(models.Hotel).filter(
            models.Hotel.id == conv_data.hotel_id
        ).first()
        
        user = db.query(models.User).filter(
            models.User.id == conv_data.user_id
        ).first()
        
        last_message = db.query(models.ChatMessage).filter(
            and_(
                models.ChatMessage.hotel_id == conv_data.hotel_id,
                models.ChatMessage.user_id == conv_data.user_id
            )
        ).order_by(desc(models.ChatMessage.created_at)).first()
        
        if hotel and user and last_message:
            conversation = schemas.ChatConversationResponse(
                hotel_id=hotel.id,
                user_id=user.id,
                hotel=schemas.HotelResponse.from_orm(hotel),
                guest_name=user.full_name or user.email,
                last_message=schemas.ChatMessageResponse.from_orm(last_message),
                unread_count=conv_data.unread_count or 0,
                has_unread_messages=(conv_data.unread_count or 0) > 0
            )
            conversations.append(conversation)
    
    return conversations

@router.get("/owner/chats/{hotel_id}/{user_id}", response_model=List[schemas.ChatMessageResponse])
def get_owner_chat_messages(
    hotel_id: int,
    user_id: int,
    current_user: models.User = Depends(get_current_owner),
    db: Session = Depends(get_db)
):
    hotel = db.query(models.Hotel).filter(
        and_(
            models.Hotel.id == hotel_id,
            models.Hotel.owner_id == current_user.id
        )
    ).first()
    
    if not hotel:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Hotel not found or access denied"
        )
    
    messages = db.query(models.ChatMessage).filter(
        and_(
            models.ChatMessage.hotel_id == hotel_id,
            models.ChatMessage.user_id == user_id
        )
    ).order_by(models.ChatMessage.created_at).all()
    
    db.query(models.ChatMessage).filter(
        and_(
            models.ChatMessage.hotel_id == hotel_id,
            models.ChatMessage.user_id == user_id,
            models.ChatMessage.is_from_user == True,
            models.ChatMessage.is_read == False
        )
    ).update({"is_read": True})
    
    db.commit()
    
    return messages

@router.post("/owner/chats/{hotel_id}/{user_id}", response_model=schemas.ChatMessageResponse)
def send_owner_message(
    hotel_id: int,
    user_id: int,
    message: schemas.ChatMessageCreate,
    current_user: models.User = Depends(get_current_owner),
    db: Session = Depends(get_db)
):
    hotel = db.query(models.Hotel).filter(
        and_(
            models.Hotel.id == hotel_id,
            models.Hotel.owner_id == current_user.id
        )
    ).first()
    
    if not hotel:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Hotel not found or access denied"
        )
    
    db_message = models.ChatMessage(
        hotel_id=hotel_id,
        user_id=user_id,
        message=message.message,
        is_from_user=False,
        is_from_owner=True,
        is_ai_response=False,
        is_read=True
    )
    
    db.add(db_message)
    db.commit()
    db.refresh(db_message)
    
    return db_message