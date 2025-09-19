# Stage 1 : build Vite/React
FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm install -g vite
RUN npm ci
COPY . .
RUN npm run build

# Stage 2 : NGINX
FROM nginx:stable-alpine
RUN rm -rf /usr/share/nginx/html/*
COPY --from=builder /app/dist /usr/share/nginx/html
COPY ./nginx/conf.d /etc/nginx/conf.d
COPY ./nginx/sites-enabled /etc/nginx/sites-enabled
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
