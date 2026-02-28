# server.py
from fastapi import FastAPI, HTTPException, UploadFile, File
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from pymongo import MongoClient
import bcrypt
import os
import random
from dotenv import load_dotenv
import asyncio
from typing import List, Dict, Optional
from deepgram import DeepgramClient
from openai import OpenAI
from pygments import highlight
from pygments.lexers import get_lexer_by_name, guess_lexer
from pygments.formatters import TerminalFormatter

# ===== Load environment =====
load_dotenv(override=True)

app = FastAPI()

# ===== CORS =====
# For local development, allow everything. 
# Note: If allow_credentials is True, allow_origins cannot be ["*"].
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False, 
    allow_methods=["*"],
    allow_headers=["*"],
)

# ===== Style Prompts =====
STYLE_PROMPTS = {
    "short": "Provide a concise answer in 2–3 sentences.",
    "descriptive": "Explain clearly with examples in 1–2 paragraphs.",
    "long": "Provide a detailed explanation with multiple structured paragraphs.",
    "professional": "Provide a formal, professional explanation suitable for reports or academic use.",
}

# ===== MongoDB =====
mongo_client = MongoClient("mongodb://127.0.0.1:27017")
db = mongo_client.voicenotex
users = db.users

# ===== AI Clients =====
GROQ_API_KEY = os.getenv("GROQ_API_KEY")
DEEPGRAM_API_KEY = os.getenv("DEEPGRAM_API_KEY")

if GROQ_API_KEY and DEEPGRAM_API_KEY:
    deepgram_client = DeepgramClient(api_key=DEEPGRAM_API_KEY)
    groq_client = OpenAI(api_key=GROQ_API_KEY, base_url="https://api.groq.com/openai/v1")
else:
    print("WARNING: GROQ_API_KEY or DEEPGRAM_API_KEY not found in environment.")
    deepgram_client = None
    groq_client = None

# ===== Global conversation history =====
conversation_history = []

# ===== Models =====
class SignupRequest(BaseModel):
    name: str
    email: str
    password: str

class LoginRequest(BaseModel):
    email: str
    password: str

class PromptRequest(BaseModel):
    prompt: str
    history: Optional[List[Dict[str, str]]] = []
    styles: Optional[List[str]] = ["descriptive"]
    code_request: Optional[bool] = False
    only_code: Optional[bool] = False
    language: Optional[str] = None

class ForgotPasswordRequest(BaseModel):
    email: str

class ResetPasswordRequest(BaseModel):
    email: str
    otp: str
    new_password: str

# ===== Helpers =====
def format_code(code_text, language=None):
    if not code_text.strip():
        return ""
    try:
        lexer = get_lexer_by_name(language.lower()) if language else guess_lexer(code_text)
        return highlight(code_text, lexer, TerminalFormatter())
    except Exception:
        return code_text

def auto_detect_code_request(user_input):
    code_keywords = ["code", "function", "program", "script", "implementation", "algorithm"]
    only_code_keywords = ["only code", "just code", "code only"]
    code_request = any(word.lower() in user_input.lower() for word in code_keywords)
    only_code = any(word.lower() in user_input.lower() for word in only_code_keywords)
    return code_request, only_code

def chat_with_llm(user_message, styles=[], code_request=False, only_code=False, language=None, history=None):
    style_instruction = " ".join([STYLE_PROMPTS[s] for s in styles if s in STYLE_PROMPTS])
    prompt = style_instruction + "\n\n" + user_message if style_instruction else user_message

    if code_request:
        lang = language if language else 'any'
        prompt += f"\nGenerate the answer as executable {lang} code."
        if only_code:
            prompt += " Return only the code, no extra explanation."

    # Build messages list
    messages = history.copy() if history else []
    messages.append({"role": "user", "content": prompt})

    response = groq_client.chat.completions.create(
        model="llama-3.1-8b-instant",
        messages=messages,
        max_tokens=4000,
        temperature=0.7
    )

    assistant_reply = response.choices[0].message.content
    messages.append({"role": "assistant", "content": assistant_reply})
    return assistant_reply, messages

async def transcribe_file_bytes(file_bytes):
    response = deepgram_client.listen.v1.media.transcribe_file(
        request=file_bytes,
        model="nova-3"
    )
    return response.results.channels[0].alternatives[0].transcript

# ===== AUTH ENDPOINTS =====
@app.post("/signup")
async def signup(user: SignupRequest):
    if users.find_one({"email": user.email}):
        raise HTTPException(status_code=400, detail="Email already exists")

    hashed_pw = bcrypt.hashpw(user.password.encode(), bcrypt.gensalt())

    users.insert_one({
        "name": user.name,
        "email": user.email,
        "password": hashed_pw
    })

    return {"message": "User created"}

@app.post("/login")
async def login(data: LoginRequest):
    user = users.find_one({"email": data.email})
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    if bcrypt.checkpw(data.password.encode(), user["password"]):
        return {"message": "Login success"}
    else:
        raise HTTPException(status_code=401, detail="Wrong password")

@app.post("/forgot-password")
async def forgot_password(req: ForgotPasswordRequest):
    user = users.find_one({"email": req.email})
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    otp = str(random.randint(1000, 9999))
    print(f"------------ OTP for {req.email}: {otp} ------------")
    users.update_one({"email": req.email}, {"$set": {"otp": otp}})
    return {"message": "OTP generated (check console)"}

@app.post("/reset-password")
async def reset_password(req: ResetPasswordRequest):
    user = users.find_one({"email": req.email})
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    if user.get("otp") != req.otp:
        raise HTTPException(status_code=400, detail="Invalid OTP")

    hashed_pw = bcrypt.hashpw(req.new_password.encode(), bcrypt.gensalt())
    users.update_one({"email": req.email}, {"$set": {"password": hashed_pw}, "$unset": {"otp": ""}})
    return {"message": "Password reset successfully"}

# ===== AI ENDPOINTS =====
@app.post("/chat")
async def chat(req: PromptRequest):
    if not groq_client:
        raise HTTPException(status_code=500, detail="Groq Client not configured")

    reply, updated_history = chat_with_llm(
        user_message=req.prompt,
        styles=req.styles,
        code_request=req.code_request,
        only_code=req.only_code,
        language=req.language,
        history=req.history or conversation_history
    )

    conversation_history.extend(updated_history[len(conversation_history):])
    return {"response": reply}

@app.post("/transcribe")
async def transcribe_audio(file: UploadFile = File(...)):
    if not deepgram_client:
        raise HTTPException(status_code=500, detail="Deepgram Client not configured")
    file_bytes = await file.read()
    transcript = await asyncio.to_thread(transcribe_file_bytes, file_bytes)
    return {"transcript": transcript}