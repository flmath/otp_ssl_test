#!/bin/bash
set -e
CERT_DIR=$1
mkdir -p "$CERT_DIR"
cd "$CERT_DIR"

echo "Generating RSA certificates..."
openssl req -x509 -newkey rsa:2048 -nodes -keyout rsa_key.pem -out rsa_cert.pem -days 365 -subj "/CN=localhost"

echo "Generating ECC certificates..."
openssl req -x509 -newkey ec -pkeyopt ec_paramgen_curve:prime256v1 -nodes -keyout ecc_key.pem -out ecc_cert.pem -days 365 -subj "/CN=localhost"

echo "Generating SM2 certificates..."
# Check if SM2 curve is supported
if openssl ecparam -list_curves | grep -q "SM2"; then
  # Multi-step generation for better compatibility
  openssl ecparam -genkey -name sm2 -out sm2_key.pem
  openssl req -new -key sm2_key.pem -out sm2_csr.pem -subj "/CN=localhost" -sm3
  openssl x509 -req -in sm2_csr.pem -signkey sm2_key.pem -out sm2_cert.pem -days 365 -sm3
  echo "SM2 certificates generated."
else
  echo "SM2 curve not supported by this OpenSSL version."
fi
