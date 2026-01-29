# GitHub Actions Fixer

![GitHub Actions Fixer](https://img.shields.io/badge/GitHub-Actions%20Fixer-green)

Automatically detects and fixes common GitHub Actions errors in workflow files.

## 🚀 Features

- **Automatic Detection**: Scans workflow files for common errors and issues
- **Smart Fixes**: Automatically fixes detected issues
- **Dry Run Mode**: Preview changes without modifying files
- **Comprehensive Coverage**: Fixes a wide range of common GitHub Actions issues
- **Easy Integration**: Simple to use in any repository

## 📋 Supported Fixes

### Action Versions
- Updates outdated action versions to the latest stable releases
- Ensures consistent versioning across workflows

### Permissions
- Fixes empty permissions sections
- Adds appropriate permissions for specific actions (e.g., `actions/deploy-pages`)

### Timeout Settings
- Increases minimum timeout values
- Ensures workflows have reasonable timeout settings

### Syntax Errors
- Fixes trailing commas in YAML
- Corrects indentation issues
- Resolves common YAML syntax errors

### Matrix Configuration
- Fixes matrix syntax issues
- Ensures proper matrix configuration format

### Environment Variables
- Fixes environment variable syntax
- Ensures consistent variable usage

## 🛠️ Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `workflows-directory` | Directory containing workflow files | No | `.github/workflows` |
| `dry-run` | Run in dry run mode (no changes made) | No | `false` |
| `verbose` | Enable verbose output | No | `false` |

## 📤 Outputs

| Output | Description |
|--------|-------------|
| `fixed-files` | List of files that were fixed |
| `errors-found` | List of errors encountered |
| `status` | Status of the fixer run |

## 📖 Usage Examples

### Basic Usage

```yaml
name: Fix GitHub Actions
on: [push, pull_request]

jobs:
  fix-actions:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout repository
        uses: actions/checkout@v4
        
      - name: Run GitHub Actions Fixer
        uses: ./.github/actions/action-fixer
```

### Dry Run Mode

```yaml
name: Check GitHub Actions
on: [push, pull_request]

jobs:
  check-actions:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout repository
        uses: actions/checkout@v4
        
      - name: Check GitHub Actions (Dry Run)
        uses: ./.github/actions/action-fixer
        with:
          dry-run: true
```

### Custom Workflows Directory

```yaml
name: Fix GitHub Actions
on: [push, pull_request]

jobs:
  fix-actions:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout repository
        uses: actions/checkout@v4
        
      - name: Run GitHub Actions Fixer
        uses: ./.github/actions/action-fixer
        with:
          workflows-directory: 'custom-workflows-directory'
```

## 🔒 Permissions

This action requires the following permissions:

```yaml
permissions:
  contents: write  # Required to modify workflow files
  actions: read    # Required to read action information
```

## 📁 Directory Structure

```
.github/actions/action-fixer/
├── action.yml     # Action configuration
├── fixer.py       # Main fixer script (Python)
├── run.sh         # Run script (Bash)
└── README.md      # This documentation
```

## 🛠️ Dependencies

- **Python 3**: Required to run the fixer script
- **PyYAML**: Required for YAML parsing

## 📝 Notes

1. **Backup Recommended**: It's recommended to backup your workflow files before running this action, especially in production repositories

2. **Review Changes**: Always review the changes made by this action to ensure they align with your repository's requirements

3. **Custom Workflows**: This action may not catch all custom workflow issues, but it will fix common problems

4. **Version Control**: The action will only modify files in the specified workflow directory

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 📞 Support

If you have any questions or issues, please open an issue in the repository.

---

Made with ❤️ by the GitHub Actions Team
