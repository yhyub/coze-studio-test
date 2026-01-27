import yaml

def validate_yaml(file_path):
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            # Load the YAML file
            yaml.safe_load_all(f)
        print(f"✅ {file_path} is valid YAML")
        return True
    except yaml.YAMLError as e:
        print(f"❌ {file_path} is invalid YAML: {e}")
        return False

if __name__ == "__main__":
    # Directly specify the file path
    file_path = r"c:\Users\Administrator\Desktop\fcjgfycrteas\存放\actions-config\sample-installation存放安装脚本.yml"
    validate_yaml(file_path)