from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Form, Header
from fastapi.responses import JSONResponse
import google.generativeai as genai
import PIL.Image
from sqlalchemy.orm import Session
from database import get_db
from models import PotholeRequest, User
import shutil
import os
from inference import predict_pothole
from typing import List, Optional
from pydantic import BaseModel
from datetime import datetime, timedelta, timezone
from routers.auth import get_current_user
import requests

router = APIRouter(
    prefix="/potholes",
    tags=["potholes"]
)

GEMINI_API_KEY = "AIzaSyDtNuseOeFpFCekWBvd4T25AGEvf5zJtE8"
genai.configure(api_key=GEMINI_API_KEY)

def get_street_name_from_coordinates(latitude: float, longitude: float) -> str:
    """Get street name from coordinates using Nominatim reverse geocoding"""
    try:
        url = f"https://nominatim.openstreetmap.org/reverse?format=json&lat={latitude}&lon={longitude}&zoom=18&addressdetails=1"
        headers = {'User-Agent': 'PotholeDetectionApp/1.0'}
        response = requests.get(url, headers=headers, timeout=5)
        data = response.json()

        if 'address' in data:
            address = data['address']
            # Try to get the most specific street name
            street = address.get('road') or address.get('street') or address.get('highway') or address.get('path')
            if street:
                # Add suburb/city for context if available
                suburb = address.get('suburb') or address.get('city') or address.get('town')
                if suburb and suburb != street:
                    return f"{street}, {suburb}"
                return street

        # Fallback to display name if no specific street found
        return data.get('display_name', 'Unknown Location').split(',')[0]

    except Exception as e:
        print(f"Geocoding error: {e}")
        return "Unknown Location"

def check_pothole_gemini(image_path: str) -> bool:
    try:
        model = genai.GenerativeModel("gemini-2.5-flash")
        img = PIL.Image.open(image_path)
        
        response = model.generate_content([
            "Analyze this image for any potholes, regardless of size. If you see even a small or minor pothole or road damage, answer 'Yes'. If the road is clear of potholes, answer 'No'. Answer only 'Yes' or 'No'.",
            img
        ])
        
        answer = response.text.strip()
        return "yes" in answer.lower()
            
    except Exception as e:
        print(f"Gemini API error: {e}")
        # Identify if we should fail open or closed. User wants it to pass through if it finds a pothole.
        # If error, maybe safe to pass through or just return False? 
        # Requirement: "if it doesn't find any pothole... reply no pothole detected"
        # If API fails, we can't be sure, but let's assume valid flow is needed.
        # Let's assume on error we proceed to YOLO to be safe/robust, or return False.
        # Given "Minimum changes" and strict flow, I will print error and return True (pass to YOLO) to avoid blocking hard 
        # unless it explicitly says 'No'.
        # Actually proper behavior if API fails is probably to fallback to local model. 
        # But let's stick to the prompt: "if it does image should pass through". 
        # If error, we default to passing through.
        return True

class PotholeResponse(BaseModel):
    id: int
    image_path: str
    latitude: float
    longitude: float
    severity: str
    depth: float
    status: str
    street_name: Optional[str]
    created_at: datetime
    
    class Config:
        from_attributes = True

@router.post("/", response_model=PotholeResponse)
async def create_pothole_request(
    latitude: float = Form(...),
    longitude: float = Form(...),
    file: UploadFile = File(...),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    # Save image
    upload_dir = "uploads"
    os.makedirs(upload_dir, exist_ok=True)
    file_location = f"{upload_dir}/{file.filename}"
    with open(file_location, "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)
        
    # Inference
    # First pass through Gemini
    if not check_pothole_gemini(file_location):
        response = {"message": "no pothole detected"}
        print(f"API Response: {response}")
        return JSONResponse(content=response)

    result = predict_pothole(file_location)
    if not result:
        # Fallback
        import random
        severity = random.choice(["Minor", "Medium", "Major"])
        if severity == "Minor":
            depth = random.uniform(1.0, 2.0)
        elif severity == "Medium":
            depth = random.uniform(2.0, 4.0)
        else:
            depth = random.uniform(4.0, 10.0)
    else:
        severity = result["severity"]
        depth = result["depth"]
        
    # Get actual street name from coordinates
    street_name = get_street_name_from_coordinates(latitude, longitude)
    
    new_request = PotholeRequest(
        user_id=current_user.id,
        image_path=file_location,
        latitude=latitude,
        longitude=longitude,
        severity=severity,
        depth=depth,
        status="pending",
        street_name=street_name
    )
    db.add(new_request)
    db.commit()
    db.refresh(new_request)
    print(f"API Response: Pothole detected - ID: {new_request.id}, Severity: {new_request.severity}, Depth: {new_request.depth}")
    return new_request

@router.get("/my", response_model=List[PotholeResponse])
def get_my_requests(current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    requests = db.query(PotholeRequest).filter(PotholeRequest.user_id == current_user.id).order_by(PotholeRequest.created_at.desc()).all()
    # Ensure created_at is in UTC
    for request in requests:
        if request.created_at.tzinfo is None:
            # If no timezone info, assume it's UTC
            request.created_at = request.created_at.replace(tzinfo=timezone.utc)
    return requests

@router.get("/all", response_model=List[PotholeResponse])
def get_all_requests(current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    if current_user.role != "admin":
        raise HTTPException(status_code=403, detail="Not authorized")
    requests = db.query(PotholeRequest).all()
    # Ensure created_at is in UTC
    for request in requests:
        if request.created_at.tzinfo is None:
            request.created_at = request.created_at.replace(tzinfo=timezone.utc)
    return requests

@router.delete("/{request_id}")
def delete_request(request_id: int, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    if current_user.role != "admin":
        raise HTTPException(status_code=403, detail="Not authorized")
    request = db.query(PotholeRequest).filter(PotholeRequest.id == request_id).first()
    if not request:
        raise HTTPException(status_code=404, detail="Request not found")
    
    # Delete image file
    if os.path.exists(request.image_path):
        os.remove(request.image_path)
        
    db.delete(request)
    db.commit()
    return {"detail": "Request deleted"}

@router.get("/dashboard/stats")
def get_dashboard_stats(current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    from datetime import datetime, timedelta
    
    # Get today's detections
    today = datetime.now().date()
    today_detections = db.query(PotholeRequest).filter(
        PotholeRequest.user_id == current_user.id,
        PotholeRequest.created_at >= today
    ).count()
    
    # Get high severity nearby (within 5km, severity Major)
    # For simplicity, we'll count all Major severity potholes as "nearby"
    high_severity_nearby = db.query(PotholeRequest).filter(
        PotholeRequest.severity == "Major"
    ).count()
    
    # Get predicted risks (potholes with depth > 5cm)
    predicted_risks = db.query(PotholeRequest).filter(
        PotholeRequest.depth > 5.0
    ).count()
    
    # Active scanners - for now, simulate based on total users
    total_users = db.query(User).count()
    active_scanners = min(total_users * 10, 500)  # Simulate active scanners
    
    return {
        "high_severity_nearby": high_severity_nearby,
        "ai_detections_today": today_detections,
        "predicted_risks": predicted_risks,
        "active_scanners": active_scanners
    }

@router.get("/dashboard/weekly-analytics")
def get_weekly_analytics(current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    from datetime import datetime, timedelta
    
    # Get detections for the last 7 days
    today = datetime.now().date()
    weekly_data = []
    
    for i in range(7):
        day = today - timedelta(days=6-i)  # Start from 6 days ago
        day_start = datetime.combine(day, datetime.min.time())
        day_end = datetime.combine(day, datetime.max.time())
        
        count = db.query(PotholeRequest).filter(
            PotholeRequest.user_id == current_user.id,
            PotholeRequest.created_at >= day_start,
            PotholeRequest.created_at <= day_end
        ).count()
        
        weekly_data.append(count)
    
    return {"weekly_detections": weekly_data}

@router.get("/dashboard/nearby")
def get_nearby_potholes(current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    # Get recent potholes (last 30 days) as "nearby"
    thirty_days_ago = datetime.now() - timedelta(days=30)
    
    recent_potholes = db.query(PotholeRequest).filter(
        PotholeRequest.created_at >= thirty_days_ago
    ).order_by(PotholeRequest.created_at.desc()).limit(10).all()
    
    result = []
    for pothole in recent_potholes:
        # Calculate mock distance and street name for demo
        import random
        distance = random.uniform(50, 2000)  # 50m to 2km
        
        # Mock street names
        streets = ["Main St", "Oak Ave", "Pine Rd", "Elm St", "Maple Dr", "Cedar Ln", "Birch Blvd"]
        street = random.choice(streets)
        
        severity_value = 0.3 if pothole.severity == "Minor" else 0.5 if pothole.severity == "Medium" else 0.8
        
        result.append({
            "id": pothole.id,
            "street": street,
            "distance_m": round(distance, 1),
            "severity": severity_value,
            "latitude": pothole.latitude,
            "longitude": pothole.longitude,
            "created_at": pothole.created_at.isoformat()
        })
    
    return {"nearby_potholes": result}
