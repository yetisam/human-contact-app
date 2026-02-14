# Development Setup

## Prerequisites

- **Node.js** 22+ (installed)
- **Flutter** 3.x (installed at `~/.flutter`)
- **PostgreSQL** 17 (running on webdev or via Docker)
- **Redis** 7 (running on webdev or via Docker)
- **Git** + GitHub CLI (`gh`)

## Quick Start

### 1. Clone the repo

```bash
cd /var/www
git clone https://github.com/yetisam/human-contact-app.git
cd human-contact-app
```

### 2. Backend Setup

```bash
cd server

# Install dependencies
npm install

# Configure environment
cp .env.example .env
# Edit .env with your database credentials

# Run database migrations
npx prisma migrate dev

# Generate Prisma client
npx prisma generate

# Seed interest tags
npm run db:seed

# Start dev server
npm run dev
```

The API will be running at `http://localhost:5000`.

### 3. Flutter App Setup

```bash
cd app

# Get dependencies
flutter pub get

# Run on web (for dev)
flutter run -d chrome

# Run on connected device
flutter run

# Run on specific platform
flutter run -d ios
flutter run -d android
```

### 4. Using Docker (optional — for isolated DB/Redis)

If you don't want to use the system PostgreSQL/Redis:

```bash
# From project root
docker compose up -d

# Uses ports 5433 (postgres) and 6380 (redis) to avoid conflicts
# Update .env DATABASE_URL and REDIS_URL accordingly
```

## Project Structure

```
human-contact-app/
├── app/          # Flutter frontend
├── server/       # Node.js backend
├── docs/         # Documentation
└── shared/       # Shared constants
```

## Database

We use Prisma ORM with PostgreSQL.

```bash
# Create a new migration
cd server
npx prisma migrate dev --name description_of_change

# View database in browser
npx prisma studio

# Reset database (deletes all data)
npm run db:reset
```

## Testing

```bash
# Server tests
cd server
npm test

# Flutter tests
cd app
flutter test

# Flutter integration tests
cd app
flutter test integration_test
```

## Environment

- **Dev server (webdev):** `http://localhost:5000` (API), `http://localhost:3000` or `8080` (Flutter web)
- **Database:** PostgreSQL on localhost:5432 (system) or localhost:5433 (Docker)
- **Redis:** localhost:6379 (system) or localhost:6380 (Docker)
- **Persona sandbox:** For ID verification testing

## Useful Commands

```bash
# Check Flutter setup
flutter doctor

# Update Flutter
flutter upgrade

# Analyze Dart code
flutter analyze

# Format Dart code
dart format lib/

# Prisma Studio (visual DB browser)
cd server && npx prisma studio
```
