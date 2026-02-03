import yaml
import os
import sys

def validate_file(file_path):
    """验证单个文件"""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        yaml.safe_load(content)
        return True, None
    except Exception as e:
        return False, str(e)

def main():
    """验证所有工作流程文件"""
    workflow_dir = ".github/workflows"
    
    if not os.path.exists(workflow_dir):
        print(f"错误: 目录 {workflow_dir} 不存在")
        return 1
    
    files = [f for f in os.listdir(workflow_dir) if f.endswith('.yml') or f.endswith('.yaml')]
    total = len(files)
    valid = 0
    invalid = 0
    
    print(f"验证 {total} 个工作流程文件...")
    print("=" * 80)
    
    for file in files:
        file_path = os.path.join(workflow_dir, file)
        is_valid, error = validate_file(file_path)
        
        if is_valid:
            print(f"✅ {file}")
            valid += 1
        else:
            print(f"❌ {file}")
            print(f"   错误: {error}")
            invalid += 1
        print("-" * 80)
    
    print("=" * 80)
    print(f"验证结果: {valid} 个有效, {invalid} 个无效")
    
    if invalid > 0:
        return 1
    else:
        print("🎉 所有工作流程文件都有效!")
        return 0

if __name__ == "__main__":
    sys.exit(main())
