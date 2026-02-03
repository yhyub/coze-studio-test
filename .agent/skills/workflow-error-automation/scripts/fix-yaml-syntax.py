#!/usr/bin/env python3
"""
YAML语法错误修复脚本
自动检测和修复工作流文件中的YAML语法错误
"""

import yaml
import os
import re
import argparse
from pathlib import Path

class YAMLSyntaxFixer:
    def __init__(self):
        self.fixed_files = []
        self.errors = []
    
    def detect_yaml_files(self, directory):
        """检测目录中的YAML文件"""
        yaml_files = []
        for root, _, files in os.walk(directory):
            for file in files:
                if file.endswith(('.yml', '.yaml')):
                    yaml_files.append(os.path.join(root, file))
        return yaml_files
    
    def validate_yaml(self, file_path):
        """验证YAML文件语法"""
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
            yaml.safe_load(content)
            return True, ""
        except yaml.YAMLError as e:
            return False, str(e)
        except Exception as e:
            return False, f"Error reading file: {str(e)}"
    
    def fix_yaml_syntax(self, file_path):
        """修复YAML语法错误"""
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            # 修复常见的YAML语法错误
            fixes = []
            
            # 1. 修复缩进问题
            lines = content.split('\n')
            fixed_lines = []
            indent_stack = []
            
            for i, line in enumerate(lines):
                original_line = line
                
                # 去除行尾空格
                line = line.rstrip()
                
                # 跳过空行和注释
                if not line or line.strip().startswith('#'):
                    fixed_lines.append(original_line)
                    continue
                
                # 计算缩进
                indent_level = len(line) - len(line.lstrip())
                
                # 检查是否是列表项
                if line.strip().startswith('- '):
                    # 列表项应该与上一个同级元素对齐
                    if indent_stack:
                        expected_indent = indent_stack[-1]
                        if indent_level != expected_indent:
                            line = ' ' * expected_indent + line.lstrip()
                            fixes.append(f"Line {i+1}: Fixed list item indentation")
                    else:
                        indent_stack.append(indent_level)
                
                # 检查是否是键值对
                elif ':' in line and not line.strip().startswith('#'):
                    # 检查冒号后是否有空格
                    if ':' in line and not line.strip().endswith(':'):
                        parts = line.split(':', 1)
                        if len(parts) == 2 and parts[1].strip():
                            # 确保冒号后有空格
                            if not parts[1].startswith(' '):
                                line = parts[0] + ': ' + parts[1].strip()
                                fixes.append(f"Line {i+1}: Added space after colon")
                
                fixed_lines.append(line)
            
            # 2. 修复无效字符
            fixed_content = '\n'.join(fixed_lines)
            
            # 3. 修复多行字符串格式
            fixed_content = re.sub(r'\|\s*$', '|', fixed_content)
            
            # 4. 修复重复键
            # 简单的重复键检测
            try:
                yaml.safe_load(fixed_content)
            except yaml.YAMLError:
                # 尝试修复重复键
                fixed_content = self._fix_duplicate_keys(fixed_content)
                fixes.append("Fixed duplicate keys")
            
            # 验证修复结果
            try:
                yaml.safe_load(fixed_content)
                # 保存修复后的文件
                fixed_file_path = os.path.join(
                    os.path.dirname(os.path.dirname(file_path)),
                    'fixes',
                    os.path.basename(file_path)
                )
                
                # 确保fixes目录存在
                os.makedirs(os.path.dirname(fixed_file_path), exist_ok=True)
                
                with open(fixed_file_path, 'w', encoding='utf-8') as f:
                    f.write(fixed_content)
                
                return True, fixes
            except yaml.YAMLError as e:
                return False, [f"Failed to fix: {str(e)}"]
                
        except Exception as e:
            return False, [f"Error fixing file: {str(e)}"]
    
    def _fix_duplicate_keys(self, content):
        """修复重复键"""
        # 简单的重复键修复：保留最后一个值
        lines = content.split('\n')
        key_lines = {}
        fixed_lines = []
        
        for i, line in enumerate(lines):
            if ':' in line and not line.strip().startswith('#') and not line.strip().startswith('- '):
                key = line.split(':', 1)[0].strip()
                if key:
                    key_lines[key] = i
        
        # 标记重复键
        seen_keys = set()
        for i, line in enumerate(lines):
            if ':' in line and not line.strip().startswith('#') and not line.strip().startswith('- '):
                key = line.split(':', 1)[0].strip()
                if key and key in seen_keys:
                    # 添加注释标记重复键
                    fixed_lines.append(f"# DUPLICATE_KEY: {line}")
                else:
                    fixed_lines.append(line)
                    seen_keys.add(key)
            else:
                fixed_lines.append(line)
        
        return '\n'.join(fixed_lines)
    
    def run(self, directory):
        """运行修复过程"""
        print(f"Scanning directory: {directory}")
        yaml_files = self.detect_yaml_files(directory)
        print(f"Found {len(yaml_files)} YAML files")
        
        for file_path in yaml_files:
            print(f"\nProcessing: {file_path}")
            is_valid, error_msg = self.validate_yaml(file_path)
            
            if is_valid:
                print("  ✓ YAML syntax is valid")
            else:
                print(f"  ✗ YAML syntax error: {error_msg}")
                print("  Attempting to fix...")
                
                success, fixes = self.fix_yaml_syntax(file_path)
                if success:
                    print("  ✓ Fix successful!")
                    for fix in fixes:
                        print(f"    - {fix}")
                    self.fixed_files.append(file_path)
                else:
                    print("  ✗ Fix failed!")
                    for error in fixes:
                        print(f"    - {error}")
                    self.errors.append((file_path, fixes))
        
        print("\n" + "="*60)
        print("SUMMARY")
        print("="*60)
        print(f"Fixed files: {len(self.fixed_files)}")
        print(f"Failed files: {len(self.errors)}")
        
        if self.fixed_files:
            print("\nFixed files:")
            for file in self.fixed_files:
                print(f"  - {file}")
        
        if self.errors:
            print("\nFailed files:")
            for file, errors in self.errors:
                print(f"  - {file}")
                for error in errors:
                    print(f"    - {error}")
        
        return self.fixed_files, self.errors

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Fix YAML syntax errors in workflow files")
    parser.add_argument('directory', nargs='?', default='.', help="Directory to scan for YAML files")
    args = parser.parse_args()
    
    fixer = YAMLSyntaxFixer()
    fixer.run(args.directory)
