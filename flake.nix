{
  description = "Custom nix build with modules, no flake-utils";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      # Specify the system explicitly
      system = "aarch64-darwin"; # Change this to your system if needed (e.g., "aarch64-linux")
      pkgs = nixpkgs.legacyPackages.${system};
      lib = pkgs.lib;

      # Evaluate the modules
      config = lib.evalModules {
        modules = [
          ./my-module.nix
          {
            _module.args.pkgs = pkgs; # Pass pkgs to modules
            myConfig.configPath = "$out/etc/greeting.conf"; # Pass the config path
          }
        ];
      };

      # Build a derivation from the evaluated config
      myConfigOutput = pkgs.stdenv.mkDerivation {
        name = "my-custom-config";
        src = pkgs.runCommand "empty" {} "mkdir $out"; # Empty source directory
        buildInputs = [ pkgs.bash ]; # Tools needed for build

        buildPhase = ''
          mkdir -p $out/etc $out/bin

          # Write the config file from the module
          echo "${config.config.myConfig.greeting}" > $out/etc/greeting.conf

          # Write a script from the module
          cat > $out/bin/run-greeting <<EOF
          #!/bin/sh
          ${config.config.myConfig.scriptContent}
          EOF
          chmod +x $out/bin/run-greeting
        '';

        installPhase = "true";
      };

    in
    {
      # Define outputs without flake-utils
      packages.${system}.default = myConfigOutput;

      # Optional: devShell for testing
      devShells.${system}.default = pkgs.mkShell {
        buildInputs = [ pkgs.bash ];
        shellHook = ''
          echo "Build with: nix build ."
          echo "Result will be in ./result"
        '';
      };
    };
}