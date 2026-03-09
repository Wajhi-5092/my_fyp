from fastapi import APIRouter, HTTPException, UploadFile, File
import asyncio
from models import PromptRequest
from services import chat_with_llm, transcribe_file_bytes, generate_chat_title
from config import groq_client, deepgram_client
from database import db
from datetime import datetime
import uuid

router = APIRouter()

# ===== Global conversation history =====
conversation_history = []

# ===== AI ENDPOINTS =====
@router.post("/chat")
async def chat(req: PromptRequest):
    if not groq_client:
        raise HTTPException(status_code=500, detail="Groq Client not configured")

    # Fetch existing chat or ensure it belongs to user
    chat_doc = db.chats.find_one({"chat_id": req.chat_id, "user_email": req.email})
    
    # Use provided history or fall back to DB history
    current_history = req.history if req.history else (chat_doc["messages"] if chat_doc else [])

    reply, updated_history = chat_with_llm(
        user_message=req.prompt,
        styles=req.styles,
        code_request=req.code_request,
        only_code=req.only_code,
        language=req.language,
        history=current_history
    )

    # Update or Create Chat in MongoDB
    update_data = {
        "messages": updated_history,
        "updated_at": datetime.utcnow(),
    }

    # Generate a proper AI title if it's the first real message
    if not chat_doc or chat_doc.get("last_message") == "New Chat":
        update_data["last_message"] = generate_chat_title(req.prompt)

    db.chats.update_one(
        {"chat_id": req.chat_id, "user_email": req.email},
        {"$set": update_data},
        upsert=True
    )

    return {"response": reply, "chat_id": req.chat_id}

@router.get("/chats/{email}")
async def get_user_chats(email: str):
    chats = db.chats.find({"user_email": email}).sort("updated_at", -1)
    return [
        {
            "chat_id": c["chat_id"],
            "last_message": c.get("last_message", "New Chat"),
            "updated_at": c["updated_at"].isoformat() if isinstance(c["updated_at"], datetime) else c["updated_at"]
        }
        for c in chats
    ]

@router.get("/chat-history/{chat_id}")
async def get_chat_history(chat_id: str):
    chat_doc = db.chats.find_one({"chat_id": chat_id})
    if not chat_doc:
        return {"messages": []}
    return {"messages": chat_doc["messages"]}

@router.post("/new-chat")
async def create_new_chat(req: dict):
    email = req.get("email")
    if not email:
        raise HTTPException(status_code=400, detail="Email required")
    
    new_id = str(uuid.uuid4())
    db.chats.insert_one({
        "chat_id": new_id,
        "user_email": email,
        "messages": [],
        "created_at": datetime.utcnow(),
        "updated_at": datetime.utcnow(),
        "last_message": "New Chat"
    })
    return {"chat_id": new_id}

@router.delete("/chats/{email}")
async def clear_user_chats(email: str):
    result = db.chats.delete_many({"user_email": email})
    return {"success": True, "deleted_count": result.deleted_count}

@router.delete("/chat/{chat_id}")
async def delete_single_chat(chat_id: str):
    result = db.chats.delete_one({"chat_id": chat_id})
    if result.deleted_count == 0:
        raise HTTPException(status_code=404, detail="Chat not found")
    return {"success": True}

@router.post("/transcribe")
async def transcribe_audio(file: UploadFile = File(...)):
    if not deepgram_client:
        raise HTTPException(status_code=500, detail="Deepgram Client not configured")
    file_bytes = await file.read()
    transcript = await asyncio.to_thread(transcribe_file_bytes, file_bytes)
    return {"transcript": transcript}
