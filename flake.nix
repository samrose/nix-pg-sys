{
  description = "PostgreSQL configuration with Nix modules";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      # Specify the system explicitly
      system = "aarch64-darwin"; # Change this to your system if needed (e.g., "aarch64-linux")
      pkgs = nixpkgs.legacyPackages.${system};
      lib = pkgs.lib;

      # Import PostgreSQL package
      postgresqlPkg = (import ./postgresql) pkgs;

      # PostgreSQL configuration
      postgresqlConfig = {
        enable = true;
        package = postgresqlPkg.postgresql_17;
        dataDir = "~/.local/share/postgresql";
        port = 5432;
        settings = {
          max_connections = "100";
          shared_buffers = "128MB";
          effective_cache_size = "512MB";
          maintenance_work_mem = "64MB";
          checkpoint_completion_target = "0.9";
          wal_buffers = "4MB";
          default_statistics_target = "100";
          random_page_cost = "1.1";
          effective_io_concurrency = "200";
          work_mem = "4MB";
          min_wal_size = "1GB";
          max_wal_size = "4GB";
        };
      };

      # Build a derivation from the config
      postgresqlConfigOutput = pkgs.stdenv.mkDerivation {
        name = "postgresql-config";
        src = pkgs.runCommand "empty" {} "mkdir $out"; # Empty source directory
        buildInputs = [ pkgs.bash postgresqlPkg.postgresql_17 ];

        buildPhase = ''
          mkdir -p $out/etc $out/bin

          # Write the PostgreSQL configuration
          cat > $out/etc/postgresql.conf <<EOF
          ${lib.concatStringsSep "\n" (lib.mapAttrsToList (name: value: "${name} = ${value}") postgresqlConfig.settings)}
          EOF

          # Write a script to manage PostgreSQL
          cat > $out/bin/manage-postgresql <<EOF
          #!/bin/sh
          case "\$1" in
            start)
              mkdir -p "${postgresqlConfig.dataDir}"
              chmod 700 "${postgresqlConfig.dataDir}"
              if [ ! -e "${postgresqlConfig.dataDir}/PG_VERSION" ]; then
                ${postgresqlPkg.postgresql_17}/bin/initdb -D "${postgresqlConfig.dataDir}"
              fi
              ${postgresqlPkg.postgresql_17}/bin/pg_ctl -D "${postgresqlConfig.dataDir}" start
              ;;
            stop)
              ${postgresqlPkg.postgresql_17}/bin/pg_ctl -D "${postgresqlConfig.dataDir}" stop
              ;;
            restart)
              ${postgresqlPkg.postgresql_17}/bin/pg_ctl -D "${postgresqlConfig.dataDir}" restart
              ;;
            status)
              ${postgresqlPkg.postgresql_17}/bin/pg_ctl -D "${postgresqlConfig.dataDir}" status
              ;;
            *)
              echo "Usage: \$0 {start|stop|restart|status}"
              exit 1
              ;;
          esac
          EOF
          chmod +x $out/bin/manage-postgresql
        '';

        installPhase = "true";
      };

    in
    {
      # Define outputs without flake-utils
      packages.${system}.default = postgresqlConfigOutput;

      # Optional: devShell for testing
      devShells.${system}.default = pkgs.mkShell {
        buildInputs = [ 
          pkgs.bash 
          postgresqlPkg.postgresql_17
        ];
        shellHook = ''
          echo "Build with: nix build ."
          echo "Result will be in ./result"
          echo "PostgreSQL version: ${postgresqlPkg.postgresql_17.version}"
        '';
      };
    };
}