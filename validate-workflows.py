import yaml
import os
import glob

# Get all workflow files
workflow_files = glob.glob('.github/workflows/*.yml') + glob.glob('.github/workflows/*.yaml')

print(f'Found {len(workflow_files)} workflow files to validate\n')

valid_files = 0
invalid_files = 0

for file_path in workflow_files:
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            yaml.safe_load(f)
        print(f'✅ {file_path} - Valid YAML')
        valid_files += 1
    except yaml.YAMLError as e:
        print(f'❌ {file_path} - Invalid YAML: {e}')
        invalid_files += 1
    except Exception as e:
        print(f'❌ {file_path} - Error: {e}')
        invalid_files += 1

print(f'\nValidation Summary:')
print(f'Valid files: {valid_files}')
print(f'Invalid files: {invalid_files}')
print(f'Total files: {len(workflow_files)}')
