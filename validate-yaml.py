import yaml
import os

workflows_dir = '.github/workflows'
invalid_files = []

print('Validating workflow files...')
print('-' * 50)

for file in os.listdir(workflows_dir):
    if file.endswith('.yml') or file.endswith('.yaml'):
        file_path = os.path.join(workflows_dir, file)
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                yaml.safe_load(f)
            print(f'✓ {file} is valid')
        except Exception as e:
            print(f'✗ {file} is invalid: {e}')
            invalid_files.append(file)

print('-' * 50)
if invalid_files:
    print(f'Found {len(invalid_files)} invalid files:')
    for file in invalid_files:
        print(f'  - {file}')
    exit(1)
else:
    print('All workflow files are valid!')
    exit(0)
