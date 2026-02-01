#!/usr/bin/env python3
import os
import re

def fix_workflow_permissions(workflow_dir):
    """修复工作流文件的权限配置"""
    fixed_files = []
    
    for filename in os.listdir(workflow_dir):
        if filename.endswith('.yml') or filename.endswith('.yaml'):
            filepath = os.path.join(workflow_dir, filename)
            
            try:
                with open(filepath, 'r', encoding='utf-8') as f:
                    content = f.read()
                
                original_content = content
                
                # 检查是否有 permissions 配置
                if 'permissions:' not in content:
                    # 添加基本权限配置
                    # 找到 on: 部分后的位置插入 permissions
                    if 'on:' in content:
                        # 找到 on: 部分的结束位置
                        lines = content.split('\n')
                        new_lines = []
                        for i, line in enumerate(lines):
                            new_lines.append(line)
                            # 找到 on: 部分的结束（下一个顶级键）
                            if line.strip() and not line.startswith(' ') and not line.startswith('  ') and 'on:' in new_lines:
                                # 检查是否已经是下一个顶级键
                                if line.strip() != 'on:' and i > 0 and lines[i-1].strip() != 'on:':
                                    # 插入 permissions 配置
                                    new_lines.insert(i, '')
                                    new_lines.insert(i+1, 'permissions:')
                                    new_lines.insert(i+2, '  contents: read')
                                    new_lines.insert(i+3, '  actions: read')
                                    new_lines.insert(i+4, '  issues: read')
                                    new_lines.insert(i+5, '  pull-requests: read')
                                    break
                        content = '\n'.join(new_lines)
                else:
                    # 检查并修复现有权限配置
                    # 确保有必要的权限
                    if 'workflows:' not in content:
                        # 找到 permissions: 部分并添加 workflows 权限
                        lines = content.split('\n')
                        new_lines = []
                        in_permissions = False
                        for line in lines:
                            new_lines.append(line)
                            if line.strip() == 'permissions:':
                                in_permissions = True
                            elif in_permissions and line.strip() and not line.startswith(' ') and not line.startswith('  '):
                                # 权限部分结束，检查是否添加了 workflows 权限
                                if not any('workflows:' in l for l in new_lines[-10:]):
                                    # 在权限部分结束前添加 workflows 权限
                                    for i in range(len(new_lines)-1, -1, -1):
                                        if new_lines[i].strip() == 'permissions:':
                                            # 在 permissions: 后添加 workflows 权限
                                            new_lines.insert(i+1, '  workflows: read')
                                            break
                                in_permissions = False
                        content = '\n'.join(new_lines)
                
                # 只在内容变化时写入
                if content != original_content:
                    with open(filepath, 'w', encoding='utf-8') as f:
                        f.write(content)
                    fixed_files.append(filename)
                    print(f"Fixed permissions in: {filename}")
                    
            except Exception as e:
                print(f"Error processing {filename}: {e}")
    
    return fixed_files

if __name__ == "__main__":
    workflow_dir = os.path.join('.github', 'workflows')
    
    if not os.path.exists(workflow_dir):
        print(f"Directory {workflow_dir} does not exist")
        exit(1)
    
    print("Fixing workflow permissions...")
    fixed = fix_workflow_permissions(workflow_dir)
    
    if fixed:
        print(f"\nFixed permissions in {len(fixed)} files:")
        for file in fixed:
            print(f"- {file}")
    else:
        print("\nNo files needed permission fixes")
