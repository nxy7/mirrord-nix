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
in rustPlatform.buildRustPackage rec {
  inherit cargo;
  pname = "mirrord";
  version = "3.68.0";

  src = fetchFromGitHub {
    owner = "metalbear-co";
    repo = "mirrord";
    rev = "${version}";
    hash = "sha256-63qJhje5YjeX55OIwMFk+qkbNgaZ6Nr1tL+GCbByzoY=";
  };
  cargoBuildFlags = [ "-Z bindeps" ];

  cargoLock.lockFile = "${src}/Cargo.lock";

  cargoLock.outputHashes = {
    "bs-filter-0.1.0" = "sha256-IxuilE2MGdM/1lfvqJ1k5blE036IZEXam6VMgZBHZsQ=";
    "containerd-client-0.3.0" =
      "sha256-eUnOe4Epze7qVuM5iyDIIoewIAnhbAvBdFagOpM3fh4=";
    "frida-build-0.2.1" = "sha256-MXIPudKEtqvNnekemTcULz2pZBzSWjMFhgWBr4+U8nw=";
    "hyper-1.0.0-rc.4" = "sha256-glfvjO+7GNH3zJIc/2ZXhF/EtjN60+z4ov3oNmfaDqg=";
    "hyper-util-0.0.0" = "sha256-BMW8fpLt1jg27VKa/x2MkntDs7dLnElXO12rucsc780=";
    "rasn-0.6.1" = "sha256-Pn0v+UR+gMKHMkhGTeL8bYBXoNQNnYrJ8Tluc2HVEZo=";
    "tracing-0.1.37" = "sha256-VVIVJz1+u4PqRFj1lAKGB6EbnP+b4dnimOWaNEkBAos=";
  };
  nativeBuildInputs = with pkgs; [ protobuf frida-tools pkg-config ];

  meta = with lib; {
    description =
      "Run your local code in the real-time context of your cloud environment, with access to other microservices, databases, queues, and managed services, all without leaving the local setup you know and love.";
    homepage = "https://mirrord.dev/";
    license = licenses.asl20;
    maintainers = with maintainers; [ ];
    mainProgram = "mirrord";
  };
}

