FROM ubuntu

# Install Certbot
RUN apt-get -y update
RUN apt-get -y install certbot

# WORKDIR
WORKDIR /

# Copy scripts
COPY start.sh /
COPY base64.sh /

# Glue
ENV YOUR_CERTIFICATE_EMAIL=yourcertificatemail
ENV YOUR_DOMAIN=yourdomainvalue
ENV PFX_EXPORT_PASSWORD=securevalue
ENV WAIT_TIME_AFTER_ISSUE_IN_S=360
ENV PRODUCTION=0

ENTRYPOINT /start.sh
