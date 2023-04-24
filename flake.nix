{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs = inputs@{ self, nixpkgs, flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      # Only Darwin x86_64 and aaarch64 are supported, as this is a macOS-only flake.
      systems = [ "x86_64-darwin" "aarch64-darwin" ];
      perSystem = { self', pkgs, lib, config, system, ... }: {
        packages.winecx = pkgs.stdenv.mkDerivation (this: {
            name = "winecx";
            version = "22.1.0";
            depsBuildBuild = with pkgs; [ makeWrapper ];
            
            # fetchzip is redundant here, as mkDerivation's unpackPhase will unpack the tar.xz automatically.
            src = pkgs.fetchurl {
              url = "https://github.com/Gcenx/winecx/releases/download/crossover-wine-${this.version}/wine-crossover-${this.version}-osx64.tar.xz";
              sha256 = "sha256-SmN15DwuZ0pVt0bvs9hrCWz5Blqa6/qgW0KgjtAqRqA";
            };

            # mkDerivation's unpackPhase is automatically unpacking the tar.xz and setting sourceRoot to the unpacked .app,
            # but we want to be able to use the .app as-is, so we override the sourceRoot to be the main directory.
            sourceRoot = ".";

            installPhase = ''
              mkdir -p $out/Applications
              mv Wine\ Crossover.app $out/Applications/
              makeWrapper $out/Applications/Wine\ Crossover.app/Contents/Resources/wine/bin/wine64 $out/bin/wine64 \
                --prefix PATH : $out/Applications/Wine\ Crossover.app/Contents/Resources/wine/bin \
                --prefix PATH : $out/Applications/Wine\ Crossover.app/Contents/Resources/start/bin
            '';
          });

        packages.wine-staging = pkgs.stdenv.mkDerivation (this: {
            name = "wine-staging";
            version = "8.5";
            depsBuildBuild = with pkgs; [ makeWrapper ];
            
            src = pkgs.fetchurl {
              url = "https://github.com/Gcenx/macOS_Wine_builds/releases/download/${this.version}/wine-staging-${this.version}-osx64.tar.xz";
              sha256 = "sha256-R8vyLfzl5xj1NhysqS1ZVpIKiX13ly2qWoDb6aGBtkk";
            };

            sourceRoot = ".";

            installPhase = ''
              mkdir -p $out/Applications
              mv Wine\ Staging.app $out/Applications/
              makeWrapper $out/Applications/Wine\ Staging.app/Contents/Resources/wine/bin/wine64 $out/bin/wine64 \
                --prefix PATH : $out/Applications/Wine\ Staging.app/Contents/Resources/wine/bin \
                --prefix PATH : $out/Applications/Wine\ Staging.app/Contents/Resources/start/bin
            '';
          });

        packages.default = self'.packages.winecx;

        devShells.default = pkgs.mkShell {
            buildInputs = [ 
              self'.packages.default
            ];
          };
      };
    };
}
