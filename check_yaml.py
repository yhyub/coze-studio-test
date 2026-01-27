import yaml
import os

files_to_check = [
    '.github/workflows/ci-cd.yml',
    '.github/workflows/test.yml',
    '.github/workflows/auto-fix.yml',
    '.github/workflows/issue-summary.yml',
    '.github/workflows/actions.yaml',
    '.github/workflows/.pre-commit-config.yaml'
]

print("Validating YAML files...\n")

all_valid = True
for file_path in files_to_check:
    if os.path.exists(file_path):
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                yaml.safe_load(f)
            print(f"✅ {file_path}: Valid")
        except Exception as e:
            print(f"❌ {file_path}: Error - {e}")
            all_valid = False
    else:
        print(f"⚠️  {file_path}: File not found")

print(f"\n{'='*60}")
if all_valid:
    print("✅ All YAML files are valid!")
else:
    print("❌ Some files have errors!")
