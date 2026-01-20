from fastapi import FastAPI
from fastapi.staticfiles import StaticFiles
from database import engine, Base
from routers import auth, potholes
import os
from fastapi.middleware.cors import CORSMiddleware

# Create tables
Base.metadata.create_all(bind=engine)

app = FastAPI(title="Pothole Detection System")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Mount uploads directory
os.makedirs("uploads", exist_ok=True)
app.mount("/uploads", StaticFiles(directory="uploads"), name="uploads")

app.include_router(auth.router)
app.include_router(potholes.router)

@app.get("/")
def read_root():
    return {"message": "Welcome to Pothole Detection System API"}
