{
  description = "Reproducible bootstrap environment for syscode-pi-agent-kit";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs =
    { nixpkgs, ... }:
    let
      systems = [
        "aarch64-darwin"
        "x86_64-darwin"
        "aarch64-linux"
        "x86_64-linux"
      ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
      safehouseFor =
        pkgs:
        pkgs.stdenvNoCC.mkDerivation {
          pname = "agent-safehouse";
          version = "0.10.1";

          src = pkgs.fetchurl {
            url = "https://github.com/eugene1g/agent-safehouse/releases/download/v0.10.1/safehouse.sh";
            hash = "sha256-vwboTXShHc2zzscpNyi3jfj3Cjz/3RletKyLhrUUJkI=";
          };

          dontUnpack = true;

          installPhase = ''
            runHook preInstall
            install -Dm755 "$src" "$out/bin/safehouse"
            runHook postInstall
          '';
        };
      specstoryFor =
        system: pkgs:
        let
          release = {
            aarch64-darwin = {
              asset = "SpecStoryCLI_Darwin_arm64.tar.gz";
              hash = "sha256-xse5k+lq0jldauhB4fM64O27eIkJ548nt0hn+uA85lQ=";
            };
            x86_64-darwin = {
              asset = "SpecStoryCLI_Darwin_x86_64.tar.gz";
              hash = "sha256-8kJXx5pRJMjx5boy1zHq/Lma8bTkQ5t6dvHK0tThNJE=";
            };
            aarch64-linux = {
              asset = "SpecStoryCLI_Linux_arm64.tar.gz";
              hash = "sha256-fYg8x3IZNRkn9YSMOGKH3v1mIFGeWtEDO/QNEdTlhaY=";
            };
            x86_64-linux = {
              asset = "SpecStoryCLI_Linux_x86_64.tar.gz";
              hash = "sha256-DGSslmCoiq9lXO6zvOl/dpRPFJWPiX1Jw8eadwFeDTg=";
            };
          }.${system};
        in
        pkgs.stdenvNoCC.mkDerivation {
          pname = "specstory";
          version = "1.13.0";

          src = pkgs.fetchurl {
            url = "https://github.com/specstoryai/getspecstory/releases/download/v1.13.0/${release.asset}";
            inherit (release) hash;
          };

          unpackPhase = ''
            runHook preUnpack
            tar -xzf "$src"
            runHook postUnpack
          '';

          installPhase = ''
            runHook preInstall
            install -Dm755 specstory "$out/bin/specstory"
            runHook postInstall
          '';
        };
    in
    {
      packages = forAllSystems (
        system:
        let
          pkgs = import nixpkgs { inherit system; };
        in
        {
          safehouse = safehouseFor pkgs;
          specstory = specstoryFor system pkgs;
        }
      );

      devShells = forAllSystems (
        system:
        let
          pkgs = import nixpkgs { inherit system; };
        in
        {
          default = pkgs.mkShell {
            packages = with pkgs; [
              curl
              git
              gitleaks
              jq
              mise
              nodejs_24
              ripgrep
              tmux
              (safehouseFor pkgs)
              (specstoryFor system pkgs)
            ];

            shellHook = ''
              echo "Run: mise run bootstrap"
            '';
          };
        }
      );
    };
}
