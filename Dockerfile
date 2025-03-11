# Use the Kubeflow Code-Server base image
FROM kubeflownotebookswg/codeserver:latest

# Switch to root to install packages and make modifications
USER root

# Install NGINX
RUN apt-get update && apt-get install -y nginx && apt-get clean && rm -rf /var/lib/apt/lists/*

# Create custom directories for nginx to use with correct permissions
RUN mkdir -p /home/jovyan/nginx/logs /home/jovyan/nginx/run /home/jovyan/nginx/cache /home/jovyan/nginx/body && \
    chown -R ${NB_USER}:${NB_GID} /home/jovyan/nginx

# Configure NGINX to work with non-root user (custom paths, no privileged ports)
RUN echo "worker_processes auto;\n\
pid /home/jovyan/nginx/run/nginx.pid;\n\
events {\n\
    worker_connections 1024;\n\
}\n\
http {\n\
    include /etc/nginx/mime.types;\n\
    default_type application/octet-stream;\n\
    access_log /home/jovyan/nginx/logs/access.log;\n\
    error_log /home/jovyan/nginx/logs/error.log;\n\
    client_body_temp_path /home/jovyan/nginx/body;\n\
    proxy_temp_path /home/jovyan/nginx/cache/proxy;\n\
    fastcgi_temp_path /home/jovyan/nginx/cache/fastcgi;\n\
    uwsgi_temp_path /home/jovyan/nginx/cache/uwsgi;\n\
    scgi_temp_path /home/jovyan/nginx/cache/scgi;\n\
    server {\n\
        listen 8888;\n\
        server_name localhost;\n\
        location / {\n\
            root /usr/share/nginx/html;\n\
            index index.html;\n\
        }\n\
        add_header Access-Control-Allow-Origin *;\n\
    }\n\
}" > /etc/nginx/nginx.conf

# Copy your web app files
COPY . /usr/share/nginx/html
RUN chown -R ${NB_USER}:${NB_GID} /usr/share/nginx/html

# Remove the code-server service to prevent it from starting
RUN rm -f /etc/services.d/code-server/run

# Create nginx run script
RUN mkdir -p /etc/services.d/nginx && \
    echo '#!/command/with-contenv bash' > /etc/services.d/nginx/run && \
    echo 'exec 2>&1' >> /etc/services.d/nginx/run && \
    echo 'exec nginx -g "daemon off;"' >> /etc/services.d/nginx/run

# Set proper permissions for the run script
RUN chmod 755 /etc/services.d/nginx/run && \
    chown ${NB_USER}:${NB_GID} /etc/services.d/nginx/run

# Expose port 8888
EXPOSE 8888

# Switch back to non-root user
USER $NB_UID

# Keep the original entrypoint
ENTRYPOINT ["/init"]
