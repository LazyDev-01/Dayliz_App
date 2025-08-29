@echo off
REM Production Keystore Generation Script for Dayliz App
REM This script generates a production keystore for app signing

echo 🔐 Generating Production Keystore for Dayliz App
echo ================================================

REM Keystore configuration
set KEYSTORE_NAME=release-keystore.jks
set KEY_ALIAS=dayliz-release-key
set VALIDITY_DAYS=10000

REM Check if keystore already exists
if exist "%KEYSTORE_NAME%" (
    echo ⚠️  Keystore already exists: %KEYSTORE_NAME%
    set /p "overwrite=Do you want to overwrite it? (y/N): "
    if /i not "%overwrite%"=="y" (
        echo ❌ Keystore generation cancelled
        exit /b 1
    )
    del "%KEYSTORE_NAME%"
)

echo 📝 Please provide the following information for your keystore:
echo.

REM Generate keystore
keytool -genkey -v -keystore "%KEYSTORE_NAME%" -keyalg RSA -keysize 2048 -validity %VALIDITY_DAYS% -alias "%KEY_ALIAS%"

if %errorlevel% equ 0 (
    echo.
    echo ✅ Keystore generated successfully: %KEYSTORE_NAME%
    echo.
    echo 📋 Next steps:
    echo 1. Copy key.properties.example to key.properties
    echo 2. Update key.properties with your keystore passwords
    echo 3. Keep your keystore and passwords secure!
    echo 4. NEVER commit keystore files to version control
    echo.
    echo 🔒 Security reminders:
    echo - Store keystore in a secure location
    echo - Backup keystore and passwords securely
    echo - Use strong passwords
    echo - Keep keystore passwords confidential
) else (
    echo ❌ Failed to generate keystore
    exit /b 1
)

pause
