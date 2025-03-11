# Use the Kubeflow Code-Server base image
FROM kubeflownotebookswg/codeserver:latest

# Switch to root to install packages and make modifications
USER root

# Install NGINX
RUN apt-get update && apt-get install -y nginx && apt-get clean && rm -rf /var/lib/apt/lists/*

# Configure NGINX to serve on port 8888 (same port code-server was using)
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

# Remove the code-server service to prevent it from starting
RUN rm -f /etc/services.d/code-server/run

# Create nginx run script with the EXACT same shebang as the code-server script
RUN mkdir -p /etc/services.d/nginx && \
    cat > /etc/services.d/nginx/run << 'EOF'
#!/command/with-contenv bash
exec 2>&1
exec nginx -g "daemon off;"
EOF

# Make sure the script is executable with the right permissions
RUN chmod 755 /etc/services.d/nginx/run && \
    chown ${NB_USER}:${NB_GID} /etc/services.d/nginx/run

# Expose port 8888
EXPOSE 8888

# Switch back to non-root user
USER $NB_UID

# Keep the original entrypoint
ENTRYPOINT ["/init"]
