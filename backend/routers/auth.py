from fastapi import APIRouter, HTTPException
import bcrypt
import random
from models import SignupRequest, LoginRequest, ForgotPasswordRequest, ResetPasswordRequest
from database import users

router = APIRouter()

# ===== AUTH ENDPOINTS =====
@router.post("/signup")
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

@router.post("/login")
async def login(data: LoginRequest):
    user = users.find_one({"email": data.email})
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    if bcrypt.checkpw(data.password.encode(), user["password"]):
        return {"message": "Login success"}
    else:
        raise HTTPException(status_code=401, detail="Wrong password")

@router.post("/forgot-password")
async def forgot_password(req: ForgotPasswordRequest):
    user = users.find_one({"email": req.email})
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    otp = str(random.randint(1000, 9999))
    print(f"------------ OTP for {req.email}: {otp} ------------")
    users.update_one({"email": req.email}, {"$set": {"otp": otp}})
    return {"message": "OTP generated (check console)"}

@router.post("/reset-password")
async def reset_password(req: ResetPasswordRequest):
    user = users.find_one({"email": req.email})
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    if user.get("otp") != req.otp:
        raise HTTPException(status_code=400, detail="Invalid OTP")

    hashed_pw = bcrypt.hashpw(req.new_password.encode(), bcrypt.gensalt())
    users.update_one({"email": req.email}, {"$set": {"password": hashed_pw}, "$unset": {"otp": ""}})
    return {"message": "Password reset successfully"}
