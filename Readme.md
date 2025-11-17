CREATE DATABASE IF NOT EXISTS mystery_manorA CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE mystery_manorA;
SOURCE schema.sql;
SHOW TABLES;
EXIT;

**To run locally 
create a .env file in root directory as 
.env.local
DATABASE_URL=mysql://USER:PASS@localhost:****/mystery_manorA**

# 🕵️ Mystery Manor Game

A full-stack detective mystery game built with Next.js 15, TypeScript, MySQL, and TanStack Query.

## 🚀 Quick Start

### Prerequisites
- Node.js 18+ 
- MySQL 8.0+
- npm or yarn

### Installation

1. **Clone and install dependencies:**


6. **Open http://localhost:3000**

## 🎮 Game Features

- 5 unique rooms with themed mini-games
- Real-time leaderboard with MySQL views
- Player progress tracking
- Score calculation with stored procedures
- Mystery-solving gameplay

## 🛠️ Tech Stack

- **Frontend:** Next.js 15, React 19, TypeScript, Tailwind CSS
- **Backend:** Next.js Route Handlers, MySQL 8.0
- **State:** TanStack Query v5
- **Database:** MySQL with stored procedures, triggers, and views

## 📁 Project Structure


## 🔧 Development

- `npm run dev` - Start dev server
- `npm run build` - Build for production
- `npm run start` - Start production server
- `npm run lint` - Run ESLint

## 📝 License

MIT

rm -rf node_modules package-lock.json
npm install --legacy-peer-deps

npm run dev 
