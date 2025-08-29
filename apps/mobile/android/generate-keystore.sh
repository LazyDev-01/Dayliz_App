#!/bin/bash

# Production Keystore Generation Script for Dayliz App
# This script generates a production keystore for app signing

echo "🔐 Generating Production Keystore for Dayliz App"
echo "================================================"

# Keystore configuration
KEYSTORE_NAME="release-keystore.jks"
KEY_ALIAS="dayliz-release-key"
VALIDITY_DAYS=10000  # ~27 years

# Check if keystore already exists
if [ -f "$KEYSTORE_NAME" ]; then
    echo "⚠️  Keystore already exists: $KEYSTORE_NAME"
    read -p "Do you want to overwrite it? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "❌ Keystore generation cancelled"
        exit 1
    fi
    rm "$KEYSTORE_NAME"
fi

echo "📝 Please provide the following information for your keystore:"
echo

# Generate keystore
keytool -genkey -v \
    -keystore "$KEYSTORE_NAME" \
    -keyalg RSA \
    -keysize 2048 \
    -validity $VALIDITY_DAYS \
    -alias "$KEY_ALIAS"

if [ $? -eq 0 ]; then
    echo
    echo "✅ Keystore generated successfully: $KEYSTORE_NAME"
    echo
    echo "📋 Next steps:"
    echo "1. Copy key.properties.example to key.properties"
    echo "2. Update key.properties with your keystore passwords"
    echo "3. Keep your keystore and passwords secure!"
    echo "4. NEVER commit keystore files to version control"
    echo
    echo "🔒 Security reminders:"
    echo "- Store keystore in a secure location"
    echo "- Backup keystore and passwords securely"
    echo "- Use strong passwords"
    echo "- Keep keystore passwords confidential"
else
    echo "❌ Failed to generate keystore"
    exit 1
fi
