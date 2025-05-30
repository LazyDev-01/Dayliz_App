@echo off
echo Installing dependencies...
flutter pub get

echo 
echo Building and running the app...
flutter run

echo
echo If the app fails to start, try the following troubleshooting steps:
echo 1. Make sure Flutter is installed and in your PATH.
echo 2. Run 'flutter doctor' to check for any issues with your Flutter installation.
echo 3. Try cleaning the project with 'flutter clean' and then 'flutter pub get' again. 