# Use the Kubeflow Code-Server base image
FROM kubeflownotebookswg/codeserver:latest

# Switch to root to install packages and make modifications
USER root

# Install NGINX
RUN apt-get update && apt-get install -y nginx && apt-get clean && rm -rf /var/lib/apt/lists/*

# Configure NGINX to serve on port 8080 instead of 8888 to avoid conflicts
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

# Create the nginx service in the correct location
RUN mkdir -p /etc/services.d/nginx

# Create the run script with the correct format
RUN echo '#!/bin/execlineb -P\n\
nginx -g "daemon off;"\n\
' > /etc/services.d/nginx/run \
&& chmod +x /etc/services.d/nginx/run

# Expose both ports
EXPOSE 8888 8080

# Switch back to non-root user
USER $NB_UID

# Keep the original entrypoint
ENTRYPOINT ["/init"]
