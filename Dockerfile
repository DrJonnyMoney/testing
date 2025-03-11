# Use the Kubeflow Code-Server base image
FROM kubeflownotebookswg/codeserver:latest

# Switch to root to install packages and make modifications
USER root

# Install NGINX
RUN apt-get update && apt-get install -y nginx && apt-get clean && rm -rf /var/lib/apt/lists/*

# Copy the nginx configuration file
COPY nginx.conf /etc/nginx/nginx.conf

# Copy your web app files
COPY . /usr/share/nginx/html
RUN chown -R ${NB_USER}:${NB_GID} /usr/share/nginx/html

# Create an initialization script that will run before services start
RUN mkdir -p /etc/cont-init.d && \
    echo '#!/bin/bash' > /etc/cont-init.d/02-setup-nginx && \
    echo 'mkdir -p /home/jovyan/nginx/logs /home/jovyan/nginx/run /home/jovyan/nginx/cache/proxy /home/jovyan/nginx/cache/fastcgi /home/jovyan/nginx/cache/uwsgi /home/jovyan/nginx/cache/scgi /home/jovyan/nginx/body' >> /etc/cont-init.d/02-setup-nginx && \
    echo 'chown -R ${NB_USER}:${NB_GID} /home/jovyan/nginx' >> /etc/cont-init.d/02-setup-nginx && \
    chmod 755 /etc/cont-init.d/02-setup-nginx

# Create nginx service directory
RUN mkdir -p /etc/services.d/nginx

# Copy the nginx run script 
COPY nginx-run /etc/services.d/nginx/run

# Set proper permissions for the run script
RUN chmod 755 /etc/services.d/nginx/run && \
    chown ${NB_USER}:${NB_GID} /etc/services.d/nginx/run

# Expose port 8888
EXPOSE 8888

# Switch back to non-root user
USER $NB_UID

# Keep the original entrypoint
ENTRYPOINT ["/init"]
