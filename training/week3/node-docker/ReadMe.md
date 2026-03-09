# 📚 Student Management System  
## Full Stack Multi-Tier Dockerized Application

This project demonstrates a **production-style 3-tier architecture** using:

- 🎨 Frontend – Vite + Nginx
- 🚀 Backend – Node.js (Express)
- 🛢 MySQL – Persistent Database
- 🔴 Redis – Caching Layer
- 🐳 Docker & Docker Compose – Containerization

---

# 🏗️ Architecture Overview

User → Frontend (Nginx :80) → Backend (Node.js :3000)
                                        ↓
                                 Redis (Cache Layer)
                                        ↓
                                 MySQL (Database)

---

# 🔄 Complete Application Flow

## 1️⃣ Read Operation (GET /students)

Step 1: User accesses frontend  
Step 2: Frontend calls `/api/students`  
Step 3: Backend checks Redis  

### 🔥 Cache HIT
- Redis returns cached data
- MySQL is NOT queried
- Faster response

### ❄ Cache MISS
- Backend queries MySQL
- MySQL returns data
- Backend stores data in Redis
- Response sent to frontend

---

## 2️⃣ Write Operation (POST /students)

Step 1: Insert data into MySQL  
Step 2: Clear Redis cache  
Step 3: Next GET refreshes cache  

This ensures cache consistency.

---

# 📁 Project Structure

```
project-root/
│
├── frontend/
│   ├── Dockerfile
│   ├── nginx/
│   │   └── nginx.conf
│   └── (Vite source files)
│
├── backend/
│   ├── Dockerfile
│   ├── .env
│   └── (Node.js source files)
│
├── init.sql
├── docker-compose.yml
└── README.md
```

---

# 🐳 Backend Dockerfile

```dockerfile
FROM node:20-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
EXPOSE 3000
CMD ["npm", "start"]
```

---

# 🎨 Frontend Dockerfile (Multi-Stage Build)

```dockerfile
FROM node:20-alpine as builder
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
RUN npm run build

FROM nginx:alpine
COPY --from=builder /app/dist /usr/share/nginx/html
COPY nginx/nginx.conf /etc/nginx/nginx.conf
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

---

# 🗄️ Database Initialization

## init.sql

```sql
CREATE TABLE IF NOT EXISTS students (
 id INT AUTO_INCREMENT PRIMARY KEY,
 name VARCHAR(255) NOT NULL,
 age INT NOT NULL,
 class VARCHAR(100) NOT NULL,
 created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

This runs automatically when MySQL container starts.

---

# 🧩 Docker Compose Configuration

## docker-compose.yml

```yaml
version: '3.8'

services:

  frontend:
    build:
      context: ./frontend
      dockerfile: Dockerfile
    container_name: frontend
    ports:
      - "80:80"
    depends_on:
      - backend

  backend:
    build:
      context: ./backend
      dockerfile: Dockerfile
    container_name: backend
    ports:
      - "3000:3000"
    env_file:
      - ./backend/.env
    depends_on:
      - redis
      - mysql

  mysql:
    image: mysql:8.0
    container_name: mysql
    environment:
      MYSQL_ROOT_PASSWORD: admin123
      MYSQL_DATABASE: schooldb
      MYSQL_USER: admin
      MYSQL_PASSWORD: admin123
    ports:
      - "3306:3306"
    volumes:
      - ./mysql_data:/var/lib/mysql
      - ./init.sql:/docker-entrypoint-initdb.d/init.sql

  redis:
    image: redis:alpine
    container_name: redis
    ports:
      - "6379:6379"
    volumes:
      - ./redis_data:/data
```

---

# 🔐 Environment Variables

## Backend `.env`

```
DB_HOST=mysql
DB_USER=admin
DB_PASSWORD=admin123
DB_NAME=schooldb
REDIS_URL=redis://redis:6379
```

Important:
- `mysql` and `redis` are service names in Docker network.

---

## Frontend `.env`

```
VITE_API_URL=http://<server-ip>/api
```

Replace `<server-ip>` with:

- localhost (local machine)
- Public IP (cloud server)

Example:

```
VITE_API_URL=http://localhost/api
```

---

# ▶️ Step-by-Step Setup Guide

## Step 1: Clone Repository

```
git clone <your-repo-url>
cd project-root
```

---

## Step 2: Build & Start Containers

```
docker-compose up --build
```

This will:

- Build frontend & backend images
- Start MySQL & Redis
- Initialize database
- Create Docker network

---

## Step 3: Access Application

Frontend:
```
http://localhost
```

Backend:
```
http://localhost:3000
```

---

# 🛑 Stop Containers

```
docker-compose down
```

Remove volumes also:

```
docker-compose down -v
```

---

# 💾 Data Persistence

- MySQL data → ./mysql_data
- Redis data → ./redis_data

Data remains even after restart.

---

# 🧠 What This Project Demonstrates

- 3-Tier Architecture
- Docker Networking
- Multi-Stage Builds
- Redis Caching Pattern
- Cache Hit / Cache Miss Flow
- Database Initialization
- Persistent Volumes
- Environment Configuration

---

# 🚀 Production Recommendations

- Do NOT expose MySQL & Redis publicly
- Use HTTPS
- Add health checks
- Use Docker secrets
- Add CI/CD pipeline
- Use reverse proxy for SSL termination

---

# 👨‍💻 Author

Built for DevOps & Docker Multi-Container Architecture Learning by Rajcosiva.