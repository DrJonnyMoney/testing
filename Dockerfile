# Use the Kubeflow Code-Server base image
FROM kubeflownotebookswg/codeserver:latest

# Switch to root to install packages and make modifications
USER root

# Install NGINX
RUN apt-get update && apt-get install -y nginx && apt-get clean && rm -rf /var/lib/apt/lists/*

# Configure NGINX to serve on port 8888 (same as code-server used)
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

# Copy your web app files
COPY . /usr/share/nginx/html

# Remove the code-server service - check both locations
RUN rm -rf /etc/services.d/code-server /etc/s6/services.d/code-server || true

# Create the nginx service in the correct location for s6-overlay
RUN mkdir -p /etc/services.d/nginx

# Create the run script with the correct format
RUN echo '#!/bin/execlineb -P\nnginx -g "daemon off;"' > /etc/services.d/nginx/run && \
    chmod +x /etc/services.d/nginx/run

# Create a setup script that runs at container start to ensure the runtime service directory exists
RUN mkdir -p /etc/cont-init.d && \
    echo '#!/bin/bash\nmkdir -p /run/s6/legacy-services/nginx\ncp /etc/services.d/nginx/run /run/s6/legacy-services/nginx/\nchmod +x /run/s6/legacy-services/nginx/run' > /etc/cont-init.d/01-setup-nginx-service && \
    chmod +x /etc/cont-init.d/01-setup-nginx-service

# Expose port 8888 (same as what code-server was using)
EXPOSE 8888

# Switch back to non-root user
USER $NB_UID

# Keep the original entrypoint
ENTRYPOINT ["/init"]
