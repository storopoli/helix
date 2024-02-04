{
  description = "Personal Helix";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs = inputs@{ self, nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
        };

        cfg = pkgs.runCommand "helix-config" { } ''
          mkdir -p $out/helix/config
          cp ${./.}/helix/config.toml $out/helix/config.toml
          cp ${./.}/helix/languages.toml $out/helix/languages.toml
        '';

        hx = pkgs.writeShellScriptBin "hx" ''
          # I would prefer not to use this env var
          # but https://github.com/helix-editor/helix/discussions/8160
          # helix people seem people opinionated and I can't be fucked going in
          # to have a chat about that again
          XDG_CONFIG_HOME=${cfg} ${pkgs.helix}/bin/hx $@
        '';
      in
      rec {

        # leaving this here in case I want to override anything else..
        helix = hx;

        overlays.default = final: prev: {
          helix = self.packages.${final.system}.default;
        };

        nixosModules.hm = {
          imports = [
            { nixpkgs.overlays = [ overlays.default ]; }
          ];
        };

        packages = {
          default = helix;
        };

        apps = rec {
          helix = {
            type = "app";
            program = "${packages.default}/bin/hx";
          };
          default = helix;
        };

        devShells.default = pkgs.mkShell {
          buildInputs = [ helix ];
        };
      }
    );
}
