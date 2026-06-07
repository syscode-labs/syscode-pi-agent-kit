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
      leanCtxFor =
        system: pkgs:
        let
          release = {
            aarch64-darwin = {
              asset = "lean-ctx-aarch64-apple-darwin.tar.gz";
              hash = "sha256-v6V/tzM5begn6w94JDv+j64kVSZ9TxExH/NdQxjiPXc=";
            };
            x86_64-darwin = {
              asset = "lean-ctx-x86_64-apple-darwin.tar.gz";
              hash = "sha256-b0dRvGLUpy3jPH/k/xA2GufOqaTIbbzhBj10+bpTtTY=";
            };
            aarch64-linux = {
              asset = "lean-ctx-aarch64-unknown-linux-gnu.tar.gz";
              hash = "sha256-BOl9x9H7cfbeiWGMTckEleQe3l98egrlBiKjGOpas9k=";
            };
            x86_64-linux = {
              asset = "lean-ctx-x86_64-unknown-linux-gnu.tar.gz";
              hash = "sha256-xYav5kEUFCuuNgtcJ/NhjS++T4K6Sz4GQglvM7Jo5NM=";
            };
          }.${system};
        in
        pkgs.stdenvNoCC.mkDerivation {
          pname = "lean-ctx";
          version = "3.7.5";

          src = pkgs.fetchurl {
            url = "https://github.com/yvgude/lean-ctx/releases/download/v3.7.5/${release.asset}";
            inherit (release) hash;
          };

          dontUnpack = true;

          installPhase = ''
            runHook preInstall
            tar -xzf "$src" lean-ctx
            install -Dm755 lean-ctx "$out/bin/lean-ctx"
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
          lean-ctx = leanCtxFor system pkgs;
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
              (leanCtxFor system pkgs)
            ];

            shellHook = ''
              echo "Run: mise run bootstrap"
            '';
          };
        }
      );
    };
}
