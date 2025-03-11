# Use the Kubeflow Code-Server base image
FROM kubeflownotebookswg/codeserver:latest

# Switch to root to install packages and make modifications
USER root

# Install NGINX
RUN apt-get update && apt-get install -y nginx && apt-get clean && rm -rf /var/lib/apt/lists/*

# Remove the built-in code-server service to avoid port conflict on 8888
# Make sure directory exists before removing
RUN if [ -d "/etc/s6/services.d/codeserver" ]; then rm -rf /etc/s6/services.d/codeserver; fi

# Copy your web app files
COPY . /usr/share/nginx/html

# Make sure the directory exists
RUN mkdir -p /usr/share/nginx/html

# Configure NGINX to serve on port 8888
RUN echo "server { \
    listen 8888; \
    server_name localhost; \
    location / { \
        root /usr/share/nginx/html; \
        index index.html; \
    } \
    add_header Access-Control-Allow-Origin *; \
}" > /etc/nginx/sites-available/default \
&& ln -sf /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default

# Set up NGINX as a service in s6-overlay
RUN mkdir -p /etc/s6/services.d/nginx

# Create the run script directly instead of copying
RUN echo '#!/bin/sh\nexec nginx -g "daemon off;"' > /etc/s6/services.d/nginx/run \
    && chmod +x /etc/s6/services.d/nginx/run

# Expose port 8888
EXPOSE 8888

# Switch back to non-root user (NB_UID is set in the base image)
USER $NB_UID

# Use the built-in s6-overlay entrypoint - keep as array format
ENTRYPOINT ["/init"]
