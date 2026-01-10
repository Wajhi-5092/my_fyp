from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from google import genai
import os
from dotenv import load_dotenv
import asyncio  # new

load_dotenv()

app = FastAPI()

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], 
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

client = genai.Client(api_key=os.getenv("GEMINI_API_KEY"))

class PromptRequest(BaseModel):
    prompt: str

# Async POST endpoint
@app.post("/generate")
async def generate_content(req: PromptRequest):
    # Run blocking Gemini call in a separate thread to avoid blocking the event loop
    loop = asyncio.get_running_loop()
    response = await loop.run_in_executor(
        None, 
        lambda: client.models.generate_content(
            model="gemini-3-flash-preview",
            contents=req.prompt,
        )
    )
    return {"text": response.text}
