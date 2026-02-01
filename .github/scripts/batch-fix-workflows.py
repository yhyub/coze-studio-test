#!/usr/bin/env python3
import os
import re

def fix_workflow_file(filepath):
    """修复单个工作流文件"""
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
        
        original_content = content
        fixes_applied = []
        
        # 1. 添加缺失的 permissions 配置
        if 'permissions:' not in content:
            # 找到合适的位置插入 permissions
            if 'on:' in content:
                lines = content.split('\n')
                new_lines = []
                for i, line in enumerate(lines):
                    new_lines.append(line)
                    # 找到 on: 部分的结束
                    if line.strip() and not line.startswith(' ') and not line.startswith('  '):
                        if 'on:' in '\n'.join(new_lines) and line.strip() != 'on:':
                            # 插入 permissions 配置
                            new_lines.insert(i, '')
                            new_lines.insert(i+1, 'permissions:')
                            new_lines.insert(i+2, '  contents: read')
                            new_lines.insert(i+3, '  actions: read')
                            new_lines.insert(i+4, '  issues: read')
                            new_lines.insert(i+5, '  pull-requests: read')
                            new_lines.insert(i+6, '  workflows: read')
                            fixes_applied.append('添加了基本权限配置')
                            break
                content = '\n'.join(new_lines)
        
        # 2. 添加缺失的 workflows 权限
        if 'permissions:' in content and 'workflows:' not in content:
            lines = content.split('\n')
            new_lines = []
            in_permissions = False
            for line in lines:
                new_lines.append(line)
                if line.strip() == 'permissions:':
                    in_permissions = True
                elif in_permissions and line.strip() and not line.startswith(' ') and not line.startswith('  '):
                    # 权限部分结束，检查是否需要添加 workflows 权限
                    if not any('workflows:' in l for l in new_lines):
                        # 在权限部分末尾添加 workflows 权限
                        for j in range(len(new_lines)-1, -1, -1):
                            if new_lines[j].strip() == 'permissions:':
                                # 找到权限部分的末尾
                                k = j + 1
                                while k < len(new_lines) and (new_lines[k].startswith(' ') or new_lines[k].startswith('  ')):
                                    k += 1
                                new_lines.insert(k-1, '  workflows: read')
                                fixes_applied.append('添加了 workflows 权限')
                                break
                    break
            content = '\n'.join(new_lines)
        
        # 3. 修复 checkout 动作版本
        if 'actions/checkout@' in content:
            # 将旧版本更新为 v4
            content = re.sub(r'actions/checkout@v[0-9]+', 'actions/checkout@v4', content)
            fixes_applied.append('更新了 checkout 动作版本')
        
        # 4. 修复 setup-node 动作版本
        if 'actions/setup-node@' in content:
            # 将旧版本更新为 v5
            content = re.sub(r'actions/setup-node@v[0-9]+', 'actions/setup-node@v5', content)
            fixes_applied.append('更新了 setup-node 动作版本')
        
        # 5. 修复 setup-python 动作版本
        if 'actions/setup-python@' in content:
            # 将旧版本更新为 v5
            content = re.sub(r'actions/setup-python@v[0-9]+', 'actions/setup-python@v5', content)
            fixes_applied.append('更新了 setup-python 动作版本')
        
        # 6. 添加超时设置
        if 'timeout-minutes:' not in content and 'runs-on:' in content:
            lines = content.split('\n')
            new_lines = []
            for i, line in enumerate(lines):
                new_lines.append(line)
                if 'runs-on:' in line:
                    # 在 runs-on: 行后添加超时设置
                    new_lines.insert(i+1, '    timeout-minutes: 30')
                    fixes_applied.append('添加了超时设置')
                    break
            content = '\n'.join(new_lines)
        
        # 只在内容变化时写入
        if content != original_content:
            with open(filepath, 'w', encoding='utf-8') as f:
                f.write(content)
            return fixes_applied
        else:
            return []

def main():
    """主函数"""
    workflow_dir = os.path.join('.github', 'workflows')
    
    if not os.path.exists(workflow_dir):
        print(f"Directory {workflow_dir} does not exist")
        return
    
    print(f"Fixing workflow files in {workflow_dir}...")
    
    fixed_files = []
    total_fixes = 0
    
    for filename in os.listdir(workflow_dir):
        if filename.endswith('.yml') or filename.endswith('.yaml'):
            filepath = os.path.join(workflow_dir, filename)
            print(f"\nProcessing: {filename}")
            
            fixes = fix_workflow_file(filepath)
            if fixes:
                fixed_files.append(filename)
                total_fixes += len(fixes)
                print(f"Applied fixes:")
                for fix in fixes:
                    print(f"  - {fix}")
            else:
                print("No fixes needed")
    
    print(f"\n=== Summary ===")
    print(f"Fixed {len(fixed_files)} files")
    print(f"Applied {total_fixes} fixes in total")
    
    if fixed_files:
        print(f"\nFixed files:")
        for file in fixed_files:
            print(f"- {file}")

if __name__ == "__main__":
    main()
