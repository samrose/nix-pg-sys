# Nix System Configuration

A simple Nix flake that demonstrates how to create a custom system configuration using Nix modules. This project shows how to:

- Create a custom Nix module
- Build a derivation that includes both configuration files and executable scripts
- Handle path resolution between configuration files and scripts in the Nix store

## Features

- Custom greeting message configuration
- Executable script that reads from the configuration
- Proper path handling between components in the Nix store

## Usage

1. Build the package:
   ```bash
   nix build .
   ```

2. Run the greeting script:
   ```bash
   ./result/bin/run-greeting
   ```

## Project Structure

- `flake.nix`: Main flake definition
- `my-module.nix`: Custom Nix module that defines the configuration options
- `LICENSE`: MIT License
- `.gitignore`: Excludes Nix build artifacts

## How It Works

The project consists of two main components:

1. A Nix module (`my-module.nix`) that defines:
   - A greeting message
   - A config file path
   - A script that reads the greeting

2. A flake that:
   - Evaluates the module
   - Creates a derivation that installs both the config file and script
   - Ensures proper path resolution between components

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details. 