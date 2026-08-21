#!/usr/bin/env bash
set -e

VERSION="${1:-0.4.2}"
echo "Обновление FlClashX до $VERSION..."

AMD64_URL="https://github.com/pluralplay/FlClashX/releases/download/v${VERSION}/FlClashX-linux-amd64.deb"
ARM64_URL="https://github.com/pluralplay/FlClashX/releases/download/v${VERSION}/FlClashX-linux-arm64.deb"

echo "Получение хешей..."

# Получаем чистый base32 хеш и удаляем любые случайные префиксы или кавычки
RAW_AMD64=$(nix-prefetch-url "$AMD64_URL" 2>/dev/null | tail -n 1 | tr -d '\r\n\'"'"' ')
RAW_ARM64=$(nix-prefetch-url "$ARM64_URL" 2>/dev/null | tail -n 1 | tr -d '\r\n\'"'"' ')

AMD64_HASH="${RAW_AMD64#sha256-}"
ARM64_HASH="${RAW_ARM64#sha256-}"

echo "AMD64: $AMD64_HASH"
echo "ARM64: $ARM64_HASH"

# Обновляем версию и хеши по маркерам
sed -i "s/version = \"[^\"]*\"/version = \"$VERSION\"/" package.nix
sed -i "s|x86_64-linux = \"[^\"]*\"; # AMD64_HASH_MARKER|x86_64-linux = \"$AMD64_HASH\"; # AMD64_HASH_MARKER|" package.nix
sed -i "s|aarch64-linux = \"[^\"]*\"; # ARM64_HASH_MARKER|aarch64-linux = \"$ARM64_HASH\"; # ARM64_HASH_MARKER|" package.nix

echo "Готово. Запускай: nix build .#flclashx"
