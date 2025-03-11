# Use the Kubeflow Code-Server base image
FROM kubeflownotebookswg/codeserver:latest

# Switch to root to install packages and make modifications
USER root

# Install NGINX
RUN apt-get update && apt-get install -y nginx && apt-get clean && rm -rf /var/lib/apt/lists/*

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

# Copy your web app files
COPY . /usr/share/nginx/html

# Modify the code-server service to run nginx instead
RUN cat > /etc/services.d/code-server/run << 'EOF'
#!/bin/execlineb -P
nginx -g "daemon off;"
EOF

RUN chmod +x /etc/services.d/code-server/run

# Expose port 8888
EXPOSE 8888

# Switch back to non-root user
USER $NB_UID

# Keep the original entrypoint
ENTRYPOINT ["/init"]
