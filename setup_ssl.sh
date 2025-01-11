#!/bin/bash

# Exit on error
set -e

DOMAIN="ec2-3-144-41-168.us-east-2.compute.amazonaws.com"

# Install certbot and nginx plugin
echo "Installing Certbot..."
sudo apt-get update
sudo apt-get install -y certbot python3-certbot-nginx

# Stop nginx container to free up port 80
echo "Stopping nginx container..."
docker compose down nginx

# Get SSL certificate
echo "Getting SSL certificate..."
sudo certbot certonly --standalone \
    --non-interactive \
    --agree-tos \
    --email joshua.daniel.jarabek@gauntletai.com \
    -d $DOMAIN

# Create directory for certificates if it doesn't exist
sudo mkdir -p /etc/nginx/ssl
sudo cp /etc/letsencrypt/live/$DOMAIN/fullchain.pem /etc/nginx/ssl/
sudo cp /etc/letsencrypt/live/$DOMAIN/privkey.pem /etc/nginx/ssl/

# Set proper permissions
sudo chown -R $USER:$USER /etc/nginx/ssl
chmod -R 600 /etc/nginx/ssl

# Create renewal hook to copy certificates and restart nginx
echo "Setting up auto-renewal..."
sudo tee /etc/letsencrypt/renewal-hooks/deploy/copy-certs-and-restart.sh > /dev/null << 'EOF'
#!/bin/bash
cp /etc/letsencrypt/live/DOMAIN/fullchain.pem /etc/nginx/ssl/
cp /etc/letsencrypt/live/DOMAIN/privkey.pem /etc/nginx/ssl/
docker compose -f /home/ubuntu/slack/devops/docker-compose.yml restart nginx
EOF

# Replace DOMAIN placeholder
sudo sed -i "s/DOMAIN/$DOMAIN/g" /etc/letsencrypt/renewal-hooks/deploy/copy-certs-and-restart.sh

# Make the hook executable
sudo chmod +x /etc/letsencrypt/renewal-hooks/deploy/copy-certs-and-restart.sh

echo "SSL certificates obtained successfully!"
echo "Now updating NGINX configuration..." 