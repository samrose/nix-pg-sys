# PostgreSQL Development Environment

A Nix-based PostgreSQL development environment that provides a user-managed PostgreSQL instance. This project sets up PostgreSQL 17 with a simple management interface, allowing you to run a personal PostgreSQL server for development purposes.

## Features

- PostgreSQL 17 with JIT support
- User-managed PostgreSQL instance (runs under your user account)
- Simple management script for starting/stopping the server
- Default configuration optimized for development
- Data stored in your home directory (`~/.local/share/postgresql`)

## Usage

1. Build the package:
   ```bash
   nix build .
   ```

2. Start PostgreSQL:
   ```bash
   ./result/bin/manage-postgresql start
   ```

3. Connect to PostgreSQL:
   ```bash
   psql
   ```
   This will connect to your default database (named after your username)

4. Stop PostgreSQL when done:
   ```bash
   ./result/bin/manage-postgresql stop
   ```

## Default Configuration

- Runs on port 5432
- Data directory: `~/.local/share/postgresql`
- Default database: your username
- Runs under your user account (no separate postgres user)
- Optimized settings for development:
  - max_connections = 100
  - shared_buffers = 128MB
  - effective_cache_size = 512MB
  - maintenance_work_mem = 64MB
  - And more...

## Management Commands

The `manage-postgresql` script provides these commands:
- `start`: Start the PostgreSQL server
- `stop`: Stop the PostgreSQL server
- `restart`: Restart the PostgreSQL server
- `status`: Check the server status

## Development Shell

A development shell is provided with PostgreSQL tools:
```bash
nix develop
```

## Project Structure

- `flake.nix`: Main flake definition
- `postgresql/`: PostgreSQL package definition
- `LICENSE`: MIT License
- `.gitignore`: Excludes Nix build artifacts

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details. 