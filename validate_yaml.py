import yaml

try:
    with open('.github/workflows/新建文本文档.yml', 'r', encoding='utf-8') as f:
        content = f.read()
        yaml.safe_load(content)
    print('YAML syntax is valid!')
except Exception as e:
    print('Error:', e)
    import traceback
    traceback.print_exc()