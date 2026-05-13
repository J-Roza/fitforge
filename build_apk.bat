@echo off
echo ================================================
echo  FitForge - Build APK Android
echo ================================================
echo.

REM Verifier Flutter
where flutter >nul 2>nul
if %errorlevel% neq 0 (
    echo [ERREUR] Flutter n'est pas installe ou pas dans le PATH.
    echo Telecharge Flutter sur : https://docs.flutter.dev/get-started/install/windows
    pause
    exit /b 1
)

echo [1/3] Installation des dependances...
flutter pub get
if %errorlevel% neq 0 (
    echo [ERREUR] Echec de flutter pub get
    pause
    exit /b 1
)

echo.
echo [2/3] Build APK release...
flutter build apk --release
if %errorlevel% neq 0 (
    echo [ERREUR] Build echoue. Verifie les erreurs ci-dessus.
    pause
    exit /b 1
)

echo.
echo [3/3] Succes !
echo.
echo L'APK se trouve ici :
echo   build\app\outputs\flutter-apk\app-release.apk
echo.
echo Pour installer directement sur ton telephone connecte :
echo   flutter install
echo.
pause
