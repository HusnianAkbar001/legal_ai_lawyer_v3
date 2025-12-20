# LegalAI Project Setup Guide

This guide explains how to set up and run the LegalAI project on Windows. Follow the steps carefully for Backend, Celery, and Frontend.

---

## Backend Setup

### First Time Setup

1. Open a terminal and navigate to the backend directory:

   ```bash
   cd legalai-backend
   ```
2. Create a virtual environment:

   ```bash
   python -m venv venv
   ```
3. Activate the virtual environment:

   ```bash
   venv/Scripts/activate
   ```
4. Apply database migrations:

   ```bash
   flask db upgrade
   ```
5. Install project dependencies:

   ```bash
   pip install -r requirements.txt
   ```
6. Run the backend server:

   ```bash
   python run.py
   ```

### Subsequent Runs

1. Navigate to the backend directory:

   ```bash
   cd legalai-backend
   ```
2. Activate the virtual environment:

   ```bash
   venv/Scripts/activate
   ```
3. Run the backend server:

   ```bash
   python run.py
   ```

---

## Celery Worker Setup

1. Open a new terminal and navigate to the backend directory:

   ```bash
   cd legalai-backend
   ```
2. Activate the virtual environment:

   ```bash
   venv/Scripts/activate
   ```
3. Start the Celery worker:

   ```bash
   celery -A app.tasks.celery_app:celery worker --loglevel=info --pool=solo
   ```

> **Note:** Ensure Docker Desktop is running and Redis is active before starting Celery.

---

## Frontend Setup

### First Time Setup

1. Install Flutter and Dart extensions in VS Code.
2. Navigate to the frontend directory:

   ```bash
   cd legalai-Frontend
   ```
3. Initialize Flutter project:

   ```bash
   flutter create .
   ```
4. Verify Flutter setup:

   ```bash
   flutter doctor
   flutter doctor --android-licenses
   ```
5. Get project dependencies:

   ```bash
   flutter pub get
   ```
6. Run the frontend in Chrome:

   ```bash
   flutter run -d chrome
   ```

### Subsequent Runs

1. Navigate to the frontend directory:

   ```bash
   cd legalai-Frontend
   ```
2. Run on Android device/emulator:

   ```bash
   npx cap run android
   ```
