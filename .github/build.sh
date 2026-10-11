#!/usr/bin/env bash
# Runs inside the unityci/editor Android image: activate a Unity Personal seat,
# build the ARM64 APK with CardWarsAndroidBuild.BuildApk, then return the seat.
set -uo pipefail
ED=/opt/unity/Editor
AP=$ED/Data/PlaybackEngines/AndroidPlayer
export ANDROID_SDK_ROOT=$AP/SDK ANDROID_NDK_ROOT=$AP/NDK JAVA_HOME=$AP/OpenJDK
ls -d "$ANDROID_SDK_ROOT" "$ANDROID_NDK_ROOT" "$JAVA_HOME"
UNITY=$(command -v unity-editor || echo $ED/Unity)
LC=$(find $ED/Data/Resources/Licensing -name Unity.Licensing.Client -type f | head -1)
echo "Licensing client: $LC"

return_seat() {
  "$UNITY" -batchmode -nographics -quit -returnlicense \
    -username "$UNITY_EMAIL" -password "$UNITY_PASSWORD" -logFile - | grep -i licen || true
}
trap return_seat EXIT

"$LC" --activate-all --include-personal --username "$UNITY_EMAIL" --password "$UNITY_PASSWORD"
echo "activation exit: $?"

"$UNITY" -batchmode -nographics -quit -projectPath /project -buildTarget Android \
  -executeMethod CardWarsAndroidBuild.BuildApk -logFile /project/Builds/unity-build.log
rc=$?
echo "unity exit: $rc"
grep -iE 'licen|error|exception|Building Card Wars|build succeeded|build failed' /project/Builds/unity-build.log | tail -150
exit $rc
