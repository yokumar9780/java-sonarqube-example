#!/bin/bash

# Define the server URL and file names
SERVER_URL="https://web.sonar.vgcslabs.io"
CERT_FILE="sonar_cert.pem"
KEYSTORE_FILE="$JAVA_HOME/lib/security/cacerts"
KEYSTORE_PASSWORD="changeit"
ALIAS="sonar_server"

# Step 1: Download the certificate using openssl
echo "Downloading certificate from $SERVER_URL"
openssl s_client -connect web.sonar.vgcslabs.io:443 -showcerts < /dev/null | openssl x509 -outform PEM > $CERT_FILE

# Step 2: Check if alias already exists in the keystore
echo "Checking if alias '$ALIAS' already exists in the keystore"
keytool -list -keystore $KEYSTORE_FILE -storepass $KEYSTORE_PASSWORD | grep -i "$ALIAS"

if [ $? -eq 0 ]; then
    echo "Alias '$ALIAS' already exists. Deleting the existing alias..."
    keytool -delete -alias $ALIAS -keystore $KEYSTORE_FILE -storepass $KEYSTORE_PASSWORD
else
    echo "No existing alias '$ALIAS' found."
fi

# Step 3: Import the certificate into the Java keystore
echo "Importing certificate into Java keystore"
keytool -import -noprompt -trustcacerts -alias $ALIAS -file $CERT_FILE -keystore $KEYSTORE_FILE -storepass $KEYSTORE_PASSWORD

# Step 4: Verify the certificate was imported successfully
echo "Verifying certificate import"
keytool -list -keystore $KEYSTORE_FILE -storepass $KEYSTORE_PASSWORD | grep -i "$ALIAS"

if [ $? -eq 0 ]; then
    echo "Certificate imported successfully and verified."
else
    echo "Certificate import failed or alias not found in the keystore."
    exit 1
fi

# Step 5: Clean up the downloaded certificate
rm -f $CERT_FILE

echo "Process completed successfully."
