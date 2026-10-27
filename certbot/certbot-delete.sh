#!/bin/sh

set -e

domain="$1"

if [ -z "$domain" ]; then
  echo "Specify the domain on the command line"
  exit 1;
fi

echo "Deleting the certificate for domain $domain"

if [ "$DRY_RUN" = "true" ]; then
  echo "Dry run:      certbot --noninteractive delete --cert-name ${domain}"
else
  certbot --noninteractive delete --cert-name "${domain}"
fi
