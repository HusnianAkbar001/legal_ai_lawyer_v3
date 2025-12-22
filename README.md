# LegalAI Project Setup Guide

This guide explains how to set up and run the **LegalAI** project on **Windows**. The project consists of a **Flask backend**, a **Celery worker**, and a **web-based frontend using Node.js + Capacitor**.

---

## Prerequisites

Make sure the following tools are installed:

* **Python 3.10 or higher**
* **pip**
* **Git**
* **Docker Desktop** (required for Redis)
* **Node.js (LTS version)**
* **Android Studio** (Android SDK required for Capacitor Android builds)

---

## Backend Setup (Flask)

### First-Time Setup

1. Open a terminal and navigate to the backend directory:

```bash
cd legalai-backend
```

2. Create a virtual environment:

```bash
python -m venv venv
```
```bash
C:\Users\Zbook\AppData\Local\Programs\Python\Python310\python.exe -m venv venv
```

3. Activate the virtual environment (Windows):

```bash
venv\Scripts\activate
```

4. Install backend dependencies:

```bash
pip install -r requirements.txt
```

5. Apply database migrations:

```bash
flask db upgrade
```

6. Start the backend server:

```bash
python run.py
```

---

### Subsequent Runs (Backend)

```bash
cd legalai-backend
```
```bash
venv\Scripts\activate
```
```bash
python run.py
```

---

## Celery Worker Setup

> **Important:** Ensure **Docker Desktop is running** and **Redis is active** before starting Celery.

```bash
cd legalai-backend
```
```bash
venv\Scripts\activate
```
```bash
celery -A app.tasks.celery_app:celery worker --loglevel=info --pool=solo
```

---

## Frontend Setup (Node.js + Capacitor)

### First-Time Setup

In legalai-Frontend\src\lib\api.ts Change Your Address in API_BASE_URL:
1. Navigate to the frontend directory:

```bash
cd legalai-frontend
```

2. Install Node.js dependencies:

```bash
npm install
```

3. Initialize Capacitor (only required once):

```bash
npx cap init
```

4. Add supported platforms:

```bash
npx cap add android
```
```bash
npx cap add ios
```

5. Build the mobile application and sync with Capacitor:

```bash
npm run build
```
```bash
npx cap sync
```

6. Run the application:

```bash
npx cap run android
```
```bash
npx cap run ios
```

---

### Subsequent Runs (Frontend)

```bash
cd legalai-frontend
```
```bash
npx cap run android
```
```bash
npx cap run ios
```

---

## Notes

* Backend, Celery worker, and Frontend must be run in **separate terminals**.
* Ensure `.env` files are correctly configured.
* Celery tasks will not execute if Redis is not running.

---

## Recommended Startup Order

1. Backend Server
2. Celery Worker
3. Frontend Application

Following this order helps prevent runtime and dependency issues.
