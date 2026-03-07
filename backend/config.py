import os
from dotenv import load_dotenv
from deepgram import DeepgramClient
from openai import OpenAI

# ===== Load environment =====
load_dotenv(override=True)

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
