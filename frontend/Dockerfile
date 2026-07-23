# Stage 1: Build the React app
FROM node:20-alpine AS build

# Must be passed as a build ARG, not a runtime env var — CRA bakes
# REACT_APP_* values into the static bundle at `npm run build` time.
ARG REACT_APP_API_BASE_URL
ENV REACT_APP_API_BASE_URL=${REACT_APP_API_BASE_URL}

ARG APP_VERSION=dev
LABEL version=${APP_VERSION}

WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
RUN npm run build

# Stage 2: Serve with Nginx
FROM nginx:1.27-alpine

COPY --from=build /app/build /usr/share/nginx/html

COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

HEALTHCHECK --interval=10s --timeout=3s --retries=5 \
  CMD wget -q --spider http://127.0.0.1:80 || exit 1

CMD ["nginx", "-g", "daemon off;"]