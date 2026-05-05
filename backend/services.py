from pygments import highlight
from pygments.lexers import get_lexer_by_name, guess_lexer
from pygments.formatters import TerminalFormatter
from config import groq_client, deepgram_client

import sys
import time
import re

# ==============================
# STYLE PROMPTS
# ==============================
STYLE_PROMPTS = {
    "short": "Provide a concise answer in 1–2 sentences.",
    "descriptive": "Explain clearly with examples in 1–3 paragraphs.",
    "long": "Provide a detailed explanation with multiple structured paragraphs.",
    "professional": "Provide a formal, professional explanation.",
    "bulletpoints": "Present the information using bullet points.",
}

# ==============================
# FORCE ENGLISH RULE (IMPORTANT)
# ==============================
GLOBAL_SYSTEM_RULE = """
You are a helpful AI assistant.

RULES:
- Respond ONLY in English.
- Do NOT use Urdu, Hindi, or Roman Urdu/Hindi words.
- If user speaks Roman Urdu or mixed language, translate internally and respond in English.
- Keep responses natural, clear, and professional.
"""

# ==============================
# CODE FORMATTER
# ==============================
def format_code(text, language=None):
    if not text.strip():
        return ""

    pattern = r"```(\w*)\n?(.*?)```"

    if "```" not in text:
        try:
            lexer = get_lexer_by_name(language.lower()) if language else guess_lexer(text)
            return highlight(text, lexer, TerminalFormatter())
        except Exception:
            return text

    def replace_block(match):
        lang = match.group(1).strip()
        code = match.group(2)

        try:
            lexer = get_lexer_by_name(lang) if lang else guess_lexer(code)
            return highlight(code, lexer, TerminalFormatter())
        except Exception:
            return f"\n{code}\n"

    return re.sub(pattern, replace_block, text, flags=re.DOTALL)

# ==============================
# DETECT CODE REQUEST
# ==============================
def auto_detect_code_request(user_input):
    code_keywords = ["code", "function", "program", "script", "implementation", "algorithm"]
    only_code_keywords = ["only code", "just code", "code only"]

    code_request = any(word in user_input.lower() for word in code_keywords)
    only_code = any(word in user_input.lower() for word in only_code_keywords)

    return code_request, only_code

# ==============================
# ENFORCE ENGLISH ONLY (SAFETY)
# ==============================
def enforce_english_only(text):
    forbidden = [
        "hai", "hain", "kya", "acha", "nahi", "nahin",
        "mein", "tum", "ap", "aur", "se", "yeh", "woh"
    ]

    for word in forbidden:
        text = re.sub(rf"\b{word}\b", "", text, flags=re.IGNORECASE)

    return text

# ==============================
# CHAT WITH LLM
# ==============================
def chat_with_llm(user_message, styles=[], code_request=False, only_code=False, language=None, history=None):

    style_instruction = " ".join([STYLE_PROMPTS[s] for s in styles if s in STYLE_PROMPTS])

    prompt = user_message

    if code_request:
        lang = language if language else 'any'
        prompt += f"\nGenerate the answer as executable {lang} code."
        if only_code:
            prompt += " Return only the code, no explanation."

    messages = history.copy() if history else []

    system_content = GLOBAL_SYSTEM_RULE
    if style_instruction:
        system_content += "\n" + style_instruction

    if messages and messages[0].get("role") == "system":
        messages[0] = {"role": "system", "content": system_content}
    else:
        messages.insert(0, {"role": "system", "content": system_content})

    messages.append({"role": "user", "content": prompt})

    response = groq_client.chat.completions.create(
        model="llama-3.1-8b-instant",
        messages=messages,
        max_tokens=4000,
        temperature=0.7
    )

    assistant_reply = response.choices[0].message.content

    # FORCE CLEAN ENGLISH OUTPUT
    assistant_reply = enforce_english_only(assistant_reply)

    messages.append({"role": "assistant", "content": assistant_reply})

    return assistant_reply, messages

# ==============================
# CHAT TITLE GENERATOR
# ==============================
def generate_chat_title(first_prompt: str) -> str:
    try:
        response = groq_client.chat.completions.create(
            model="llama-3.1-8b-instant",
            messages=[
                {"role": "system", "content": "You are a helpful assistant. Create a very short (max 3 words) title for a chat based on the user's first prompt. Do not use quotes or periods. Just the title."},
                {"role": "user", "content": f"Task: Summarize this prompt into a 3-word title: {first_prompt}"}
            ],
            max_tokens=10,
            temperature=0.5
        )
        title = response.choices[0].message.content.strip()
        title = title.replace('"', '').replace("'", '').replace('.', '')
        return title if title else first_prompt[:25]
    except Exception:
        return first_prompt[:25]

# ==============================
# STYLE DETECTION
# ==============================
def detect_style(text):
    text = text.lower()

    if len(text) < 40:
        return ["short"]
    if "explain" in text or "why" in text or "how" in text:
        return ["descriptive"]
    if "detail" in text:
        return ["long"]
    if "report" in text:
        return ["professional"]
    if "list" in text:
        return ["bulletpoints"]

    return []

# ==============================
# HISTORY LIMIT
# ==============================
MAX_HISTORY = 20

def trim_history(history):
    if history and len(history) > MAX_HISTORY:
        return history[-MAX_HISTORY:]
    return history

# ==============================
# SMART CHAT
# ==============================
def smart_chat(user_input, history):

    styles = detect_style(user_input)
    code_request, only_code = auto_detect_code_request(user_input)

    reply, history = chat_with_llm(
        user_input,
        styles=styles,
        code_request=code_request,
        only_code=only_code,
        history=history
    )

    history = trim_history(history)

    return reply, history

# ==============================
# STREAM OUTPUT
# ==============================
def stream_print(text, delay=0.01):
    for char in text:
        sys.stdout.write(char)
        sys.stdout.flush()
        time.sleep(delay)
    print()

# ==============================
# SPEECH TO TEXT (ROMAN URDU READY)
# ==============================
def transcribe_file_bytes(file_bytes):
    response = deepgram_client.listen.v1.media.transcribe_file(
        request=file_bytes,
        model="nova-3",
        smart_format=True,
        language="multi"
    )

    return response.results.channels[0].alternatives[0].transcript

# ==============================
# VOICE CHAT
# ==============================
def voice_chat(audio_bytes, history):

    text = transcribe_file_bytes(audio_bytes)
    print("\nYou said:", text)

    reply, history = smart_chat(text, history)

    return reply, history

# ==============================
# CLI CHAT APP
# ==============================
def run_cli():

    print("\nAI Assistant Ready (type 'exit' to quit)\n")

    history = []

    while True:

        user_input = input("You: ")

        if user_input.lower() in ["exit", "quit"]:
            print("\nGoodbye!\n")
            break

        reply, history = smart_chat(user_input, history)

        formatted_reply = format_code(reply)

        print("\nAssistant:")
        stream_print(formatted_reply)

# ==============================
# RUN
# ==============================
if __name__ == "__main__":
    run_cli()