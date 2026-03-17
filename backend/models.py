from pydantic import BaseModel
from typing import List, Dict, Optional

# ===== Models =====
class SignupRequest(BaseModel):
    name: str
    email: str
    password: str

class LoginRequest(BaseModel):
    email: str
    password: str

class PromptRequest(BaseModel):
    prompt: Optional[str] = ""
    email: str # User email for identification
    chat_id: str # Specific chat session ID
    history: Optional[List[Dict[str, str]]] = []
    styles: Optional[List[str]] = ["descriptive"]
    code_request: Optional[bool] = False
    only_code: Optional[bool] = False
    language: Optional[str] = None

class NewChatRequest(BaseModel):
    email: str

class ForgotPasswordRequest(BaseModel):
    email: str

class ResetPasswordRequest(BaseModel):
    email: str
    otp: str
    new_password: str

class LectureCreateRequest(BaseModel):
    email: str
    title: str
    course_code: Optional[str] = None
    instructor: Optional[str] = None
    transcript: str
