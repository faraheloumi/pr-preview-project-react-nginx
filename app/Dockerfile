FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm install -g vite
RUN npm ci
COPY . .
RUN npm run build


FROM nginx:alpine
WORKDIR /usr/share/nginx/html
COPY --from=builder /app/dist ./
EXPOSE 80
