# Build stage
FROM node:20-slim AS builder

WORKDIR /app

# 의존성 파일 복사
COPY package*.json ./
COPY tsconfig.json ./

# 의존성 설치
RUN npm install

# 소스 복사 및 빌드
COPY src ./src
RUN npm run build

# Production stage
FROM node:20-slim

WORKDIR /app

# 프로덕션 의존성만 설치
COPY package*.json ./
RUN npm install --omit=dev

# 빌드된 파일 복사
COPY --from=builder /app/dist ./dist

# 설정 디렉토리 생성
RUN mkdir -p /app/.google-workspace

# 볼륨 마운트 포인트
VOLUME ["/app/.google-workspace"]

# 환경 변수
ENV GOOGLE_CONFIG_DIR=/app/.google-workspace

# 실행
CMD ["node", "dist/index.js"]
