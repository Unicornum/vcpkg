@echo off

rem [20.12.2024] Библиотеки корректно собираются для Vs2022 и Android NDK:
set EXPECTED_ANDROID_NDK=android-ndk-r26d
set ManifestRoot=--x-manifest-root=externals

cd %~dp0\..

if "%ANDROID_NDK_HOME%"=="" (
  echo error: not set ANDROID_NDK_HOME
  echo please call first 'setx ANDROID_NDK_HOME path\to\androidndk\root'
  pause
  goto EndOfFile
)

call :CheckPathToAndroidNdk "%ANDROID_NDK_HOME%"
if ERRORLEVEL 1 goto EndOfFile

rem Проверить наличие файл-флага
if exist .\Externals\Success.build goto EndOfFile

rem Собрать vcpkg
call bootstrap-vcpkg.bat -disableMetrics

vcpkg.exe install --triplet "x64-windows-static-md" --x-install-root=. %ManifestRoot%
if ERRORLEVEL 1 (
  echo x64-windows: error: build failed
  pause
  goto EndOfFile
)

rem Копировать в одну общую папку нельзя, .т.к некоторые заголовочные файлы
rem Windows и Android версий отличаются.
xcopy "x64-windows-static-md\*" "Externals\Windows" /S /Q /Y /I

vcpkg.exe install --triplet "arm64-android" --x-install-root=. %ManifestRoot%
if ERRORLEVEL 1 (
  echo arm64-android: error: build failed
  pause
  goto EndOfFile
)

rem Копировать в одну общую папку нельзя, .т.к некоторые заголовочные файлы
rem Windows и Android версий отличаются.
xcopy "arm64-android\*" "Externals\Android" /S /Q /Y /I

del .\buildtrees\*.* /S /Q

rem Удачная сборка, добавить файл-флаг как маркер этого факта
echo Success > .\Externals\Success.build

rem Библиотеки собираются в \packages\...
rem Результат копируется в \installed\...

goto EndOfFile

:CheckPathToAndroidNdk

if not "%~nx1" == "%EXPECTED_ANDROID_NDK%" (
  echo ANDROID_NDK_HOME: error: expected path to %EXPECTED_ANDROID_NDK%
  pause
  exit /b 1
)

exit /b 0

:EndOfFile
