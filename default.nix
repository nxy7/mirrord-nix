{ pkgs, lib, fetchFromGitHub, makeRustPlatform, ... }:
with import <nixpkgs> {
  overlays = [
    (import (fetchTarball
      "https://github.com/oxalica/rust-overlay/archive/master.tar.gz"))
  ];
};
let
  rustPlatform = makeRustPlatform {
    cargo = rust-bin.selectLatestNightlyWith (toolchain: toolchain.default);
    rustc = rust-bin.selectLatestNightlyWith (toolchain: toolchain.default);
  };

  version = "3.74.1";

  src = fetchFromGitHub {
    owner = "metalbear-co";
    repo = "mirrord";
    rev = version;
    hash = "sha256-JJo22EXamcRymxKFQJLrzWGoKmh2J0FSu+usWMROftU=";
  };

  cargoLock = {
    lockFile = src + "/Cargo.lock";
    outputHashes = {
      "bs-filter-0.1.0" = "sha256-IxuilE2MGdM/1lfvqJ1k5blE036IZEXam6VMgZBHZsQ=";
      "containerd-client-0.3.0" =
        "sha256-eUnOe4Epze7qVuM5iyDIIoewIAnhbAvBdFagOpM3fh4=";
      "frida-build-0.2.1" =
        "sha256-MXIPudKEtqvNnekemTcULz2pZBzSWjMFhgWBr4+U8nw=";
      "hyper-1.0.0-rc.4" =
        "sha256-glfvjO+7GNH3zJIc/2ZXhF/EtjN60+z4ov3oNmfaDqg=";
      "hyper-util-0.0.0" =
        "sha256-BMW8fpLt1jg27VKa/x2MkntDs7dLnElXO12rucsc780=";
      "kube-0.86.0" = "sha256-U97BgFUIMs+pXXfA5DfjNUQ2Bf/ZU6FltTlz9rOdp4U=";
      "rasn-0.6.1" = "sha256-Pn0v+UR+gMKHMkhGTeL8bYBXoNQNnYrJ8Tluc2HVEZo=";
      "tracing-0.1.37" = "sha256-VVIVJz1+u4PqRFj1lAKGB6EbnP+b4dnimOWaNEkBAos=";
      "rawsocket-0.1.0" = "sha256-IxuilE2MGdM/1lfvqJ1k5blE036IZEXam6VMgZBHZsQ=";
    };
  };

  doCheck = false;

  frida-gum = pkgs.stdenv.mkDerivation {
    name = "copy-frida";
    src = ./fridaDeps;
    phases = [ "unpackPhase" "installPhase" ];
    installPhase = ''
      mkdir -p $out/lib
      cp $src/** $out/lib/
    '';
  };
in rustPlatform.buildRustPackage rec {
  inherit cargo version src cargoLock doCheck;
  pname = "mirrord";

  prePatch = ''
    echo prepatching
    sed -i "30s#.*#frida-gum = { git = \"https://github.com/metalbear-co/frida-rust\", version = \"0.13\", branch=\"capstone_remove\" }#" ./mirrord/layer/Cargo.toml 
    cat ./mirrord/layer/Cargo.toml 
  '';

  buildPhase = ''
    echo $PKG_CONFIG_PATH
    echo $LIBCLANG_PATH
    echo $RUSTFLAGS

    cargo build --release -p mirrord -Z bindeps --verbose
  '';

  buildInputs = [
    frida-gum
    protobuf
    pkg-config
    llvmPackages.libclang
    llvmPackages.libcxxClang
    clang
  ];
  nativeBuildInputs = with pkgs; [
    frida-gum
    protobuf
    pkg-config
    llvmPackages.libclang
    llvmPackages.libcxxClang
    clang
  ];

  PKG_CONFIG_PATH = "${frida-gum}/lib";
  LIBRARY_PATH = "${frida-gum}/lib";
  LD_LIBRARY_PATH = "${frida-gum}/lib";
  RUSTFLAGS = "-L native=${frida-gum}/lib";
  LIBCLANG_PATH = "${llvmPackages.libclang.lib}/lib";
  # BINDGEN_EXTRA_CLANG_ARGS = "-isystem ${llvmPackages.libclang.lib}/lib/clang/${
  #     lib.getVersion clang
  #   }/include";

  meta = with lib; {
    description =
      "Run your local code in the real-time context of your cloud environment, with access to other microservices, databases, queues, and managed services, all without leaving the local setup you know and love.";
    homepage = "https://mirrord.dev/";
    license = licenses.asl20;
    maintainers = with maintainers; [ ];
    mainProgram = "mirrord";
  };
}

