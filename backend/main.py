from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from pymongo import MongoClient
import bcrypt
import os
import random
from dotenv import load_dotenv
import asyncio
from google import genai


# Load env
load_dotenv(override=True)



app = FastAPI()

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# MongoDB
mongo_client = MongoClient("mongodb://127.0.0.1:27017")
db = mongo_client.voicenotex
users = db.users

# Gemini
genai_client = genai.Client(api_key=os.getenv("GEMINI_API_KEY"))

# -------- MODELS --------
class SignupRequest(BaseModel):
    name: str
    email: str
    password: str

class LoginRequest(BaseModel):
    email: str
    password: str

class PromptRequest(BaseModel):
    prompt: str


class ForgotPasswordRequest(BaseModel):
    email: str

class ResetPasswordRequest(BaseModel):
    email: str
    otp: str
    new_password: str

# -------- AUTH --------
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

    # Generate 4-digit OTP
    otp = str(random.randint(1000, 9999))
    print(f"------------ OTP for {req.email}: {otp} ------------")



    users.update_one(
        {"email": req.email},
        {"$set": {"otp": otp}}
    )

    return {"message": "OTP generated (check console)"}


@app.post("/reset-password")
async def reset_password(req: ResetPasswordRequest):
    user = users.find_one({"email": req.email})
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    if user.get("otp") != req.otp:
        raise HTTPException(status_code=400, detail="Invalid OTP")

    hashed_pw = bcrypt.hashpw(req.new_password.encode(), bcrypt.gensalt())

    users.update_one(
        {"email": req.email},
        {"$set": {"password": hashed_pw}, "$unset": {"otp": ""}}
    )

    return {"message": "Password reset successfully"}


# -------- GEMINI --------
@app.post("/generate")
async def generate_content(req: PromptRequest):
    loop = asyncio.get_running_loop()

    response = await loop.run_in_executor(
        None,
        lambda: genai_client.models.generate_content(
            model="gemini-3-flash-preview",
            contents=req.prompt,
        )
    )

    return {"text": response.text}
