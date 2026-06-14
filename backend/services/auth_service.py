from typing import Optional

from sqlalchemy.orm import Session

from database.models import User
from schemas.auth import RegisterRequest
from utils.security import get_password_hash, verify_password


def get_user_by_email(db: Session, email: str) -> Optional[User]:
    return db.query(User).filter(User.email == email.lower().strip()).first()


def create_user(db: Session, request: RegisterRequest) -> User:
    user = User(
        full_name=request.full_name.strip(),
        email=request.email.lower().strip(),
        password_hash=get_password_hash(request.password),
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    return user


def authenticate_user(db: Session, email: str, password: str) -> Optional[User]:
    user = get_user_by_email(db, email)
    if not user or not verify_password(password, user.password_hash):
        return None
    return user
