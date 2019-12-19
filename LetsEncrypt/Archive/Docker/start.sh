#!/bin/bash

# Execute Let's Encrypt cert issuing process
if [ $PRODUCTION -eq 0 ]; then
  echo "Try issuing certificate from Let's Encrypt (Staging)..."
  certbot certonly --standalone --non-interactive --agree-tos --email $YOUR_CERTIFICATE_EMAIL --domains $YOUR_DOMAIN --staging 
else
    echo "Try issuing certificate from Let's Encrypt (Production)..."
  certbot certonly --standalone --non-interactive --agree-tos --email $YOUR_CERTIFICATE_EMAIL --domains $YOUR_DOMAIN 
fi

# Create PFX file
echo "Try create certificate..."
cp /etc/letsencrypt/live/$YOUR_DOMAIN/* .
openssl pkcs12 -inkey /privkey.pem -in /fullchain.pem -export -out /sslcert.pfx -passout pass:$PFX_EXPORT_PASSWORD
echo "Done"

# Keep Container alive
i=1
echo "Waiting for $WAIT_TIME_AFTER_ISSUE_IN_S seconds (for copy operation to complete)"
while [ $i -le $WAIT_TIME_AFTER_ISSUE_IN_S ]
do
  sleep 1s
  printf "."
  ((i++))
done
echo "stopping process"