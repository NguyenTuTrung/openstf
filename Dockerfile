# ======= STAGE 1: Build stage =======
FROM ubuntu:22.04 AS build

ENV DEBIAN_FRONTEND=noninteractive

# Cài hệ thống, Node.js và tool build
RUN apt-get update && apt-get -y dist-upgrade && \
    apt-get install -y wget curl gnupg2 build-essential python3 git \
    graphicsmagick openjdk-8-jdk yasm cmake libzmq3-dev libprotobuf-dev && \
    curl -fsSL https://deb.nodesource.com/setup_22.x | bash - && \
    apt-get install -y nodejs && \
    node -v && npm -v && \
    npm install -g npm && \
    useradd --system --create-home --shell /usr/sbin/nologin stf && \
    mkdir -p /app /app/bundletool

WORKDIR /app

# Tải bundletool
RUN wget -q https://github.com/google/bundletool/releases/download/1.2.0/bundletool-all-1.2.0.jar -O /app/bundletool/bundletool.jar

# Copy source code vào build image
COPY . /app

# Cài node_modules dưới quyền user stf
RUN chown -R stf:stf /app && \
    su stf -s /bin/bash -c "cd /app && npm install --loglevel=http"

# ======= STAGE 2: Runtime stage =======
FROM ubuntu:22.04 AS runtime

ENV DEBIAN_FRONTEND=noninteractive \
    PATH=/app/bin:$PATH

# Cài dependencies chỉ cần thiết khi chạy
RUN apt-get update && \
    apt-get install -y graphicsmagick openjdk-8-jdk python3 curl && \
    curl -fsSL https://deb.nodesource.com/setup_22.x | bash - && \
    apt-get install -y nodejs && \
    node -v && npm -v && \
    useradd --system --create-home --shell /usr/sbin/nologin stf && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/*

WORKDIR /app

# Copy từ build stage sang
COPY --from=build /app /app

# Gán quyền thực thi và tạo symlink
RUN chmod +x /app/bin/stf && ln -s /app/bin/stf /usr/local/bin/stf

USER stf

EXPOSE 3000

CMD ["stf", "--help"]
