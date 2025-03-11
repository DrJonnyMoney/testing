# Use the Kubeflow Code-Server base image
FROM kubeflownotebookswg/codeserver:latest

# Switch to root to install packages and make modifications
USER root

# Install NGINX
RUN apt-get update && apt-get install -y nginx && apt-get clean && rm -rf /var/lib/apt/lists/*

# Create custom directories for nginx to use with correct permissions
RUN mkdir -p /home/jovyan/nginx/logs /home/jovyan/nginx/run /home/jovyan/nginx/cache/proxy /home/jovyan/nginx/cache/fastcgi /home/jovyan/nginx/cache/uwsgi /home/jovyan/nginx/cache/scgi /home/jovyan/nginx/body && \
    chown -R ${NB_USER}:${NB_GID} /home/jovyan/nginx

# Configure NGINX to work with non-root user - using cat heredoc for proper formatting
RUN cat > /etc/nginx/nginx.conf << 'EOF'
worker_processes auto;
pid /home/jovyan/nginx/run/nginx.pid;
events {
    worker_connections 1024;
}
http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;
    access_log /home/jovyan/nginx/logs/access.log;
    error_log /home/jovyan/nginx/logs/error.log;
    client_body_temp_path /home/jovyan/nginx/body;
    proxy_temp_path /home/jovyan/nginx/cache/proxy;
    fastcgi_temp_path /home/jovyan/nginx/cache/fastcgi;
    uwsgi_temp_path /home/jovyan/nginx/cache/uwsgi;
    scgi_temp_path /home/jovyan/nginx/cache/scgi;
    server {
        listen 8888;
        server_name localhost;
        location / {
            root /usr/share/nginx/html;
            index index.html;
        }
        add_header Access-Control-Allow-Origin *;
    }
}
EOF

# Copy your web app files
COPY . /usr/share/nginx/html
RUN chown -R ${NB_USER}:${NB_GID} /usr/share/nginx/html

# Remove the code-server service to prevent it from starting
RUN rm -f /etc/services.d/code-server/run

# Create nginx run script using heredoc for proper formatting
RUN mkdir -p /etc/services.d/nginx && \
    cat > /etc/services.d/nginx/run << 'EOF'
#!/command/with-contenv bash
exec 2>&1
exec nginx -g "daemon off;"
EOF

# Set proper permissions for the run script
RUN chmod 755 /etc/services.d/nginx/run && \
    chown ${NB_USER}:${NB_GID} /etc/services.d/nginx/run

# Expose port 8888
EXPOSE 8888

# Switch back to non-root user
USER $NB_UID

# Keep the original entrypoint
ENTRYPOINT ["/init"]
