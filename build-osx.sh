#!/bin/bash

set -e

JDK_VER="11.0.4"
JDK_BUILD="11"

if ! [ -f OpenJDK11U-jre_x64_mac_hotspot_${JDK_VER}_${JDK_BUILD}.tar.gz ] ; then
    curl -Lo OpenJDK11U-jre_x64_mac_hotspot_${JDK_VER}_${JDK_BUILD}.tar.gz \
        https://github.com/AdoptOpenJDK/openjdk11-binaries/releases/download/jdk-${JDK_VER}%2B${JDK_BUILD}/OpenJDK11U-jre_x64_mac_hotspot_${JDK_VER}_${JDK_BUILD}.tar.gz
fi

rm -f packr.jar
curl -o packr.jar https://libgdx.badlogicgames.com/ci/packr/packr.jar

echo "1647fded28d25e562811f7bce2092eb9c21d30608843b04250c023b40604ff26  OpenJDK11U-jre_x64_mac_hotspot_${JDK_VER}_${JDK_BUILD}.tar.gz" | shasum -c

# packr requires a "jdk" and pulls the jre from it - so we have to place it inside
# the jdk folder at jre/
if ! [ -d osx-jdk ] ; then
    tar zxf OpenJDK11U-jre_x64_mac_hotspot_${JDK_VER}_${JDK_BUILD}.tar.gz
    mkdir osx-jdk
    mv jdk-11.0.4+11-jre osx-jdk/jre

    # Move JRE out of Contents/Home/
    pushd osx-jdk/jre
    cp -r Contents/Home/* .
    popd
fi

java -jar packr.jar \
    --platform \
    mac \
    --icon \
    packr/openosrs.icns \
    --jdk \
    osx-jdk \
    --executable \
    OpenOSRS \
    --classpath \
    build/libs/OpenOSRS-shaded.jar \
    --mainclass \
    net.runelite.launcher.Launcher \
    --vmargs \
    Drunelite.launcher.nojvm=true \
    Xmx512m \
    Xss2m \
    XX:CompileThreshold=1500 \
    Djna.nosys=true \
    --output \
    native-osx/OpenOSRS.app

cp build/filtered-resources/Info.plist native-osx/OpenOSRS.app/Contents

echo Setting world execute permissions on OpenOSRS
pushd native-osx/OpenOSRS.app
chmod g+x,o+x Contents/MacOS/OpenOSRS
popd

# create-dmg exits with an error code due to no code signing, but is still okay
# note we use Adam-/create-dmg as upstream does not support UDBZ
create-dmg --format UDBZ native-osx/OpenOSRS.app || true
