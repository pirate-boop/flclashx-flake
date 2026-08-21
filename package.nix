{ pkgs, lib, stdenv, fetchurl, dpkg, autoPatchelfHook }:

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
  
  nativeBuildInputs = [ dpkg autoPatchelfHook ];
  
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
    
    mkdir -p $out/bin $out/share/applications $out/share/icons
    cp -r ./* $out/
    
    MAIN_BIN=$(find $out -type f -executable -iname "flclashx" | grep -vi "core" | head -n 1)
    if [ -z "$MAIN_BIN" ]; then
      MAIN_BIN=$(find $out -type f -executable ! -iname "*core*" ! -name "*.so*" ! -name "*.so.*" | head -n 1)
    fi
    
    if [ -n "$MAIN_BIN" ]; then
      cat > $out/bin/flclashx << 'WRAPPER_EOF'
#!/bin/sh
export XDG_DATA_HOME="''${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_CONFIG_HOME="''${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_CACHE_HOME="''${XDG_CACHE_HOME:-$HOME/.cache}"
exec BINARY_PATH_PLACEHOLDER "$@"
WRAPPER_EOF
      
      chmod +x $out/bin/flclashx
      sed -i "s|BINARY_PATH_PLACEHOLDER|$MAIN_BIN|" $out/bin/flclashx
    else
      echo "ERROR: No executable found!"
      exit 1
    fi
    
    runHook postInstall
  '';
  
  meta = with lib; {
    description = "A fork of the multi-platform proxy client FlClash, based on Mihomo Core";
    homepages = [ "https://github.com/pluralplay/FlClashX" ];
    license = licenses.gpl3;
    platforms = platforms.linux;
    mainProgram = "flclashx";
    sourceProvenance = with sourceTypes; [ binaryNativeCode ];
  };
}
