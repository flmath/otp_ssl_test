#!/bin/bash
set -e
CERT_DIR=$1
mkdir -p "$CERT_DIR"

# Generate RSA Cert
openssl req -x509 -newkey rsa:2048 -nodes -keyout "$CERT_DIR/rsa_key.pem" -out "$CERT_DIR/rsa_cert.pem" -days 365 -subj "/CN=localhost"

# Generate ECC Cert
openssl req -x509 -newkey ec -pkeyopt ec_paramgen_curve:prime256v1 -nodes -keyout "$CERT_DIR/ecc_key.pem" -out "$CERT_DIR/ecc_cert.pem" -days 365 -subj "/CN=localhost"

# Generate SM2 Cert (Supported in OpenSSL 3.0+)
# Check if SM2 is supported
if openssl ecparam -list_curves | grep -q "SM2"; then
  openssl req -x509 -newkey ec -pkeyopt ec_paramgen_curve:sm2 -nodes -keyout "$CERT_DIR/sm2_key.pem" -out "$CERT_DIR/sm2_cert.pem" -days 365 -subj "/CN=localhost" -sm3
else
  echo "SM2 curve not supported by this OpenSSL version"
fi
