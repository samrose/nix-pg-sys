{ config, lib, pkgs, ... }:
{
  options.steps = {
    enable = lib.mkEnableOption "Enable custom steps execution";

    port = lib.mkOption {
      type = lib.types.port;
      description = "PostgreSQL port to connect to";
    };

    database = lib.mkOption {
      type = lib.types.str;
      description = "PostgreSQL database name to connect to";
    };

    dbUser = lib.mkOption {
      type = lib.types.str;
      description = "PostgreSQL database user";
    };

    commands = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "List of shell commands to execute";
      example = [
        "psql -U ${config.steps.dbUser} -d ${config.steps.database} -p ${toString config.steps.port} -c \"CREATE TABLE example (id SERIAL PRIMARY KEY, name VARCHAR(255));\""
        "psql -U ${config.steps.dbUser} -d ${config.steps.database} -p ${toString config.steps.port} -c \"\\d example\""
      ];
    };
  };

  config = lib.mkIf config.steps.enable {
    # You could add additional logic here if needed, e.g., assertions or environment setup
  };
}