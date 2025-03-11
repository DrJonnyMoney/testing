# Use the Kubeflow Code-Server base image
FROM kubeflownotebookswg/codeserver:latest

# Switch to root to install packages and make modifications
USER root

# Install NGINX
RUN apt-get update && apt-get install -y nginx && apt-get clean && rm -rf /var/lib/apt/lists/*

# Configure NGINX to serve on a DIFFERENT port (8080) to avoid conflicts with code-server on 8888
RUN echo "server { \
    listen 8080; \
    server_name localhost; \
    location / { \
        root /usr/share/nginx/html; \
        index index.html; \
    } \
    add_header Access-Control-Allow-Origin *; \
}" > /etc/nginx/sites-available/default \
&& ln -sf /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default

# Copy your web app files
COPY . /usr/share/nginx/html

# Set up NGINX as a service in the correct s6-overlay location
RUN mkdir -p /etc/services.d/nginx

# Create the run script with proper format for s6-overlay
RUN echo '#!/usr/bin/with-contenv bash\nexec nginx -g "daemon off;"' > /etc/services.d/nginx/run \
    && chmod +x /etc/services.d/nginx/run

# Create a finish script to ensure proper shutdown
RUN echo '#!/usr/bin/with-contenv bash\nkill -TERM $(cat /var/run/nginx.pid)' > /etc/services.d/nginx/finish \
    && chmod +x /etc/services.d/nginx/finish

# Expose both ports - 8888 for code-server and 8080 for nginx
EXPOSE 8888 8080

# Switch back to non-root user
USER $NB_UID

# Keep the original entrypoint
ENTRYPOINT ["/init"]
