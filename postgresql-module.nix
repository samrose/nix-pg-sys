{ config, lib, pkgs, ... }:
{
  options.postgresql = {
    enable = lib.mkEnableOption "Enable PostgreSQL service";
    
    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.postgresql_17;
      description = "PostgreSQL package to use";
    };

    dataDir = lib.mkOption {
      type = lib.types.str;
      default = "~/.local/share/postgresql";
      description = "PostgreSQL data directory";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 5432;
      description = "PostgreSQL port";
    };

    settings = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = {
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
      description = "PostgreSQL configuration settings";
    };
  };

  config = lib.mkIf config.postgresql.enable {
    # No NixOS-specific options here
  };
} 