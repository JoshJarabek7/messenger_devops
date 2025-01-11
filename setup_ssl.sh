#!/bin/bash

# Exit on error
set -e

DOMAIN="ec2-3-144-41-168.us-east-2.compute.amazonaws.com"

# Stop and disable system nginx if it exists
echo "Stopping system NGINX..."
sudo systemctl stop nginx || true
sudo systemctl disable nginx || true

# Create a temporary directory for certificates
echo "Creating temporary directory..."
TEMP_SSL_DIR=$(mktemp -d)
chmod 755 $TEMP_SSL_DIR

# Generate self-signed certificate
echo "Generating self-signed certificate..."
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout $TEMP_SSL_DIR/privkey.pem \
    -out $TEMP_SSL_DIR/fullchain.pem \
    -subj "/CN=${DOMAIN}" \
    -addext "subjectAltName=DNS:${DOMAIN}"

# Ensure certificates are readable
chmod 644 $TEMP_SSL_DIR/*.pem

# Create Docker volume if it doesn't exist
echo "Creating Docker volume..."
docker volume create ssl_certs

# Copy certificates to Docker volume using a temporary container
echo "Copying certificates to Docker volume..."
docker run --rm \
    -v ssl_certs:/ssl \
    -v $TEMP_SSL_DIR:/certs:ro \
    alpine \
    sh -c "cp /certs/*.pem /ssl/ && chown -R 101:101 /ssl && chmod -R 600 /ssl/*.pem"

# Clean up temporary directory
echo "Cleaning up..."
rm -rf $TEMP_SSL_DIR

echo "Self-signed SSL certificate generated successfully!"
echo "Note: Browsers will show a security warning because this is a self-signed certificate."
echo "To remove the warning, you'll need to either:"
echo "1. Use a custom domain name with Let's Encrypt"
echo "2. Use AWS Certificate Manager" 