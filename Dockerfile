FROM golang:1.22.5-alpine3.19

# 作業ディレクトリの設定
WORKDIR /go/src

# 必要なパッケージのインストール
RUN apk add --no-cache \
    bash \
    binutils \
    wget \
    xz \
    build-base

# upxのダウンロードとインストール
RUN wget https://github.com/upx/upx/releases/download/v4.2.4/upx-4.2.4-amd64_linux.tar.xz && \
    tar -xf upx-4.2.4-amd64_linux.tar.xz && \
    mv upx-4.2.4-amd64_linux/upx /usr/local/bin/ && \
    rm -rf upx-4.2.4-amd64_linux.tar.xz upx-4.2.4-amd64_linux

# ビルドスクリプトのコピー
COPY build.sh .

# ビルドスクリプトに実行権限を付与
RUN chmod +x build.sh

# # ビルドスクリプトの実行
# CMD ["./build.sh"]
