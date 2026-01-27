import yaml
import os
import sys

def validate_yaml_files(directory):
    errors = []
    valid_files = []
    
    for root, dirs, files in os.walk(directory):
        for file in files:
            if file.endswith(('.yml', '.yaml')):
                file_path = os.path.join(root, file)
                try:
                    with open(file_path, 'r', encoding='utf-8') as f:
                        yaml.safe_load(f)
                    valid_files.append(file_path)
                    print(f"✅ {file_path}: Valid YAML")
                except yaml.YAMLError as e:
                    errors.append(f"{file_path}: {e}")
                    print(f"❌ {file_path}: YAML Error - {e}")
                except Exception as e:
                    errors.append(f"{file_path}: Unexpected error: {e}")
                    print(f"❌ {file_path}: Error - {e}")
    
    return valid_files, errors

def main():
    workflow_dir = '.github/workflows'
    print(f"Validating YAML files in {workflow_dir}...\n")
    
    valid_files, errors = validate_yaml_files(workflow_dir)
    
    print(f"\n{'='*60}")
    print(f"Validation Summary:")
    print(f"{'='*60}")
    print(f"✅ Valid files: {len(valid_files)}")
    print(f"❌ Errors found: {len(errors)}")
    
    if errors:
        print(f"\n❌ Errors:")
        for error in errors:
            print(f"  - {error}")
        sys.exit(1)
    else:
        print(f"\n✅ All YAML files are valid!")
        sys.exit(0)

if __name__ == "__main__":
    main()
