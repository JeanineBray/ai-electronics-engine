import os
from typing import Optional
from fastapi import Header, HTTPException
from dotenv import load_dotenv
from pathlib import Path
from supabase import create_client

# Load backend/.env reliably regardless of working directory
env_path = Path(__file__).resolve().parent.parent / ".env"
load_dotenv(dotenv_path=env_path)

SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_ANON_KEY = os.getenv("SUPABASE_ANON_KEY")

if not SUPABASE_URL or not SUPABASE_ANON_KEY:
    raise RuntimeError("Missing SUPABASE_URL or SUPABASE_ANON_KEY in backend/.env")

auth_client = create_client(SUPABASE_URL, SUPABASE_ANON_KEY)

def get_bearer_token(authorization: Optional[str]) -> str:
    if not authorization:
        raise HTTPException(status_code=401, detail="Missing Authorization header")
    if not authorization.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Authorization header must be: Bearer <token>")
    return authorization[len("Bearer "):].strip()

def get_current_user_id(authorization: Optional[str] = Header(default=None)) -> str:
    token = get_bearer_token(authorization)

    # Ask Supabase Auth: "Who is this token for?"
    res = auth_client.auth.get_user(token)

    user = getattr(res, "user", None)
    if not user or not getattr(user, "id", None):
        raise HTTPException(status_code=401, detail="Invalid or expired token")

    return user.id
