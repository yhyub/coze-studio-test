import yaml

# 简单的YAML验证脚本
file_path = ".github/workflows/all-in-one-fixer.yml"

try:
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    print(f"Successfully read {file_path}")
    print(f"File length: {len(content)} characters")
    print(f"First 500 characters:\n{content[:500]}...")
    
    # 尝试加载YAML
    data = yaml.safe_load(content)
    print("\nYAML loaded successfully!")
    print(f"Name: {data.get('name')}")
    print(f"Has on section: { 'on' in data }")
    print(f"Has jobs section: { 'jobs' in data }")
    if 'jobs' in data:
        print(f"Jobs: {list(data['jobs'].keys())}")
    
    print("\nFile is valid!")
except Exception as e:
    print(f"Error: {type(e).__name__}: {e}")
    import traceback
    traceback.print_exc()
