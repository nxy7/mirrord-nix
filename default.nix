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

  version = "3.72.0";

  src = fetchFromGitHub {
    owner = "metalbear-co";
    repo = "mirrord";
    rev = version;
    hash = "sha256-rtDvVQd3qoiQFNoYDcSZZBx3/VONZPNxJJQTcfR/KSo=";
  };

  cargoLock = {
    lockFile = src + "/Cargo.lock";
    outputHashes = {
      # bs-filter is actually part of the rawsocket git source
      "bs-filter-0.1.0" = "sha256-IxuilE2MGdM/1lfvqJ1k5blE036IZEXam6VMgZBHZsQ=";
      # this is the "rust-extensions" derivation
      "containerd-client-0.3.0" =
        "sha256-eUnOe4Epze7qVuM5iyDIIoewIAnhbAvBdFagOpM3fh4=";
      "frida-build-0.2.1" =
        "sha256-MXIPudKEtqvNnekemTcULz2pZBzSWjMFhgWBr4+U8nw=";
      "hyper-1.0.0-rc.4" =
        "sha256-glfvjO+7GNH3zJIc/2ZXhF/EtjN60+z4ov3oNmfaDqg=";
      "hyper-util-0.0.0" =
        "sha256-BMW8fpLt1jg27VKa/x2MkntDs7dLnElXO12rucsc780=";
      "kube-0.86.0" = "sha256-IN6viKcyIw3odWwMX1VIH7epmOj7FPynO+XDI/24l60=";
      "rasn-0.6.1" = "sha256-Pn0v+UR+gMKHMkhGTeL8bYBXoNQNnYrJ8Tluc2HVEZo=";
      "tracing-0.1.37" = "sha256-VVIVJz1+u4PqRFj1lAKGB6EbnP+b4dnimOWaNEkBAos=";
      "rawsocket-0.1.0" = "sha256-IxuilE2MGdM/1lfvqJ1k5blE036IZEXam6VMgZBHZsQ=";
    };
  };

  doCheck = false;

  frida-gum_hack = pkgs.stdenv.mkDerivation {
    name = "copy-frida";
    src = ./fridaDeps;
    phases = [ "installPhase" ];
    installPhase = ''
      mkdir -p $out/lib
      cp $src/frida-gum.h $out/lib
      cp $src/libfrida-gum.a $out/lib
    '';
  };
  systemConfiguration = lib.optionals stdenv.isDarwin
    [ pkgs.darwin.apple_sdk.frameworks.SystemConfiguration ];

  mirrord-layer = rustPlatform.buildRustPackage {
    inherit version src cargoLock doCheck;

    pname = "mirrord-layer";

    cargoBuildFlags = [ "-p" "mirrord-layer" ];

    buildInputs = systemConfiguration ++ [ frida-gum_hack ];

    nativeBuildInputs = with pkgs; [ protobuf ];
  };
in rustPlatform.buildRustPackage rec {
  inherit cargo version src cargoLock doCheck;
  pname = "mirrord";
  cargoBuildFlags = [ "-p mirrord" "-Z bindeps" ];

  buildInputs = [ mirrord-layer frida-gum_hack ];
  nativeBuildInputs = with pkgs; [ protobuf frida-tools pkg-config ];

  MIRRORD_LAYER_FILE = if stdenv.isDarwin then
    "${mirrord-layer}/lib/libmirrord_layer.dylib"
  else
    "${mirrord-layer}/lib/libmirrord_layer.so";

  meta = with lib; {
    description =
      "Run your local code in the real-time context of your cloud environment, with access to other microservices, databases, queues, and managed services, all without leaving the local setup you know and love.";
    homepage = "https://mirrord.dev/";
    license = licenses.asl20;
    maintainers = with maintainers; [ ];
    mainProgram = "mirrord";
  };
}

