{ pkgs, lib, stdenv, fetchurl, dpkg, autoPatchelfHook, makeWrapper }:

let
  version = "0.4.2";
  
  urls = {
    x86_64-linux = "https://github.com/pluralplay/FlClashX/releases/download/v${version}/FlClashX-linux-amd64.deb";
    aarch64-linux = "https://github.com/pluralplay/FlClashX/releases/download/v${version}/FlClashX-linux-arm64.deb";
  };
  
  hashes = {
    x86_64-linux = "100qqnda7m9acffjhrrh7cf6z86byvsqjlnkcrl99zf9zccga562";
    aarch64-linux = "1pab5dnfinr6i7yama1bmfd19b4siaxv6pxfi1p7vbsmz3mk5v1k";
  };
  
  url = urls.${stdenv.hostPlatform.system} or (throw "Unsupported system: ${stdenv.hostPlatform.system}");
  hash = hashes.${stdenv.hostPlatform.system} or (throw "No hash for system: ${stdenv.hostPlatform.system}");

in
stdenv.mkDerivation rec {
  pname = "flclashx";
  inherit version;
  
  src = fetchurl {
    inherit url;
    sha256 = hash;
  };
  
  nativeBuildInputs = [ dpkg autoPatchelfHook makeWrapper ];
  
  buildInputs = with pkgs; [
    stdenv.cc.cc.lib libGL libxkbcommon wayland
    libx11 libxcomposite libxdamage libxext
    libxfixes libxrandr libxcb libxcursor
    libxi gtk3 nss nspr at-spi2-atk libdrm expat
    libxtst libxscrnsaver
    libayatana-appindicator
    libayatana-indicator
    libdbusmenu
    keybinder3
  ];
  
  unpackPhase = ''
    dpkg-deb -x $src .
  '';
  
  installPhase = ''
    runHook preInstall

    # Создаём целевые директории
    mkdir -p $out/bin $out/share/applications $out/share/icons

    # Копируем всё содержимое .deb
    cp -r ./* $out/

    # === ГЛАВНОЕ: переносим .desktop и иконки туда, где их ищет Nix ===
    if [ -d "$out/usr/share/applications" ]; then
      mv $out/usr/share/applications/*.desktop $out/share/applications/ 2>/dev/null || true
      rm -rf $out/usr/share/applications
    fi

    if [ -d "$out/usr/share/icons" ]; then
      cp -r $out/usr/share/icons/* $out/share/icons/ 2>/dev/null || true
      rm -rf $out/usr/share/icons
    fi

    # Чистим остатки пустых usr/
    rm -rf $out/usr 2>/dev/null || true

    # Ищем основной бинарник
    MAIN_BIN=$(find $out -type f -executable -iname "flclashx" | grep -vi "core" | head -n 1)
    if [ -z "$MAIN_BIN" ]; then
      MAIN_BIN=$(find $out -type f -executable ! -iname "*core*" ! -name "*.so*" ! -name "*.so.*" | head -n 1)
    fi

    if [ -z "$MAIN_BIN" ]; then
      echo "ERROR: No executable found!"
      exit 1
    fi

    # Создаём wrapper через makeWrapper (правильный Nix-способ)
    makeWrapper "$MAIN_BIN" "$out/bin/flclashx" \
      --set XDG_DATA_HOME "''${XDG_DATA_HOME:-$HOME/.local/share}" \
      --set XDG_CONFIG_HOME "''${XDG_CONFIG_HOME:-$HOME/.config}" \
      --set XDG_CACHE_HOME "''${XDG_CACHE_HOME:-$HOME/.cache}"

    # Патчим пути внутри .desktop файла
    for desktop in $out/share/applications/*.desktop; do
      if [ -f "$desktop" ]; then
        substituteInPlace "$desktop" \
          --replace-fail "/usr/bin/flclashx" "$out/bin/flclashx" \
          --replace-fail "/opt/" "$out/opt/" \
          --replace-fail "Exec=flclashx" "Exec=$out/bin/flclashx" \
          --replace-fail "Exec=/usr/bin/flclashx" "Exec=$out/bin/flclashx"
      fi
    done

    # Если .desktop файла не оказалось в .deb — создаём вручную
    if [ ! -f "$out/share/applications/flclashx.desktop" ] && [ ! -f "$out/share/applications/FlClashX.desktop" ]; then
      cat > $out/share/applications/flclashx.desktop << 'EOF'
[Desktop Entry]
Name=FlClashX
Comment=A fork of the multi-platform proxy client FlClash, based on Mihomo Core
Exec=flclashx
Icon=flclashx
Type=Application
Categories=Network;
Terminal=false
EOF
    fi

    runHook postInstall
  '';
  
  meta = with lib; {
    description = "A fork of the multi-platform proxy client FlClash, based on Mihomo Core";
    homepage = "https://github.com/pluralplay/FlClashX";
    license = licenses.gpl3;
    platforms = platforms.linux;
    mainProgram = "flclashx";
    sourceProvenance = with sourceTypes; [ binaryNativeCode ];
  };
}
