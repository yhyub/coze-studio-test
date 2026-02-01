#!/usr/bin/env python3
"""
YAML Syntax Fixer

This script fixes common YAML syntax errors in workflow files.

Copyright 2025 coze-dev Authors

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
"""

import yaml
import re
import sys

def fix_common_yaml_errors(content):
    """修复常见的YAML语法错误"""
    fixes_applied = []
    
    # 修复1: 缺失的引号
    pattern = r'(\w+):\s*([^#\n]+?)(?=\s+[\w-]+:|\s*#|\s*$)'
    
    def add_quotes(match):
        key = match.group(1)
        value = match.group(2).strip()
        if ' ' in value and not (value.startswith('"') or value.startswith("'")):
            fixes_applied.append(f"为 {key} 的值添加引号")
            return f'{key}: "{value}"'
        return match.group(0)
    
    content = re.sub(pattern, add_quotes, content, flags=re.MULTILINE)
    
    # 修复2: 不正确的缩进
    lines = content.split('\n')
    fixed_lines = []
    indent_stack = [0]
    
    for line in lines:
        if line.strip() and not line.strip().startswith('#'):
            indent = len(line) - len(line.lstrip())
            if indent > indent_stack[-1] + 2:  # 缩进跳变太大
                fixed_indent = indent_stack[-1] + 2
                fixes_applied.append(f"修正缩进: {line.strip()[:30]}...")
                line = ' ' * fixed_indent + line.lstrip()
            elif line.strip().startswith('- '):
                indent_stack.append(indent)
        fixed_lines.append(line)
    
    return '\n'.join(fixed_lines), fixes_applied

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("用法: python fix-yaml-syntax.py <yaml文件路径>")
        sys.exit(1)
    
    filepath = sys.argv[1]
    
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            original = f.read()
        
        fixed, fixes = fix_common_yaml_errors(original)
        
        if fixes:
            with open(filepath, 'w', encoding='utf-8') as f:
                f.write(fixed)
            print(f"修复已应用: {', '.join(fixes)}")
        else:
            print("未发现可自动修复的YAML错误")
    except Exception as e:
        print(f"处理文件时出错: {e}")
        sys.exit(1)