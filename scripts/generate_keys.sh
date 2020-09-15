#!/bin/bash

# Generates a prime256v1 EC private key and extracts the respective public key.
# This script requires openssl to be installed, see here:
## https://www.openssl.org/source/

pushd "$(dirname "${BASH_SOURCE[0]}")" > /dev/null || exit

rm -rf keys
mkdir keys
pushd keys > /dev/null || exit

# Generate a prime256v1 EC private key
# $1 = OUT Private key file
generate_private_key()
{
  openssl ecparam                             \
    -name prime256v1                          \
    -genkey                                   \
    -out "$1"                                 \
    -noout
}

# Extract the public key from the private key
# $1 = IN  Private key
# $2 = OUT Public key
extract_public_key()
{
  openssl ec                                  \
    -in "$1"                                  \
    -pubout                                   \
    -out "$2"
}

# Generate certificate signing request
# $1 = IN  New certificate private key
# $2 = IN  "Subject" of the certificate
# $3 = OUT Certificate signing request file
generate_certificate_signing_request()
{
  openssl req                                 \
    -new                                      \
    -key "$1"                                 \
    -subj "$2"                                \
    -out "$3"
}

# Self-sign a certificate request
# $1 = IN  Certificate signing request file
# $2 = IN  Certificate authority private key file
# $3 = OUT New certificate file
self_sign_certificate_request()
{
  openssl x509                                \
    -req                                      \
    -days 365                                 \
    -in "$1"                                  \
    -signkey "$2"                             \
    -out "$3"
}

# Self-sign a certificate for EFGS batch signing
# $1 = IN  Private key
# $2 = IN  Certificate Header Parameters
# $3 = OUT New certificate file
self_sign_efgs_signing_certificate()
{
  openssl req -x509 -new \
    -days 365 \
    -key "$1" \
    -extensions v3_req \
    -subj "$2" \
    -nodes \
    -out "$3"
}

# Generate Certificate SHA256 thumbprint
# $1 = IN  X509 Certificate File
# $2 = OUT Thumbprint File
generate_certificate_thumbprint()
{
  openssl x509 -in "$1" -noout -hash -sha256 -fingerprint \
    | grep Fingerprint | sed 's/SHA256 Fingerprint=//' | sed 's/://g' >> "$2"
}

generate_jks_keystore()
{
  keytool -genkey -keyalg EC -keystore "$1" -storepass test1234 -keysize 2048 -alias dummykey \
    -dname C=X -validity 1 -keypass test1234
}

import_certificate_to_jks()
{
  keytool -importcert -alias efgs_trust_anchor -file "$2" -keystore "$1" -storepass test1234 -noprompt
}

clean_jks()
{
  keytool -delete -keystore "$1" -storepass test1234 -alias dummykey
}

sign_public_certificate()
{
  openssl dgst -sha256 -sign "$1" -out sig.tmp "$2"
  openssl base64 -in sig.tmp -out "$3" -A
  rm sig.tmp
}

generate_private_key private.pem
extract_public_key private.pem public.pem
generate_certificate_signing_request private.pem '/CN=CWA Test Certificate' request.csr
self_sign_certificate_request request.csr private.pem certificate.crt

# Generate EFGS Trust Anchor
generate_private_key efgs_ta_key.pem
self_sign_efgs_signing_certificate efgs_ta_key.pem '/CN=CWA Test Certificate/OU=CWA-Team/C=DE' efgs_ta_cert.pem
generate_jks_keystore efgs-ta.jks
import_certificate_to_jks efgs-ta.jks efgs_tls_cert.pem
clean_jks efgs-ta.jks

# Generate EFGS TLS Certificate
generate_private_key efgs_tls_key.pem
self_sign_efgs_signing_certificate efgs_tls_key.pem '/CN=CWA Test Certificate/OU=CWA-Team/C=DE' efgs_tls_cert.pem
generate_certificate_thumbprint efgs_tls_cert.pem efgs_x509_thumbprint.txt
import_certificate_to_jks efgs-ta.jks efgs_tls_cert.pem
sign_public_certificate efgs_ta_cert.pem efgs_tls_cert.pem efgs_tls_sign.b64

# Generate EFGS Signing Certificate
generate_private_key efgs_signing_key.pem
self_sign_efgs_signing_certificate efgs_signing_key.pem '/CN=CWA Test Certificate/OU=CWA-Team/C=DE' efgs_signing_cert.pem
generate_certificate_thumbprint efgs_signing_cert.pem efgs_x509_thumbprint.txt
import_certificate_to_jks efgs-ta.jks efgs_signing_cert.pem
sign_public_certificate efgs_ta_cert.pem efgs_signing_cert.pem efgs_signing_sign.b64

popd > /dev/null || exit
popd > /dev/null || exit
