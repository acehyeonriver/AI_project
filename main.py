from fastapi import FastAPI, File, UploadFile
from fastapi.middleware.cors import CORSMiddleware
import cv2
import numpy as np
import mediapipe as mp

app = FastAPI()

# CORS 허용 (Flutter Web 요청 허용)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

pose = mp.solutions.pose.Pose(static_image_mode=True)

@app.post("/pose")
async def get_pose(file: UploadFile = File(...)):
    contents = await file.read()
    image_np = cv2.imdecode(np.frombuffer(contents, np.uint8), cv2.IMREAD_COLOR)
    results = pose.process(cv2.cvtColor(image_np, cv2.COLOR_BGR2RGB))

    keypoints = []
    if results.pose_landmarks:
        for lm in results.pose_landmarks.landmark:
            keypoints.append({
                "x": lm.x,
                "y": lm.y,
                "visibility": lm.visibility
            })
    return {"keypoints": keypoints}
