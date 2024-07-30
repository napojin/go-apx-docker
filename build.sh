#!/bin/bash

# ビルド対象のGoファイル名
GO_FILE="main.go"

# 出力バイナリ名
OUTPUT_BIN="main"

# デバッグ情報、シンボルテーブル、パス情報を削除してビルド
echo "Building with debug and symbol table removal..."
CGO_ENABLED=0 GOOS=linux GOARCH=arm64 go build -ldflags="-s -w" -trimpath -o $OUTPUT_BIN $GO_FILE

# stripコマンドでさらに不要な情報を削除
echo "Stripping the binary..."
strip $OUTPUT_BIN

# UPXでlzma圧縮
echo "Compressing with UPX (lzma)..."
upx --lzma $OUTPUT_BIN

echo "Build completed. Final binary: $OUTPUT_BIN"
strip --version
