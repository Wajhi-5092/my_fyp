from pygments import highlight
from pygments.lexers import get_lexer_by_name, guess_lexer
from pygments.formatters import TerminalFormatter
from config import groq_client, deepgram_client

import sys
import time
import re

# ===== Style Prompts =====
STYLE_PROMPTS = {
    "short": "Provide a concise answer in 1–2 sentences.",
    "descriptive": "Explain clearly with examples in 1–3 paragraphs.",
    "long": "Provide a detailed explanation with multiple structured paragraphs.",
    "professional": "Provide a formal, professional explanation suitable for reports or academic use.",
    "bulletpoints": "Present the information using clear bullet points for readability.",
}

# ===== Helpers =====
def format_code(text, language=None):
    if not text.strip():
        return ""

    # Regex to detect code blocks like ```python ... ```
    pattern = r"```(\w*)\n?(.*?)```"
    
    # If it's a raw code string without backticks, handle it directly
    if "```" not in text:
        try:
            lexer = get_lexer_by_name(language.lower()) if language else guess_lexer(text)
            return highlight(text, lexer, TerminalFormatter())
        except Exception:
            return text

    # Handle mixed text and code blocks (Markdown style)
    def replace_block(match):
        lang = match.group(1).strip()
        code = match.group(2)
        
        try:
            if lang:
                lexer = get_lexer_by_name(lang)
            else:
                lexer = guess_lexer(code)
            return highlight(code, lexer, TerminalFormatter())
        except Exception:
            return f"\n{code}\n" # Fallback to raw code

    return re.sub(pattern, replace_block, text, flags=re.DOTALL)

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

def generate_chat_title(first_prompt: str) -> str:
    """Generates a 2-3 word chat title based on the first prompt."""
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
        # Remove any quotes or periods the AI might add
        title = title.replace('"', '').replace("'", '').replace('.', '')
        return title if title else first_prompt[:25]
    except Exception:
        return first_prompt[:25]

def transcribe_file_bytes(file_bytes):
    response = deepgram_client.listen.v1.media.transcribe_file(
        request=file_bytes,
        model="nova-3"
    )
    return response.results.channels[0].alternatives[0].transcript


# ==============================
# EXTRA FEATURES (NO CHANGE TO YOUR CODE)
# ==============================


# ===== Streaming Effect =====
def stream_print(text, delay=0.01):
    for char in text:
        sys.stdout.write(char)
        sys.stdout.flush()
        time.sleep(delay)
    print()


# ===== Style Detection =====
def detect_style(text):
    text = text.lower()

    if len(text) < 40:
        return ["short"]

    if "explain" in text or "why" in text or "how" in text:
        return ["descriptive"]

    if "detail" in text or "deep" in text:
        return ["long"]

    if "report" in text or "professional" in text:
        return ["professional"]

    if "list" in text or "bullet" in text or "points" in text:
        return ["bulletpoints"]

    return []


# ===== History Manager =====
MAX_HISTORY = 20

def trim_history(history):
    if history and len(history) > MAX_HISTORY:
        return history[-MAX_HISTORY:]
    return history


# ===== Smart Chat Wrapper =====
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


# ===== Voice Chat Wrapper =====
def voice_chat(audio_bytes, history):

    text = transcribe_file_bytes(audio_bytes)

    print("\nYou said:", text)

    reply, history = smart_chat(text, history)

    return reply, history


# ===== ChatGPT Style CLI =====
def run_cli():

    print("\nAI Assistant Ready (type 'exit' to quit)\n")

    history = []

    while True:

        try:
            user_input = input("You: ")

            if user_input.lower() in ["exit", "quit"]:
                print("\nGoodbye!\n")
                break

            reply, history = smart_chat(user_input, history)

            # Apply color formatting to code in the response
            formatted_reply = format_code(reply)

            print("\nAssistant: ")
            stream_print(formatted_reply)

        except KeyboardInterrupt:
            print("\nInterrupted")
            break


# ===== Run Assistant =====
if __name__ == "__main__":
    run_cli()