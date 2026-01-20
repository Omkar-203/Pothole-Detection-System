from sqlalchemy import Column, Integer, String, Float, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from database import Base
import datetime

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    email = Column(String, unique=True, index=True)
    password = Column(String)
    role = Column(String, default="user") # 'admin' or 'user'

    requests = relationship("PotholeRequest", back_populates="owner")

class PotholeRequest(Base):
    __tablename__ = "pothole_requests"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    image_path = Column(String)
    latitude = Column(Float)
    longitude = Column(Float)
    severity = Column(String) # 'Minor', 'Medium', 'Major'
    depth = Column(Float)
    status = Column(String, default="pending") # 'pending', 'in_progress', 'fixed'
    street_name = Column(String, nullable=True) # Street/address where detected
    created_at = Column(DateTime, default=datetime.datetime.utcnow)

    owner = relationship("User", back_populates="requests")
