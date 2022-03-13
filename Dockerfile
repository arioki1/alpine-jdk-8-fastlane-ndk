FROM openjdk:8-jdk-alpine

LABEL maintainer "Yoga Setiawan <ariokidev@gmail.com>"


ENV ANDROID_SDK_TOOLS_VERSION="3859397"
ENV ANDROID_VERSION=31
ENV ANDROID_BUILD_TOOLS_VERSION=29.0.2
ENV ANDROID_NDK_VERSION=android-ndk-r21d
ENV FASTLANE_VERSION=2.204.2
ENV CMAKE_VERSION=3.18.1
ENV GLIBC_VERSION=2.29-r0

ENV ANDROID_HOME="/usr/local/android-sdk"
ENV ANDROID_SDK_ROOT=${ANDROID_HOME}
ENV ANDROID_NDK_HOME=${ANDROID_HOME}/ndk/${ANDROID_NDK_VERSION}
ENV ANDROID_NDK_ROOT=${ANDROID_NDK_HOME}
RUN export GRADLE_USER_HOME=$(pwd)/.gradle

# add to PATH
ENV PATH=${PATH}:${ANDROID_HOME}/tools
ENV PATH=${PATH}:${ANDROID_HOME}/tools/bin
ENV PATH=${PATH}:${ANDROID_HOME}/platform-tools
ENV PATH=${PATH}:${ANDROID_HOME}/build-tools/${ANDROID_BUILD_TOOLS_VERSION}
ENV PATH=${PATH}:${ANDROID_NDK_HOME}


ENV SDK_URL="https://dl.google.com/android/repository/sdk-tools-linux-${ANDROID_SDK_TOOLS_VERSION}.zip"
ENV NDK_URL="https://dl.google.com/android/repository/${ANDROID_NDK_VERSION}-linux-x86_64.zip"

ENV DOWNLOAD_FILE_SDK=/tmp/sdk.zip
ENV DOWNLOAD_FILE_NDK=/tmp/ndk.zip

# Update current packages
RUN apk update && apk upgrade

# Deps
RUN apk add --update \
    ca-certificates \
    wget \
    bash \
    unzip \
    libstdc++ \
    g++ \
    make \
    ruby \
    ruby-irb \
    ruby-dev \
    file \
    && rm -rf /var/cache/apk/*

# Fastlane
RUN gem install fastlane -N -v $FASTLANE_VERSION

# Android SDK & NDK
RUN mkdir -p ~/.android && touch ~/.android/repositories.cfg
RUN mkdir -p "$ANDROID_HOME" \
    && mkdir -p "$ANDROID_NDK_HOME" \
    && wget -q -O "$DOWNLOAD_FILE_SDK" $SDK_URL \
    && wget -q -O "$DOWNLOAD_FILE_NDK" $NDK_URL \
    && unzip "$DOWNLOAD_FILE_SDK" -d "$ANDROID_HOME" \
    && unzip "$DOWNLOAD_FILE_NDK" -d "$ANDROID_HOME/ndk/" \
    && rm "$DOWNLOAD_FILE_SDK" \
    && rm "$DOWNLOAD_FILE_NDK" 

# Acceptt all license
RUN yes | $ANDROID_HOME/tools/bin/sdkmanager --update 1>/dev/null   
RUN yes | $ANDROID_HOME/tools/bin/sdkmanager --licenses 1>/dev/null    

# Android Build Tools
RUN $ANDROID_HOME/tools/bin/sdkmanager "build-tools;${ANDROID_BUILD_TOOLS_VERSION}" \
    "platforms;android-${ANDROID_VERSION}" \
    "cmake;${CMAKE_VERSION}" \
    "platform-tools"

# AIDL deps
RUN wget -q -O /etc/apk/keys/sgerrand.rsa.pub https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub

RUN mkdir -p /tmp/glibc
RUN for PACKAGE in glibc glibc-bin glibc-i18n glibc-dev; do \
        export APK_FILE="${PACKAGE}-${GLIBC_VERSION}.apk"; \
        export APK_PATH="/tmp/glibc/$APK_FILE"; \
        wget -q -O $APK_PATH https://github.com/sgerrand/alpine-pkg-glibc/releases/download/${GLIBC_VERSION}/${APK_FILE}; \
        apk add $APK_PATH; \
    done

RUN rm -rf /tmp/glibc
