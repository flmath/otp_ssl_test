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
# Prefer gmssl binary for SM2 certs if available
GMSSL_BIN="/opt/gmssl/bin/gmssl"
if [ ! -f "$GMSSL_BIN" ]; then
    GMSSL_BIN=$(which gmssl 2>/dev/null || echo "openssl")
fi

if [ "$GMSSL_BIN" != "openssl" ]; then
    export LD_LIBRARY_PATH=/opt/gmssl/lib
    
    # Signing Certificate
    $GMSSL_BIN ecparam -genkey -name sm2p256v1 -out sm2_sign_key.pem
    $GMSSL_BIN req -new -key sm2_sign_key.pem -out sm2_sign_csr.pem -subj "/CN=SM2-Sign" -sm3
    $GMSSL_BIN x509 -req -in sm2_sign_csr.pem -signkey sm2_sign_key.pem -out sm2_sign_cert.pem -days 365 -sm3
    
    # Encryption Certificate
    $GMSSL_BIN ecparam -genkey -name sm2p256v1 -out sm2_enc_key.pem
    $GMSSL_BIN req -new -key sm2_enc_key.pem -out sm2_enc_csr.pem -subj "/CN=SM2-Enc" -sm3
    $GMSSL_BIN x509 -req -in sm2_enc_csr.pem -signkey sm2_enc_key.pem -out sm2_enc_cert.pem -days 365 -sm3

    # Compatibility links
    ln -sf sm2_sign_cert.pem sm2_cert.pem
    ln -sf sm2_sign_key.pem sm2_key.pem
    
    echo "SM2 dual-certificates generated using GmSSL."
else
    # Fallback to standard openssl if gmssl not found
    echo "GmSSL binary not found, trying OpenSSL fallback..."
    # ... (rest of old logic for openssl)
    openssl ecparam -genkey -name sm2 -out sm2_sign_key.pem
    openssl req -new -key sm2_sign_key.pem -out sm2_sign_csr.pem -subj "/CN=SM2-Sign" -sm3
    openssl x509 -req -in sm2_sign_csr.pem -signkey sm2_sign_key.pem -out sm2_sign_cert.pem -days 365 -sm3
    openssl ecparam -genkey -name sm2 -out sm2_enc_key.pem
    openssl req -new -key sm2_enc_key.pem -out sm2_enc_csr.pem -subj "/CN=SM2-Enc" -sm3
    openssl x509 -req -in sm2_enc_csr.pem -signkey sm2_enc_key.pem -out sm2_enc_cert.pem -days 365 -sm3
    ln -sf sm2_sign_cert.pem sm2_cert.pem
    ln -sf sm2_sign_key.pem sm2_key.pem
fi
