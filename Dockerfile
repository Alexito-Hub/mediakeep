# Stage 1: Build the Flutter Web App
FROM ubuntu:22.04 AS build-env

# Instalar dependencias necesarias para descargar y compilar Flutter
RUN apt-get update && \
    apt-get install -y curl git unzip xz-utils zip libglu1-mesa && \
    rm -rf /var/lib/apt/lists/*

# Clonar el SDK de Flutter (rama estable)
RUN git clone https://github.com/flutter/flutter.git /usr/local/flutter -b stable

# Configurar el PATH de Flutter
ENV PATH="/usr/local/flutter/bin:/usr/local/flutter/bin/cache/dart-sdk/bin:${PATH}"

# Inicializar Flutter y habilitar el soporte para Web
RUN flutter doctor -v
RUN flutter config --enable-web

# Configurar el directorio de trabajo
WORKDIR /app

# Copiar el pubspec y obtener dependencias temprano (aprovecha caché de Docker)
COPY pubspec.* ./
RUN flutter pub get

# Copiar el resto del código fuente
COPY . .

# Compilar la aplicación para Producción Web
RUN flutter build web --release

# Stage 2: Servir la aplicación utilizando Nginx (ligero)
FROM nginx:alpine

# Copiar los artefactos generados de Flutter Web al directorio de Nginx
COPY --from=build-env /app/build/web /usr/share/nginx/html

# Copiar la configuración personalizada de Nginx
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Reemplazar el puerto de Nginx dinámicamente usando la variable $PORT de Cloud Run al iniciar
CMD sed -i -e 's/$PORT/'"$PORT"'/g' /etc/nginx/conf.d/default.conf && nginx -g 'daemon off;'
