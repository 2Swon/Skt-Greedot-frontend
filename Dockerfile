FROM debian:bullseye

# 필요한 도구 설치
RUN apt-get update && apt-get install -y curl git unzip xz-utils zip libglu1-mesa wget

# Android Command Line Tools 설치
RUN mkdir -p /usr/local/android-sdk/cmdline-tools && \
    wget -q https://dl.google.com/android/repository/commandlinetools-linux-6609375_latest.zip -O cmdline-tools.zip && \
    unzip cmdline-tools.zip -d /usr/local/android-sdk/cmdline-tools && \
    rm cmdline-tools.zip

# OpenJDK 17 설치
RUN apt-get install -y openjdk-17-jdk

# 환경 변수 설정
ENV JAVA_HOME /usr/lib/jvm/java-17-openjdk-amd64
ENV ANDROID_HOME=/usr/local/android-sdk
ENV PATH=$PATH:$ANDROID_HOME/cmdline-tools/tools/bin:$ANDROID_HOME/platform-tools

# Android SDK 도구 설치
RUN yes | sdkmanager --licenses && \
    sdkmanager "build-tools;35.0.0-rc1" "platforms;android-34"

# Flutter 버전 3.16.5 설치
RUN git clone https://github.com/flutter/flutter.git -b stable /usr/local/flutter && \
    cd /usr/local/flutter && \
    git checkout 78666c8dc5

ENV PATH="$PATH:/usr/local/flutter/bin"

# 작업 디렉토리 설정 및 앱 복사
WORKDIR /app
COPY . /app

# Flutter 의존성 해결 및 APK 빌드
RUN flutter doctor
RUN flutter pub get
RUN flutter build apk

CMD ["flutter", "run"]