# go-upx-docker

## 概要
GoのバイナリはCのバイナリに比べて非常に大きいです。Goのバイナリが極端に大きいのは、Goのランタイムを含む外部ライブラリをすべて静的リンクしているためです。しかし、デバッグ情報やシンボルテーブルを削除し、さらに圧縮することで、バイナリサイズを大幅に削減することが可能です。この記事では、さまざまな方法を用いてGoバイナリのサイズを削減し、Cのバイナリと比較します。

## バージョン情報
- 手元の作業PC:
    - チップ: Apple M1 Pro
    - macOS: macOS Sonoma (バージョン14.5)
- Docker: 20.10.21
	- イメージ: golang:1.22.5-alpine3.19
- Docker-compose: 2.13.0


## CとGoのサイズ比較

簡単なプログラムを二つ用意しました。ハードコードされた機密情報がバイナリ解析ツールから抽出されてしまう危険性をちょうど勉強していた最中だったので、このようなプログラムになっています。

```c:main.c
#include <stdio.h>

void printKey() {
    const char *key = "secret_key_123";
    printf("Key: %s\n", key);
}

int main() {
    printKey();
    return 0;
}

```

```go:main.go
package main

import "fmt"

func printKey() {
	key := "secret_key_123"
	fmt.Println("Key:", key)
}

func main() {
	printKey()
}
```

## 削減方法

以下の削減方法を実施していきます。
- -ldflagsでデバッグ情報とシンボルテーブルを削除
- -trimpathでパス情報を削除
- stripで不要なメタデータの削除
- UPXで圧縮

## 実験結果

| バイナリ | サイズ | ビルドコマンド | 備考 |
| ---- | ---- | ---- | ---- |
| main_c | 32.7K | `gcc main.c -o main_c` | C |
| main_go | 1.8M | `go build -o main_go main.go` | Go ノーオプション |
| main_no_debug | 1.3M | `go build -ldflags="-s -w" -o main_no_debug main.go` | Go デバッグ情報、シンボルテーブル削除 |
| main_no_debug_path | 1.3M | `go build -ldflags="-s -w" -trimpath -o main_no_debug_path main.go` | Go デバッグ、パス情報、シンボルテーブル削除 |
| main_no_debug_path_strip | 1.2M | `cp main_no_debug_path main_no_debug_path_strip; strip main_no_debug_path_strip` | Go シンボルテーブルやその他の不要な情報を削除 |
| main_upx | 465.3K | `cp main_no_debug_path_strip main_upx; upx --best main_upx` | UPX --bestで圧縮 |
| main_lzma | 357.1K | `cp main_no_debug_path_strip main_lzma; upx --lzma main_lzma` | UPX lzmaで圧縮 |
| main_ultra_brute | 357.1K | `cp main_no_debug_path_strip main_ultra_brute; upx --ultra-brute main_ultra_brute` | UPX ultra-bruteで圧縮 |

## 結論

この実験から、Goバイナリのサイズを効果的に削減する方法についていくつかの重要なポイントが明らかになりました。以下にまとめます。

1. デバッグ情報とシンボルテーブルの削除
-ldflags="-s -w"オプションを使用してデバッグ情報とシンボルテーブルを削除することで、シンプルな例では、Goバイナリのサイズを約30％削減できました。この方法は、最も基本的かつ効果的なサイズ削減方法です。

2. パス情報の削除
-trimpathオプションを追加することで、さらにビルドパス情報を削除することができますが、サイズ削減効果はデバッグ情報とシンボルテーブルの削除に比べて限定的です。それでも、セキュリティの観点から不要な情報をバイナリに含めないことは重要です。


3. stripコマンドによる不要な情報の削除
stripコマンドを使用して、さらにシンボルテーブルや不要なメタデータを削除することで、追加のサイズ削減が可能です。これにより、バイナリサイズをさらに小さくすることができます。

4. UPXによる圧縮
UPXを使用してバイナリを圧縮することで、さらに劇的にサイズを削減できます。特に--lzmaや--ultra-bruteオプションを使用すると、バイナリサイズをGoバイナリの初期サイズの20％以下にまで縮小することができました。


効率的なビルドプロセスを自動化するためには、以下のシェルスクリプトを使用すると便利です。
```bash:build.sh
#!/bin/bash

# ビルド対象のGoファイル名
GO_FILE="main.go"

# 出力バイナリ名
OUTPUT_BIN="main"

# デバッグ情報、シンボルテーブル、パス情報を削除してビルド
echo "Building with debug and symbol table removal..."
go build -ldflags="-s -w" -trimpath -o $OUTPUT_BIN $GO_FILE

# stripコマンドでさらに不要な情報を削除
echo "Stripping the binary..."
strip $OUTPUT_BIN

# UPXでlzma圧縮
echo "Compressing with UPX (lzma)..."
upx --lzma $OUTPUT_BIN

echo "Build completed. Final binary: $OUTPUT_BIN"

```

ビルドスクリプト実行
```log:
/go/src # ./build.sh
Building with debug and symbol table removal...
Stripping the binary...
Compressing with UPX (lzma)...
                       Ultimate Packer for eXecutables
                          Copyright (C) 1996 - 2024
UPX 4.2.4       Markus Oberhumer, Laszlo Molnar & John Reiser    May 9th 2024

        File size         Ratio      Format      Name
   --------------------   ------   -----------   -----------
   1285048 ->    401400   31.24%   linux/arm64   main

Packed 1 file.
Build completed. Final binary: main
```

バイナリ実行
```log:
/go/src # ./main
Key: secret_key_123
```


## 余談
Apple M1 Pro内に`brew install upx`でインストールしたupx (バージョン: 4.1.0)を使って圧縮をしたところ、`upx: main: CantPackException: macOS is currently not supported (try --force-macos)`のエラーが発生してしまい、--force-macosオプション(非推奨かつ動作が保証されない)で強制的に圧縮したところ、圧縮は成功するものの、バイナリの実行時に強制終了してしまう不具合が発生した。
この不具合を避けるため、今回はDockerでコンテナを立ててコンテナ内にupxをダウンロード (バージョン: 4.2.4)し、圧縮を行った。
