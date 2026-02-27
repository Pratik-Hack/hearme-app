import os
import json
import uuid
import random
import asyncio
from datetime import datetime, timedelta
from typing import Optional

from fastapi import FastAPI, UploadFile, File, Form, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import StreamingResponse
from pydantic import BaseModel
from dotenv import load_dotenv
from groq import Groq
from langchain_core.prompts import ChatPromptTemplate, MessagesPlaceholder
from langchain_core.messages import HumanMessage, AIMessage
from langchain_groq import ChatGroq

load_dotenv()

app = FastAPI(title="HearMe Chatbot", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ── Clients ──────────────────────────────────────────────────────────────────
groq_client = Groq(api_key=os.getenv("GROQ_API_KEY"))

llm = ChatGroq(
    model="llama-3.3-70b-versatile",
    api_key=os.getenv("GROQ_API_KEY"),
    temperature=0.7,
    max_tokens=1024,
)

llm_streaming = ChatGroq(
    model="llama-3.1-8b-instant",
    api_key=os.getenv("GROQ_API_KEY"),
    temperature=0.7,
    max_tokens=1024,
    streaming=True,
)

# ── In-memory stores ────────────────────────────────────────────────────────
session_histories: dict[str, list] = {}
vitals_sessions: dict[str, dict] = {}
vitals_alerts: list[dict] = []
mental_health_notifications: list[dict] = []

# ── Medical Knowledge Base ──────────────────────────────────────────────────
MEDICAL_DATA = {
    "skin_diseases": {
        "eczema": {"symptoms": ["itchy skin", "red patches", "dry skin", "inflammation"], "severity": "moderate", "advice": "Use moisturizers, avoid triggers, consider topical corticosteroids"},
        "psoriasis": {"symptoms": ["scaly patches", "red skin", "itching", "thick silvery scales"], "severity": "moderate", "advice": "Phototherapy, topical treatments, systemic medications for severe cases"},
        "acne": {"symptoms": ["pimples", "blackheads", "whiteheads", "oily skin"], "severity": "mild", "advice": "Gentle cleansing, benzoyl peroxide, retinoids, consult dermatologist if severe"},
        "dermatitis": {"symptoms": ["skin rash", "blisters", "itching", "swelling"], "severity": "mild-moderate", "advice": "Identify and avoid allergens, use antihistamines and topical steroids"},
    },
    "chest_diseases": {
        "asthma": {"symptoms": ["wheezing", "shortness of breath", "chest tightness", "coughing"], "severity": "moderate-severe", "advice": "Use inhaler, avoid triggers, seek emergency care for severe attacks"},
        "pneumonia": {"symptoms": ["fever", "cough with phlegm", "chest pain", "difficulty breathing"], "severity": "severe", "advice": "Seek immediate medical care, antibiotics may be needed, rest and fluids"},
        "bronchitis": {"symptoms": ["persistent cough", "mucus production", "fatigue", "chest discomfort"], "severity": "moderate", "advice": "Rest, fluids, humidifier, see doctor if symptoms last >3 weeks"},
        "copd": {"symptoms": ["chronic cough", "shortness of breath", "wheezing", "frequent respiratory infections"], "severity": "severe", "advice": "Quit smoking, bronchodilators, pulmonary rehabilitation, see pulmonologist"},
    },
    "brain_diseases": {
        "migraine": {"symptoms": ["severe headache", "nausea", "sensitivity to light", "visual disturbances"], "severity": "moderate", "advice": "Rest in dark room, OTC pain relievers, preventive medications for frequent migraines"},
        "tension_headache": {"symptoms": ["dull aching head pain", "tightness around forehead", "tenderness in scalp"], "severity": "mild", "advice": "Stress management, OTC pain relievers, adequate sleep, regular exercise"},
        "concussion": {"symptoms": ["headache", "confusion", "dizziness", "nausea", "memory problems"], "severity": "severe", "advice": "Seek immediate medical attention, rest, avoid screens, gradual return to activities"},
        "meningitis": {"symptoms": ["severe headache", "stiff neck", "high fever", "sensitivity to light", "nausea"], "severity": "critical", "advice": "EMERGENCY: Seek immediate medical care. This is potentially life-threatening."},
    },
}

# ── Language Instructions ───────────────────────────────────────────────────
LANGUAGE_INSTRUCTIONS = {
    "en": "Respond in English.",
    "hi": "Respond in Hindi (हिंदी में उत्तर दें).",
    "ta": "Respond in Tamil (தமிழில் பதிலளிக்கவும்).",
    "te": "Respond in Telugu (తెలుగులో సమాధానం ఇవ్వండి).",
    "mr": "Respond in Marathi (मराठीत उत्तर द्या).",
    "bn": "Respond in Bengali (বাংলায় উত্তর দিন).",
    "kn": "Respond in Kannada (ಕನ್ನಡದಲ್ಲಿ ಉತ್ತರಿಸಿ).",
}

# ── Vitals Clinical Scenarios ───────────────────────────────────────────────
CLINICAL_SCENARIOS = {
    "normal": {
        "heart_rate": (65, 85), "systolic": (110, 130), "diastolic": (70, 85),
        "spo2": (96, 99), "temperature": (36.4, 37.2), "respiratory_rate": (14, 18),
    },
    "tachycardia": {
        "heart_rate": (100, 150), "systolic": (130, 160), "diastolic": (85, 100),
        "spo2": (93, 97), "temperature": (36.8, 37.8), "respiratory_rate": (18, 24),
    },
    "hypotension": {
        "heart_rate": (90, 120), "systolic": (70, 95), "diastolic": (45, 65),
        "spo2": (92, 96), "temperature": (36.0, 37.0), "respiratory_rate": (16, 22),
    },
    "hypertensive_crisis": {
        "heart_rate": (85, 110), "systolic": (170, 210), "diastolic": (110, 130),
        "spo2": (94, 98), "temperature": (36.6, 37.4), "respiratory_rate": (18, 26),
    },
    "respiratory_distress": {
        "heart_rate": (100, 130), "systolic": (120, 150), "diastolic": (80, 100),
        "spo2": (85, 92), "temperature": (37.0, 38.5), "respiratory_rate": (24, 35),
    },
    "fever_sepsis": {
        "heart_rate": (100, 140), "systolic": (80, 110), "diastolic": (50, 70),
        "spo2": (90, 95), "temperature": (38.5, 40.5), "respiratory_rate": (22, 30),
    },
    "bradycardia": {
        "heart_rate": (35, 55), "systolic": (90, 115), "diastolic": (60, 80),
        "spo2": (94, 98), "temperature": (36.2, 37.0), "respiratory_rate": (12, 16),
    },
    "cardiac_arrest_warning": {
        "heart_rate": (140, 200), "systolic": (60, 90), "diastolic": (30, 55),
        "spo2": (75, 88), "temperature": (35.5, 37.0), "respiratory_rate": (28, 40),
    },
}

# ── Pydantic Models ─────────────────────────────────────────────────────────

class ChatRequest(BaseModel):
    message: str
    session_id: str = "default"
    language: str = "en"
    medical_context: Optional[str] = None

class VitalsStartRequest(BaseModel):
    patient_id: str
    doctor_id: Optional[str] = None
    scenario: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None

class VitalsTickRequest(BaseModel):
    session_id: str

class RewardRedeemRequest(BaseModel):
    reward_type: str
    language: str = "en"


# ── Helper Functions ────────────────────────────────────────────────────────

def get_session_history(session_id: str) -> list:
    if session_id not in session_histories:
        session_histories[session_id] = []
    return session_histories[session_id]

def generate_vitals(scenario: str, tick: int) -> dict:
    ranges = CLINICAL_SCENARIOS.get(scenario, CLINICAL_SCENARIOS["normal"])
    noise = min(tick * 0.5, 10)

    def jitter(low, high):
        mid = (low + high) / 2
        spread = (high - low) / 2 + noise
        return round(random.uniform(mid - spread, mid + spread), 1)

    return {
        "heart_rate": max(30, min(220, jitter(*ranges["heart_rate"]))),
        "systolic": max(50, min(250, jitter(*ranges["systolic"]))),
        "diastolic": max(30, min(150, jitter(*ranges["diastolic"]))),
        "spo2": max(60, min(100, jitter(*ranges["spo2"]))),
        "temperature": max(34, min(42, jitter(*ranges["temperature"]))),
        "respiratory_rate": max(8, min(50, jitter(*ranges["respiratory_rate"]))),
        "timestamp": datetime.utcnow().isoformat(),
    }

def check_vitals_anomalies(session: dict, vitals: dict) -> list:
    alerts = []
    history = session.get("history", [])

    thresholds = {
        "heart_rate": {"critical_low": 40, "critical_high": 160, "high": 120, "low": 50},
        "systolic": {"critical_low": 70, "critical_high": 190, "high": 160, "low": 85},
        "diastolic": {"critical_low": 40, "critical_high": 120, "high": 100, "low": 55},
        "spo2": {"critical_low": 85, "low": 92},
        "temperature": {"critical_high": 40, "high": 38.5, "critical_low": 35, "low": 35.5},
        "respiratory_rate": {"critical_high": 35, "high": 25, "critical_low": 8, "low": 10},
    }

    for vital_type, limits in thresholds.items():
        value = vitals.get(vital_type)
        if value is None:
            continue

        severity = None
        message = None

        if "critical_high" in limits and value >= limits["critical_high"]:
            severity = "critical"
            message = f"CRITICAL: {vital_type.replace('_', ' ').title()} at {value} — dangerously high!"
        elif "critical_low" in limits and value <= limits["critical_low"]:
            severity = "critical"
            message = f"CRITICAL: {vital_type.replace('_', ' ').title()} at {value} — dangerously low!"
        elif "high" in limits and value >= limits["high"]:
            severity = "high"
            message = f"HIGH: {vital_type.replace('_', ' ').title()} at {value} — above normal range."
        elif "low" in limits and value <= limits["low"]:
            severity = "medium"
            message = f"WARNING: {vital_type.replace('_', ' ').title()} at {value} — below normal range."

        # Trend-based prediction (preventive alert)
        if len(history) >= 3 and severity is None:
            recent_values = [h.get(vital_type, value) for h in history[-3:]]
            trend = recent_values[-1] - recent_values[0]
            predicted = value + trend

            if "critical_high" in limits and predicted >= limits["critical_high"]:
                severity = "medium"
                message = f"TREND: {vital_type.replace('_', ' ').title()} trending toward critical ({value} → predicted {round(predicted, 1)})"
            elif "critical_low" in limits and predicted <= limits["critical_low"]:
                severity = "medium"
                message = f"TREND: {vital_type.replace('_', ' ').title()} trending toward critical ({value} → predicted {round(predicted, 1)})"

        if severity and message:
            alert = {
                "id": str(uuid.uuid4()),
                "session_id": session["session_id"],
                "patient_id": session["patient_id"],
                "patient_name": session.get("patient_name", "Unknown"),
                "doctor_id": session.get("doctor_id"),
                "vital_type": vital_type,
                "current_value": value,
                "predicted_value": round(value + (vitals.get(vital_type, value) - value), 1),
                "severity": severity,
                "message": message,
                "latitude": session.get("latitude"),
                "longitude": session.get("longitude"),
                "timestamp": datetime.utcnow().isoformat(),
                "read": False,
                "doctor_notified": session.get("doctor_id") is not None,
                "emergency_dispatched": severity == "critical",
            }
            alerts.append(alert)
            vitals_alerts.append(alert)

    return alerts


# ── Routes ──────────────────────────────────────────────────────────────────

@app.get("/health")
async def health():
    return {"status": "ok", "service": "hearme-chatbot"}


# ── Chat (non-streaming) ───────────────────────────────────────────────────

@app.post("/chat")
async def chat(req: ChatRequest):
    try:
        history = get_session_history(req.session_id)
        lang_instruction = LANGUAGE_INSTRUCTIONS.get(req.language, LANGUAGE_INSTRUCTIONS["en"])

        system_template = f"""You are a highly capable, conversational medical triage assistant for HearMe.
Your role is to help users understand their symptoms, provide general health guidance, and advise when to see a doctor.

IMPORTANT RULES:
1. Always be empathetic and supportive.
2. Never diagnose — only provide general information.
3. For severe symptoms, always advise seeking immediate medical attention.
4. {lang_instruction}

MEDICAL KNOWLEDGE BASE:
{json.dumps(MEDICAL_DATA, indent=2)}
"""
        if req.medical_context:
            system_template += f"\n\nPatient Context: {req.medical_context}"

        prompt = ChatPromptTemplate.from_messages([
            ("system", system_template),
            MessagesPlaceholder(variable_name="history"),
            ("human", "{input}"),
        ])

        chain = prompt | llm
        response = chain.invoke({"input": req.message, "history": history})

        history.append(HumanMessage(content=req.message))
        history.append(AIMessage(content=response.content))

        # Keep history manageable
        if len(history) > 20:
            session_histories[req.session_id] = history[-20:]

        return {"response": response.content, "session_id": req.session_id}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# ── Chat (streaming SSE) ───────────────────────────────────────────────────

@app.post("/chat/stream")
async def chat_stream(req: ChatRequest):
    async def event_generator():
        try:
            history = get_session_history(req.session_id)
            lang_instruction = LANGUAGE_INSTRUCTIONS.get(req.language, LANGUAGE_INSTRUCTIONS["en"])

            system_template = f"""You are a highly capable, conversational medical triage assistant for HearMe.
Your role is to help users understand their symptoms, provide general health guidance, and advise when to see a doctor.

IMPORTANT RULES:
1. Always be empathetic and supportive.
2. Never diagnose — only provide general information.
3. For severe symptoms, always advise seeking immediate medical attention.
4. {lang_instruction}

MEDICAL KNOWLEDGE BASE:
{json.dumps(MEDICAL_DATA, indent=2)}
"""
            if req.medical_context:
                system_template += f"\n\nPatient Context: {req.medical_context}"

            prompt = ChatPromptTemplate.from_messages([
                ("system", system_template),
                MessagesPlaceholder(variable_name="history"),
                ("human", "{input}"),
            ])

            chain = prompt | llm_streaming
            full_response = ""

            async for chunk in chain.astream({"input": req.message, "history": history}):
                token = chunk.content
                if token:
                    full_response += token
                    yield f"data: {json.dumps({'token': token})}\n\n"

            history.append(HumanMessage(content=req.message))
            history.append(AIMessage(content=full_response))

            if len(history) > 20:
                session_histories[req.session_id] = history[-20:]

            yield "data: [DONE]\n\n"
        except Exception as e:
            yield f"data: {json.dumps({'error': str(e)})}\n\n"

    return StreamingResponse(event_generator(), media_type="text/event-stream")


# ── Mental Health Analysis ──────────────────────────────────────────────────

@app.post("/mental-health/analyze")
async def analyze_mental_health(
    audio: UploadFile = File(...),
    patient_id: str = Form(...),
    patient_name: str = Form(...),
    doctor_id: Optional[str] = Form(None),
    language: str = Form("en"),
):
    try:
        # Save audio temporarily
        audio_bytes = await audio.read()
        temp_path = f"/tmp/mental_health_{uuid.uuid4()}.m4a"
        with open(temp_path, "wb") as f:
            f.write(audio_bytes)

        # Transcribe with Groq Whisper
        with open(temp_path, "rb") as audio_file:
            transcription = groq_client.audio.transcriptions.create(
                file=("audio.m4a", audio_file),
                model="whisper-large-v3-turbo",
                language=language if language != "en" else None,
            )

        transcript = transcription.text
        lang_instruction = LANGUAGE_INSTRUCTIONS.get(language, LANGUAGE_INSTRUCTIONS["en"])

        # Clean up temp file
        try:
            os.remove(temp_path)
        except:
            pass

        # User-facing empathetic response
        user_prompt = f"""You are a compassionate mental health companion for HearMe.
A user just shared their feelings. Here's their transcription:

"{transcript}"

Provide a warm, empathetic response. Acknowledge their feelings, offer supportive words, and suggest healthy coping strategies.
Keep it concise (3-5 sentences). {lang_instruction}"""

        user_response = llm.invoke(user_prompt)

        # Doctor-facing clinical report
        doctor_report = None
        urgency = "low"
        if doctor_id:
            doctor_prompt = f"""You are a clinical mental health analyst for HearMe.
Analyze this patient's mental health check-in transcription and provide a clinical summary for their doctor.

Patient: {patient_name}
Transcription: "{transcript}"

Provide:
1. Brief clinical summary (2-3 sentences)
2. Key concerns identified
3. Recommended follow-up actions
4. Urgency level: low, moderate, or high

Format as a professional clinical note. Respond in English."""

            doctor_response = llm.invoke(doctor_prompt)
            doctor_report = doctor_response.content

            # Determine urgency from keywords
            report_lower = doctor_report.lower()
            if any(w in report_lower for w in ["high urgency", "urgent", "crisis", "suicidal", "self-harm", "emergency"]):
                urgency = "high"
            elif any(w in report_lower for w in ["moderate urgency", "moderate", "concerning", "anxiety", "depression"]):
                urgency = "moderate"

            # Store notification for doctor
            notification = {
                "id": str(uuid.uuid4()),
                "doctor_id": doctor_id,
                "patient_id": patient_id,
                "patient_name": patient_name,
                "clinical_report": doctor_report,
                "urgency": urgency,
                "transcript": transcript,
                "timestamp": datetime.utcnow().isoformat(),
                "read": False,
            }
            mental_health_notifications.append(notification)

        return {
            "user_response": user_response.content,
            "transcript": transcript,
            "doctor_report": doctor_report,
            "urgency": urgency,
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# ── Mental Health Notifications ─────────────────────────────────────────────

@app.get("/mental-health/notifications/{doctor_id}")
async def get_mental_health_notifications(doctor_id: str):
    notifs = [n for n in mental_health_notifications if n["doctor_id"] == doctor_id]
    notifs.sort(key=lambda x: x["timestamp"], reverse=True)
    return {"notifications": notifs}


@app.put("/mental-health/notifications/{notification_id}/read")
async def mark_notification_read(notification_id: str):
    for n in mental_health_notifications:
        if n["id"] == notification_id:
            n["read"] = True
            return {"message": "Marked as read"}
    raise HTTPException(status_code=404, detail="Notification not found")


# ── Rewards ─────────────────────────────────────────────────────────────────

@app.post("/rewards/redeem")
async def redeem_reward(req: RewardRedeemRequest):
    lang_instruction = LANGUAGE_INSTRUCTIONS.get(req.language, LANGUAGE_INSTRUCTIONS["en"])

    prompts = {
        "guided_meditation": f"""Create a personalized guided meditation script (5-7 minutes).
Include breathing exercises, body scan, and visualization.
Make it calming and suitable for stress relief. {lang_instruction}""",
        "weekly_wellness": f"""Generate a comprehensive weekly wellness report with:
1. Mental health tips for the week
2. Nutrition recommendations
3. Exercise suggestions
4. Sleep hygiene tips
5. Mindfulness exercises
Make it actionable and motivating. {lang_instruction}""",
        "premium_health_tips": f"""Provide 10 premium health tips covering:
1. Physical health
2. Mental well-being
3. Nutrition
4. Sleep quality
5. Stress management
Make each tip detailed and evidence-based. {lang_instruction}""",
    }

    prompt = prompts.get(req.reward_type)
    if not prompt:
        raise HTTPException(status_code=400, detail="Invalid reward type")

    try:
        response = llm.invoke(prompt)
        return {"content": response.content, "reward_type": req.reward_type}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# ── Vitals Monitoring ───────────────────────────────────────────────────────

@app.post("/vitals/start")
async def start_vitals(req: VitalsStartRequest):
    session_id = str(uuid.uuid4())
    scenario = req.scenario or random.choice(list(CLINICAL_SCENARIOS.keys()))

    session = {
        "session_id": session_id,
        "patient_id": req.patient_id,
        "doctor_id": req.doctor_id,
        "scenario": scenario,
        "latitude": req.latitude,
        "longitude": req.longitude,
        "tick_count": 0,
        "history": [],
        "started_at": datetime.utcnow().isoformat(),
    }
    vitals_sessions[session_id] = session

    return {
        "session_id": session_id,
        "scenario": scenario,
        "message": "Vitals monitoring session started",
    }


@app.post("/vitals/tick")
async def vitals_tick(req: VitalsTickRequest):
    session = vitals_sessions.get(req.session_id)
    if not session:
        raise HTTPException(status_code=404, detail="Session not found")

    session["tick_count"] += 1
    vitals = generate_vitals(session["scenario"], session["tick_count"])
    session["history"].append(vitals)

    # Keep only last 50 data points
    if len(session["history"]) > 50:
        session["history"] = session["history"][-50:]

    alerts = check_vitals_anomalies(session, vitals)

    return {
        "vitals": vitals,
        "alerts": alerts,
        "tick": session["tick_count"],
    }


@app.delete("/vitals/session/{session_id}")
async def stop_vitals(session_id: str):
    session = vitals_sessions.pop(session_id, None)
    if not session:
        raise HTTPException(status_code=404, detail="Session not found")

    return {
        "message": "Session stopped",
        "session_id": session_id,
        "total_ticks": session["tick_count"],
        "total_alerts": len([a for a in vitals_alerts if a["session_id"] == session_id]),
    }


@app.get("/vitals/alerts/doctor/{doctor_id}")
async def get_doctor_alerts(doctor_id: str):
    alerts = [a for a in vitals_alerts if a.get("doctor_id") == doctor_id]
    alerts.sort(key=lambda x: x["timestamp"], reverse=True)
    return {"alerts": alerts}


@app.get("/vitals/alerts/patient/{patient_id}")
async def get_patient_alerts(patient_id: str):
    alerts = [a for a in vitals_alerts if a["patient_id"] == patient_id]
    alerts.sort(key=lambda x: x["timestamp"], reverse=True)
    return {"alerts": alerts}


@app.put("/vitals/alerts/{alert_id}/read")
async def mark_alert_read(alert_id: str):
    for a in vitals_alerts:
        if a["id"] == alert_id:
            a["read"] = True
            return {"message": "Alert marked as read"}
    raise HTTPException(status_code=404, detail="Alert not found")


# ── Run ─────────────────────────────────────────────────────────────────────

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
