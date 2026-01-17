# LegalAI Project Setup Guide (Windows Only)

This is the authoritative setup guide for this repository.
Stack: Flask API + Celery workers + Flutter app (Android device and Web).

## What This Repo Contains
- Backend: Flask, SQLAlchemy, Alembic migrations, Celery, Redis, PostgreSQL, pgvector
- Frontend: Flutter (Android and Web)

## Prerequisites (Install Once)
1) Python 3.10.x
   - https://www.python.org/downloads/release/python-310/
2) Git
   - https://git-scm.com/download/win
3) Docker Desktop (for Redis container)
   - https://www.docker.com/products/docker-desktop/
4) PostgreSQL 17 + pgAdmin 4
   - https://www.postgresql.org/download/windows/
5) Flutter SDK (stable)
   - https://docs.flutter.dev/get-started/install/windows
6) Android Studio (SDK + platform-tools)
   - https://developer.android.com/studio
7) Google Chrome (for Web)
   - https://www.google.com/chrome/

Verify installs (PowerShell):
```bash
python --version
git --version
docker --version
flutter --version
```

## Repository Setup
If you already have the repo locally, skip this step.
```bash
git clone <REPO_URL>
cd legal_ai_lawyer_v3
```

## PostgreSQL 17 Setup (pgAdmin)
1) Install PostgreSQL 17 with pgAdmin 4.
2) Open pgAdmin 4 and connect to your local server.
3) Create a database user and database.
   - Choose your own values (user, password, database name, port).
4) Note these values because they must match your `.env` file:
   - Host, Port, Database name, Username, Password

## pgvector Installation (PostgreSQL 17, Windows)
This project uses pgvector. You must install the extension before migrations.

1) Download the PostgreSQL 17 Windows build from GitHub:
   - https://github.com/andreiramani/pgvector_pgsql_windows/releases
2) Choose the Windows x64 artifact for PostgreSQL 17.
3) Extract the archive.
4) Copy files into your PostgreSQL 17 installation folder:
   - Copy `pgvector.dll` to:
     `C:\Program Files\PostgreSQL\17\lib\`
   - Copy `vector.control` and all `vector--*.sql` files to:
     `C:\Program Files\PostgreSQL\17\share\extension\`
5) Restart PostgreSQL service:
   - Open `services.msc`
   - Restart `postgresql-x64-17`
6) Enable the extension inside your database:
   - Open pgAdmin Query Tool for your database and run:
```sql
CREATE EXTENSION IF NOT EXISTS vector;
```
7) Verify:
```sql
SELECT extname FROM pg_extension WHERE extname = 'vector';
```

## Redis Setup (Docker)
Run Redis in a container named `Redis`:
```bash
docker pull redis
docker run -d --name Redis -p 6379:6379 redis
docker ps
```

## Backend Setup (Flask)
From the repo root:
```bash
cd legalai-backend
```

### 1) Configure Environment Variables
Open `legalai-backend\.env` and set real values. These are mandatory.

Database (must match pgAdmin):
```
DATABASE_URL=postgresql://<db_user>:<db_password>@localhost:<db_port>/<db_name>
SQLALCHEMY_DATABASE_URI=postgresql://<db_user>:<db_password>@localhost:<db_port>/<db_name>
```

Core:
```
FLASK_ENV=development
SECRET_KEY=<set_a_strong_secret>
```

SMTP (Gmail, mandatory):
```
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
MAIL_USE_TLS=True
SMTP_USER=<your_gmail_address>
SMTP_PASS=<your_gmail_app_password>
EMAIL_FROM=<your_gmail_address>
SUPPORT_INBOX_EMAIL=<support_inbox_address>
FRONTEND_VERIFY_URL=<your_frontend_verify_url>
FRONTEND_RESET_URL=<your_frontend_reset_url>
```

Superadmin (created on startup if not present):
```
SUPERADMIN_EMAIL=<admin_email>
SUPERADMIN_PASSWORD=<admin_password>
```

Redis:
```
REDIS_URL=redis://localhost:6379/0
```

LLM Providers (GroqCloud chat, OpenAI embeddings):
```
CHAT_PROVIDER=groq
CHAT_MODEL=<your_groq_chat_model>
GROQ_API_KEY=<your_groq_api_key>

EMBEDDING_PROVIDER=openai
EMBEDDING_MODEL=text-embedding-3-large
EMBEDDING_DIMENSION=3072
OPENAI_API_KEY=<your_openai_api_key>
```

Optional providers supported by the backend:
- Chat providers: openai, groq, openrouter, deepseek, grok, anthropic
  - Keys: OPENAI_API_KEY, GROQ_API_KEY, OPENROUTER_API_KEY, DEEPSEEK_API_KEY, GROK_API_KEY, ANTHROPIC_API_KEY
- Embedding providers: openai, openrouter, deepseek, grok, groq
  - Keys: OPENAI_API_KEY, OPENROUTER_API_KEY, DEEPSEEK_API_KEY, GROQ_API_KEY, GROK_API_KEY
- Base URLs (optional): OPENAI_BASE_URL, OPENROUTER_BASE_URL, GROQ_BASE_URL

### 2) Create Virtual Environment
```bash
python -m venv venv
```
If you have multiple Python versions:
```bash
py -3.10 -m venv venv
```

Activate:
```bash
venv\Scripts\activate
```

### 3) Install Dependencies
```bash
pip install -r requirements.txt
```

### 4) Run Migrations
```bash
python -m flask --app run.py db upgrade
```

### 5) Start Backend API
```bash
python run.py
```
API health check:
```
http://127.0.0.1:5000/api/v1/health
```
Swagger UI:
```
http://127.0.0.1:5000/docs
```

## Celery Worker and Beat
Keep Redis running before starting Celery.

Worker:
```bash
cd legalai-backend
venv\Scripts\activate
celery -A app.celery_worker:celery worker --loglevel=info --pool=solo
```

Beat:
```bash
cd legalai-backend
venv\Scripts\activate
celery -A app.celery_worker:celery beat --loglevel=info
```

## Frontend Setup (Flutter)
From repo root:
```bash
cd legalai-frontend
```

### 1) Flutter Dependencies
```bash
flutter doctor
flutter pub get
```

### 2) API Base URL
Edit:
```
legalai-frontend\lib\core\constants\app_constants.dart
```

For Android device (physical):
```
static const String apiBaseUrlDev = 'http://<YOUR_PC_IP>:5000/api/v1';
```

For Web (Chrome):
```
static const String apiBaseUrlDev = 'http://127.0.0.1:5000/api/v1';
```

When switching between Android device and Web, update this value.

## Run on Android Device
1) Enable Developer Options and USB Debugging on your phone.
2) Connect the device via USB.
3) Verify the device is detected:
```bash
flutter devices
```
4) Run:
```bash
flutter run -d <device_id>
```

## Run on Web (Chrome)
```bash
flutter run -d chrome
```

## Recommended Startup Order
1) Redis container
2) Backend API
3) Celery worker
4) Celery beat
5) Flutter app (Android or Web)

## Common Checks
- If migrations fail with vector errors, verify pgvector installation and `CREATE EXTENSION vector;`
- If Celery fails to connect, verify the Redis container is running and `REDIS_URL` is correct
- If Android device cannot reach the API, confirm the PC IP in `apiBaseUrlDev` and that the device and PC are on the same network

## Optional Tests
Backend:
```bash
cd legalai-backend
venv\Scripts\activate
pytest
```

Frontend:
```bash
cd legalai-frontend
flutter test
```
