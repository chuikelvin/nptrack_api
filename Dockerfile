# Use OpenJDK 8 as base image (compatible with most Java applications)
FROM openjdk:8-jre-alpine

# Install bash and envsubst for environment variable substitution
RUN apk add --no-cache bash gettext

# Set working directory
WORKDIR /app

# Copy the JAR file
COPY NPTrack.jar /app/NPTrack.jar

# Copy configuration directory
COPY appconfig/ /app/appconfig/

# Create logs directory
RUN mkdir -p /app/logs

# Create startup script
RUN echo '#!/bin/bash' > /app/start.sh && \
    echo 'envsubst < /app/appconfig/configurations-docker.properties > /app/appconfig/configurations.properties' >> /app/start.sh && \
    echo 'java -jar NPTrack.jar' >> /app/start.sh && \
    chmod +x /app/start.sh

# Expose the port from configuration (6446)
EXPOSE 6446

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:6446/health || exit 1

# Run the application with environment variable substitution
CMD ["/app/start.sh"] 