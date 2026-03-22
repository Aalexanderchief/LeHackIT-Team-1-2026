# Folosim o imagine oficială de Ubuntu
FROM ubuntu:22.04

# Evităm prompturile interactive
ENV DEBIAN_FRONTEND=noninteractive

# 1. Instalăm pachetele de bază și Java (OpenJDK 17 este recomandat)
RUN apt-get update && apt-get install -y \
    curl \
    git \
    unzip \
    xz-utils \
    zip \
    libglu1-mesa \
    openjdk-17-jdk \
    wget \
    && rm -rf /var/lib/apt/lists/*

# 2. Configurăm variabilele pentru Android SDK
ENV ANDROID_HOME=/opt/android-sdk
ENV ANDROID_SDK_ROOT=${ANDROID_HOME}
ENV CMDLINE_TOOLS_ROOT=${ANDROID_HOME}/cmdline-tools/latest
ENV PATH="${CMDLINE_TOOLS_ROOT}/bin:${ANDROID_HOME}/platform-tools:${PATH}"

# 3. Descărcăm și instalăm Android Command Line Tools
# (Folosim o versiune recentă de pe site-ul oficial Android)
RUN mkdir -p ${ANDROID_HOME}/cmdline-tools && \
    wget -q https://dl.google.com/android/repository/commandlinetools-linux-10406996_latest.zip -O /tmp/cmdline-tools.zip && \
    unzip -q /tmp/cmdline-tools.zip -d ${ANDROID_HOME}/cmdline-tools && \
    mv ${ANDROID_HOME}/cmdline-tools/cmdline-tools ${CMDLINE_TOOLS_ROOT} && \
    rm /tmp/cmdline-tools.zip

# 4. Acceptăm licențele Android și instalăm pachetele necesare
RUN yes | sdkmanager --licenses && \
    sdkmanager "platform-tools" "platforms;android-34" "build-tools;34.0.0" && \
    apt-get update && apt-get install -y libusb-1.0-0 libudev-dev && \
    rm -rf /var/lib/apt/lists/*

# 5. Configurăm Flutter SDK
ENV FLUTTER_HOME=/opt/flutter
ENV PATH="${FLUTTER_HOME}/bin:${PATH}"

# Descărcăm Flutter (canalul stable)
RUN git clone https://github.com/flutter/flutter.git -b stable $FLUTTER_HOME

# Permitem executarea Flutter ca root (necesar în Docker)
RUN git config --global --add safe.directory $FLUTTER_HOME

# Rulăm flutter doctor pentru a verifica mediul și a descărca Dart
RUN flutter --suppress-analytics doctor --android-licenses && \
    flutter --suppress-analytics doctor

# Setăm directorul de lucru
WORKDIR /app

# Copiem codul și descărcăm dependențele
COPY . .

# Autoriza Flutter sa ruleze ca root in Docker și instaleaza dependente
RUN test -f pubspec.yaml && \
    flutter --suppress-analytics config --enable-web --no-analytics && \
    flutter --suppress-analytics pub get

# Comanda implicită - rămâne în container pentru development
CMD ["/bin/bash"]