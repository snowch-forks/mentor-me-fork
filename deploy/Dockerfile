# Stage 1: Build Flutter web app
FROM ghcr.io/cirruslabs/flutter:3.27.1 AS flutter-build

WORKDIR /app
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

COPY . .

# Generate build_info.dart stub (CI normally generates this)
RUN mkdir -p lib/config && echo 'const String buildCommit = "cloud-run";\nconst String buildTimestamp = "cloud-deployed";\nconst String buildBranch = "main";' > lib/config/build_info.dart

# Build runner for JSON serialization
RUN flutter pub run build_runner build --delete-conflicting-outputs 2>/dev/null || true

# Build web app
# Build web app with cloud deployment flag (proxy handles API key server-side)
RUN flutter build web --release --base-href="/" --dart-define=CLOUD_DEPLOYED=true

# Stage 2: Production image with nginx + Node.js proxy
FROM node:20-slim

# Install nginx and supervisor
RUN apt-get update && apt-get install -y --no-install-recommends \
    nginx \
    supervisor \
    && rm -rf /var/lib/apt/lists/*

# Copy Flutter web build
COPY --from=flutter-build /app/build/web /usr/share/nginx/html

# Copy nginx config
COPY deploy/nginx.conf /etc/nginx/sites-available/default

# Set up proxy server
WORKDIR /app/proxy
COPY deploy/proxy-server.js ./server.js
COPY deploy/proxy-package.json ./package.json
RUN npm install --production

# Supervisor config to run both nginx and proxy
COPY deploy/supervisord.conf /etc/supervisor/conf.d/mentorme.conf

EXPOSE 8080

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/mentorme.conf"]
