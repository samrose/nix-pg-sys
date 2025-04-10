{
  description = "PostgreSQL configuration with Nix modules and steps";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];

      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f system);

      mkPostgresqlConfig = system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          lib = pkgs.lib;

          postgresqlPkg = (import ./postgresql) pkgs;

          platformSettings = if lib.hasSuffix "darwin" system then {
            effective_io_concurrency = "0";
          } else {
            effective_io_concurrency = "200";
          };

          # Evaluate both the PostgreSQL and steps modules
          config = lib.evalModules {
            modules = [
              ./postgresql-module.nix
              ./steps-module.nix
              {
                _module.args.pkgs = pkgs;
                postgresql = {
                  enable = true;
                  package = postgresqlPkg.postgresql_17;
                  dataDir = "postgresql-datadir";
                  port = 5433;
                  settings = {
                    max_connections = "100";
                    shared_buffers = "128MB";
                    effective_cache_size = "512MB";
                    maintenance_work_mem = "64MB";
                    checkpoint_completion_target = "0.9";
                    wal_buffers = "4MB";
                    default_statistics_target = "100";
                    random_page_cost = "1.1";
                    work_mem = "4MB";
                    min_wal_size = "1GB";
                    max_wal_size = "4GB";
                  } // platformSettings;
                };
                steps = {
                  enable = true;
                  port = config.config.postgresql.port;
                  database = "postgres";
                  dbUser = "samrose";  # Default database user
                  commands = [
                    "psql -U ${config.config.steps.dbUser} -d ${config.config.steps.database} -p ${toString config.config.postgresql.port} -c \"CREATE TABLE example (id SERIAL PRIMARY KEY, name VARCHAR(255));\""
                    "psql -U ${config.config.steps.dbUser} -d ${config.config.steps.database} -p ${toString config.config.postgresql.port} -c \"\\d example\""
                  ];
                };
              }
            ];
          };

          postgresqlConfigOutput = pkgs.stdenv.mkDerivation {
            name = "postgresql-config";
            src = ./.;
            buildInputs = [ pkgs.bash postgresqlPkg.postgresql_17 ];

            buildPhase = ''
              mkdir -p $out/etc $out/bin

              # Write the PostgreSQL configuration
              cat > $out/etc/postgresql.conf <<EOF
              # PostgreSQL configuration generated by Nix
              port = ${toString config.config.postgresql.port}
              data_directory = '${config.config.postgresql.dataDir}'
              ${lib.concatStringsSep "\n" (lib.mapAttrsToList (name: value: "${name} = ${value}") config.config.postgresql.settings)}
              EOF

              # Write a script to manage PostgreSQL and execute steps
              cat > $out/bin/manage-postgresql <<EOF
              #!/bin/sh
              
              case "\$1" in
                start)
                  mkdir -p "${config.config.postgresql.dataDir}"
                  chmod 700 "${config.config.postgresql.dataDir}"
                  if [ ! -e "${config.config.postgresql.dataDir}/PG_VERSION" ]; then
                    ${postgresqlPkg.postgresql_17}/bin/initdb -D "${config.config.postgresql.dataDir}" --no-locale
                  fi
                  ${postgresqlPkg.postgresql_17}/bin/pg_ctl -D "${config.config.postgresql.dataDir}" -o "-c config_file=$out/etc/postgresql.conf" start
                  # Execute steps if enabled
                  ${lib.optionalString config.config.steps.enable ''
                    psql -U ${config.config.steps.dbUser} -d ${config.config.steps.database} -p ${toString config.config.postgresql.port} -c "CREATE TABLE example (id SERIAL PRIMARY KEY, name VARCHAR(255));"
                    psql -U ${config.config.steps.dbUser} -d ${config.config.steps.database} -p ${toString config.config.postgresql.port} -c "\\d example"
                  ''}
                  ;;
                stop)
                  ${postgresqlPkg.postgresql_17}/bin/pg_ctl -D "${config.config.postgresql.dataDir}" stop
                  ;;
                restart)
                  ${postgresqlPkg.postgresql_17}/bin/pg_ctl -D "${config.config.postgresql.dataDir}" -o "-c config_file=$out/etc/postgresql.conf" restart
                  ;;
                status)
                  ${postgresqlPkg.postgresql_17}/bin/pg_ctl -D "${config.config.postgresql.dataDir}" status
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
          packages.default = postgresqlConfigOutput;
          devShells.default = pkgs.mkShell {
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
    in
    {
      packages = forAllSystems (system: (mkPostgresqlConfig system).packages);
      devShells = forAllSystems (system: (mkPostgresqlConfig system).devShells);
    };
}
