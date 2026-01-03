# LegalAI Project Setup Guide (Windows)

This document explains the exact, step-by-step procedure to set up and run the **LegalAI** project on **Windows**.
The project consists of a **Flask backend**, **Celery workers**, and a **React-based mobile application using Capacitor**.

> **Important:**
>
> * Backend is implemented in **Flask (Python)**
> * Mobile application is **React + Capacitor**
> * **Flutter / Dart is NOT used**

---

## Prerequisites

Ensure the following are installed on your system:

* Python 3.10 or higher
* pip
* Git
* Docker Desktop (required for Redis)
* Node.js (LTS version)
* Android Studio (Android SDK required for Capacitor Android builds)

---

## Backend Setup (Flask)

### First-Time Setup

1. Navigate to the backend directory:

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

### Subsequent Backend Runs

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

> **Important:** Docker Desktop must be running and Redis must be active before starting Celery.

```bash
cd legalai-backend
```

```bash
venv\Scripts\activate
```

### Celery Worker

```bash
# celery -A app.tasks.celery_app:celery worker --loglevel=info --pool=solo
celery -A app.celery_worker:celery worker --loglevel=info --pool=solo
```

### Celery Beat

```bash
celery -A app.celery_worker.celery beat --loglevel=info
```

---

## Frontend Setup (Node.js + Capacitor)

### First-Time Setup

1. Navigate to the frontend directory:

```bash
cd legalai-frontend
```

2. Install Node.js dependencies:

```bash
npm install
```

3. Initialize Capacitor:

```bash
npx cap init
```

4.Install Capacitor core and CLI:

```bash
npm install @capacitor/core @capacitor/cli
```

5. Install Android platform:

```bash
npm install @capacitor/android
```

```bash
npx cap add android
```

6. Install iOS platform:

```bash
npm install @capacitor/ios
```

```bash
npx cap add ios
```

---

## API Base URL Configuration

Go to the following file:

```
legalai-frontend\src\lib\api.ts
```

Set your API base URL:

```ts
const API_BASE_URL = 'https://unflexible-zora-rostrally.ngrok-free.dev/api/v1';
```

To get your IPv4 address:

```bash
ipconfig
```

Copy the IPv4 Address from **Wireless LAN adapter Wi‑Fi** and paste it into `API_BASE_URL`. You can Also use Ngrok

---

## Android Network Security Configuration

### Create network_security_config.xml

**Location:**

```
android/app/src/main/res/xml/network_security_config.xml
```

```xml
<?xml version="1.0" encoding="utf-8"?>
<network-security-config>

    <!-- HTTPS only (Production + Ngrok) -->
    <base-config cleartextTrafficPermitted="false">
        <trust-anchors>
            <certificates src="system" />
        </trust-anchors>
    </base-config>

    <!-- Ngrok domain explicitly trusted -->
    <domain-config cleartextTrafficPermitted="false">
        <domain includeSubdomains="true">
            unflexible-zora-rostrally.ngrok-free.dev
        </domain>
    </domain-config>

</network-security-config>

```

---

## Update AndroidManifest.xml

**File:**

```
android/app/src/main/AndroidManifest.xml
```

Add the following **below** `android:theme="@style/AppTheme"` and **above** `<activity>`:

```xml
android:networkSecurityConfig="@xml/network_security_config">
```

---

## Capacitor HTTP Plugin Verification

```bash
npm list @capacitor/http
```

---

## Capacitor Configuration

**File:**

```
legalai-frontend\capacitor.config.ts
```

```ts
import type { CapacitorConfig } from '@capacitor/cli';

const config: CapacitorConfig = {
  appId: 'com.LegalLawyerAi.app',
  appName: 'LegalLawyerAi',
  webDir: 'dist',
  server: {
    androidScheme: 'https'
  },
  plugins: {
    CapacitorHttp: {
      enabled: true
    }
  }
};

export default config;
```

---

## Android SDK Configuration

Create the following file:

```
legalai-frontend\android\local.properties
```

Add this line:

```
sdk.dir=C:\\Users\\{Put_Your_User}\\AppData\\Local\\Android\\Sdk
```

---

## Build and Sync Application

```bash
npm run build
```

```bash
npx cap sync
```

## Run Mobile Application

```bash
npx cap run android
```

```bash
npx cap run ios
```

---

## Subsequent Frontend Runs

```bash
cd legalai-frontend
```

```bash
npx cap run android
```

```bash
npx cap open android
```

```bash
npx cap run ios
```

---

## Notes

* Backend, Celery Worker, and Frontend must be run in **separate terminals**
* Redis must be running for Celery tasks
* `.env` files must be correctly configured

---

## Recommended Startup Order

1. Backend Server
2. Celery Worker
3. Frontend Application

Following this sequence prevents runtime and dependency issues.
