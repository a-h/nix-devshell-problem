{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";
  };
  outputs = { self, nixpkgs }:
    let
      allSystems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forAllSystems = f: nixpkgs.lib.genAttrs allSystems (system: f {
        pkgs = import nixpkgs { inherit system; };
      });
      hello = pkgs: pkgs.stdenv.mkDerivation {
        name = "hello";
        src = ./.;
        buildPhase = ''
        '';
        installPhase = ''
          mkdir -p $out/bin
          cp hello.sh $out/bin/hello
          chmod +x $out/bin/hello
        '';
        buildInputs = [ pkgs.bash ];
      };

      devTools = { pkgs }: [
        pkgs.sl # The highly useful `sl` command...
      ];
    in
    {
      packages = forAllSystems ({ pkgs }: {
        default = hello pkgs;
      });
      devShells = forAllSystems ({ pkgs }: {
        default = pkgs.mkShell {
          buildInputs = (devTools { pkgs = pkgs; });
        };
      });
    };
}
