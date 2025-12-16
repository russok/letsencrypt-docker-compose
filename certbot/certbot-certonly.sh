#!/bin/sh

set -e

config="/letsencrypt-docker-compose/config.json"

if [ ! -f "$config" ]; then
  echo "Configuration file not found"
  exit 1;
fi

domains=$(jq -r '.domains[].domain' $config)

if [ -z "$domains" ]; then
  echo "Domains are not configured"
  exit 1;
fi

for domain in $domains; do
  echo "Obtaining the certificate for domain $domain"

  www_subdomain=$(jq -r --arg domain "$domain" '.domains[] | select(.domain == $domain) | .wwwSubdomain' $config)
  email=$(jq -r --arg domain "$domain" '.domains[] | select(.domain == $domain) | .email' $config)
  test_cert=$(jq -r --arg domain "$domain" '.domains[] | select(.domain == $domain) | .testCert' $config)

  mkdir -p "/var/www/certbot/${domain}"

  if [ -d "/etc/letsencrypt/live/${domain}" ]; then
    echo "Let's Encrypt certificate for ${domain} already exists"
    continue
  fi

  if [ "$www_subdomain" = "true" ]; then
    www_subdomain_arg="-d www.${domain}"
    echo "A 'www' subdomain enabled"
  else
    www_subdomain_arg=""
  fi

  if [ "$test_cert" = "true" ]; then
    test_cert_arg="--test-cert"
    echo "Testing on staging environment enabled"
  else
    test_cert_arg=""
  fi

  if [ -z "$email" ]; then
    email_arg="--register-unsafely-without-email"
    echo "Registering unsafely without email"
  else
    email_arg="--email $email"
    echo "Using email ${email}"
  fi

  if [ "$DRY_RUN" = "true" ]; then
    echo "Dry run is enabled"
  else
    certbot certonly \
      --webroot \
      -w "/var/www/certbot/${domain}" \
      -d "$domain" \
      $www_subdomain_arg \
      $test_cert_arg \
      $email_arg \
      --agree-tos \
      --noninteractive \
      --verbose || true
  fi
done
