# GitGuardian ggshield Pre-commit Setup

## Overview
This project uses GitGuardian's ggshield to scan for secrets before each commit.

## Installation

### 1. Install pre-commit framework
```bash
pip3 install pre-commit --user
# or
brew install pre-commit
```

### 2. Install ggshield
```bash
pip3 install ggshield --user
# or
brew install gitguardian/tap/ggshield
```

### 3. Install the git hooks
```bash
pre-commit install
```

## Usage

Once installed, the hook will automatically run on every commit:
- Scans staged files for secrets
- Blocks commits if secrets are detected
- Allows whitelisted files (like Firebase config files)

### Manual Scan
```bash
# Scan all files
ggshield secret scan repo .

# Scan specific file
ggshield secret scan path firebase/dev/GoogleService-Info.plist

# Scan with pre-commit
pre-commit run --all-files
```

## Configuration

The `.pre-commit-config.yaml` includes:
- **ggshield**: Secret scanning
- **trailing-whitespace**: Remove trailing spaces
- **end-of-file-fixer**: Ensure files end with newline
- **check-yaml**: Validate YAML syntax
- **check-added-large-files**: Prevent large files (>1MB)
- **check-merge-conflict**: Detect merge conflict markers
- **mixed-line-ending**: Ensure consistent line endings

## Whitelisting Files

If ggshield flags a false positive, add to `.gitguardian.yaml`:

```yaml
version: 2
paths-ignore:
  - android/app/google-services.json
  - firebase/dev/GoogleService-Info.plist
  - ios/Runner/GoogleService-Info.plist
```

## Bypassing (Emergency Only)

If you absolutely need to bypass the hook (NOT RECOMMENDED):
```bash
git commit --no-verify -m "commit message"
```

## Resources
- [GitGuardian ggshield](https://github.com/gitguardian/ggshield)
- [pre-commit framework](https://pre-commit.com)
