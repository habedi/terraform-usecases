{
  description = "Development environment for Terraform use cases";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            terraform
            awscli2
            git
            gnumake
            pre-commit
            uv
            python312
          ];

          shellHook = ''
            echo "Terraform use cases development shell loaded."
            echo "Terraform: $(terraform -version 2>/dev/null | head -n 1 || echo 'not found')"
            echo "AWS CLI: $(aws --version 2>/dev/null || echo 'not found')"
            echo "uv: $(uv --version 2>/dev/null || echo 'not found')"
          '';
        };
      }
    );
}
