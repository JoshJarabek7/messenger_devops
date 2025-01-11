#!/bin/bash

# Exit on error
set -e

DOMAIN="ec2-3-144-41-168.us-east-2.compute.amazonaws.com"

# Create directory for certificates if it doesn't exist
sudo mkdir -p /etc/nginx/ssl

# Generate self-signed certificate
echo "Generating self-signed certificate..."
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/nginx/ssl/privkey.pem \
    -out /etc/nginx/ssl/fullchain.pem \
    -subj "/CN=${DOMAIN}" \
    -addext "subjectAltName=DNS:${DOMAIN}"

# Set proper permissions
sudo chown -R $USER:$USER /etc/nginx/ssl
chmod -R 600 /etc/nginx/ssl

echo "Self-signed SSL certificate generated successfully!"
echo "Note: Browsers will show a security warning because this is a self-signed certificate."
echo "To remove the warning, you'll need to either:"
echo "1. Use a custom domain name with Let's Encrypt"
echo "2. Use AWS Certificate Manager" 