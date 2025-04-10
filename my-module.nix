{ config, lib, pkgs, ... }:
{
  options.myConfig = {
    greeting = lib.mkOption {
      type = lib.types.str;
      default = "Hello, world!";
      description = "A greeting message";
    };
    configPath = lib.mkOption {
      type = lib.types.str;
      description = "Path to the config file";
    };
    scriptContent = lib.mkOption {
      type = lib.types.str;
      default = ''
        echo "Running the script..."
        cat "${config.myConfig.configPath}"
      '';
      description = "Content of a script to run";
    };
  };

  config = {
    # Default values are set above
  };
}
