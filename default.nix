{ lib, fetchFromGitHub, rustPlatform }:

rustPlatform.buildRustPackage rec {
  pname = "mirrord";
  version = "3.68.0";

  src = fetchFromGitHub {
    owner = "metalbear-co";
    repo = "mirrord";
    rev = "${version}";
    hash = lib.fakeHash;
  };

  vendorHash = lib.fakeHash;

  meta = with lib; {
    description =
      "Run your local code in the real-time context of your cloud environment, with access to other microservices, databases, queues, and managed services, all without leaving the local setup you know and love.";
    homepage = "https://mirrord.dev/";
    license = licenses.asl20;
    maintainers = with maintainers; [ nxyt ];
    mainProgram = "mirrord";
  };
}

