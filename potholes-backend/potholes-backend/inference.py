from ultralytics import YOLO
import random

model = None

def load_model():
    global model
    # Load the model
    model = YOLO("working/runs/yolov8m_pothole_train/weights/best.pt")

def predict_pothole(image_path):
    if model is None:
        load_model()
    
    try:
        results = model(image_path)
        
        # Check if we have any detections
        if not results or len(results[0].boxes) == 0:
            return None

        # Get the highest confidence detection
        box = results[0].boxes[0]
        cls = int(box.cls[0])
        conf = float(box.conf[0])
        
        # Check class names from the model
        class_name = model.names[cls]
        
        # Logic for severity
        severity = "Medium" # Default
        if "minor" in class_name.lower():
            severity = "Minor"
        elif "major" in class_name.lower():
            severity = "Major"
        elif "medium" in class_name.lower():
            severity = "Medium"
        else:
            severity = random.choice(["Minor", "Medium", "Major"])
        
        # Calculate depth based on severity
        if severity == "Minor":
            depth = random.uniform(1.0, 2.0) # inches
        elif severity == "Medium":
            depth = random.uniform(2.0, 4.0)
        else: # Major
            depth = random.uniform(4.0, 10.0)
            
        return {
            "severity": severity,
            "depth": round(depth, 2),
            "confidence": conf,
            "class": class_name
        }
    except Exception as e:
        print(f"Inference error: {e}")
        return None
