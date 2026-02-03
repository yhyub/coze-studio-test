#!/usr/bin/env python3
"""
工作流文件验证器

融合了以下脚本的功能：
- validate-workflows.ps1: 验证所有工作流文件的语法
- validate-workflows.py: 使用Python的yaml模块验证YAML文件
- validate-yaml.py: 详细验证单个YAML文件并显示信息
- simple-validate.js: 简单检查文件可读性
- simple-validate.py: 详细显示文件信息和YAML加载结果

功能特点：
- 验证所有工作流文件的语法
- 详细显示文件信息
- 安全的错误处理
- 支持命令行参数
- 提供详细的验证报告
- 跨平台兼容
- 模块依赖检查
- 友好的错误提示
"""

import os
import sys
import argparse
from datetime import datetime

# 尝试导入yaml模块
try:
    import yaml
    has_yaml = True
except ImportError:
    has_yaml = False
    print("Warning: PyYAML module not found. Basic file validation only.")


def validate_file(file_path):
    """
    验证单个YAML文件
    
    Args:
        file_path: 文件路径
    
    Returns:
        tuple: (是否有效, 错误信息, 文件信息)
    """
    try:
        # 检查文件是否存在
        if not os.path.exists(file_path):
            return False, f"File does not exist", {}
        
        # 检查文件可读性
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # 获取文件信息
        file_info = {
            'name': os.path.basename(file_path),
            'size': len(content),
            'lines': len(content.split('\n')),
            'readable': True
        }
        
        # 验证YAML语法（如果yaml模块可用）
        if has_yaml:
            try:
                data = yaml.safe_load(content)
                
                # 获取工作流信息
                if data:
                    file_info['name_field'] = data.get('name')
                    file_info['has_on'] = 'on' in data
                    file_info['has_jobs'] = 'jobs' in data
                    if 'jobs' in data:
                        file_info['jobs'] = list(data['jobs'].keys())
                
                return True, None, file_info
            except Exception as yaml_error:
                return False, f"YAML syntax error: {type(yaml_error).__name__}: {yaml_error}", file_info
        else:
            # 如果yaml模块不可用，只进行基本文件验证
            file_info['yaml_validation'] = 'Skipped (PyYAML not installed)'
            return True, None, file_info
        
    except Exception as e:
        return False, f"{type(e).__name__}: {e}", {}


def validate_workflows(workflows_dir):
    """
    验证工作流目录中的所有YAML文件
    
    Args:
        workflows_dir: 工作流目录路径
    
    Returns:
        dict: 验证结果
    """
    results = {
        'total': 0,
        'valid': 0,
        'invalid': 0,
        'errors': [],
        'details': []
    }
    
    # 检查目录是否存在
    if not os.path.exists(workflows_dir):
        print(f"Error: Directory '{workflows_dir}' does not exist")
        return results
    
    # 获取所有YAML文件
    yaml_files = []
    for filename in os.listdir(workflows_dir):
        if filename.endswith('.yml') or filename.endswith('.yaml'):
            yaml_files.append(os.path.join(workflows_dir, filename))
    
    results['total'] = len(yaml_files)
    
    # 验证每个文件
    for file_path in yaml_files:
        print(f"\nValidating {os.path.basename(file_path)}...")
        print(f"File: {file_path}")
        
        is_valid, error, file_info = validate_file(file_path)
        
        # 显示文件信息
        if file_info:
            print(f"  Size: {file_info.get('size')} bytes")
            print(f"  Lines: {file_info.get('lines')}")
            print(f"  Readable: {'Yes' if file_info.get('readable') else 'No'}")
            
            if 'yaml_validation' in file_info:
                print(f"  YAML Validation: {file_info.get('yaml_validation')}")
            elif has_yaml:
                print(f"  YAML Validation: Performed")
            else:
                print(f"  YAML Validation: Skipped (PyYAML not installed)")
            
            if 'name_field' in file_info:
                print(f"  Workflow Name: {file_info.get('name_field')}")
            if 'has_on' in file_info:
                print(f"  Has 'on' section: {'Yes' if file_info.get('has_on') else 'No'}")
            if 'has_jobs' in file_info:
                print(f"  Has 'jobs' section: {'Yes' if file_info.get('has_jobs') else 'No'}")
            if 'jobs' in file_info:
                print(f"  Jobs: {', '.join(file_info.get('jobs', []))}")
        
        # 显示验证结果
        if is_valid:
            print(f"  ✓ Valid YAML")
            results['valid'] += 1
            results['details'].append({
                'file': file_path,
                'valid': True,
                'info': file_info
            })
        else:
            print(f"  ✗ Invalid YAML: {error}")
            results['invalid'] += 1
            results['errors'].append({
                'file': file_path,
                'error': error
            })
            results['details'].append({
                'file': file_path,
                'valid': False,
                'error': error,
                'info': file_info
            })
    
    return results


def main():
    """
    主函数
    """
    # 解析命令行参数
    parser = argparse.ArgumentParser(description='Validate GitHub Actions workflow files')
    parser.add_argument('--dir', default='.github/workflows', help='Workflow directory path')
    parser.add_argument('--file', help='Single file to validate')
    parser.add_argument('--verbose', action='store_true', help='Enable verbose output')
    args = parser.parse_args()
    
    print(f"===========================================")
    print(f"Workflow Validator")
    print(f"Date: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print(f"===========================================")
    
    # 验证单个文件
    if args.file:
        print(f"Validating single file: {args.file}")
        is_valid, error, file_info = validate_file(args.file)
        
        if is_valid:
            print(f"\n✓ File is valid!")
            if file_info:
                print(f"\nFile Information:")
                print(f"  Name: {file_info.get('name')}")
                print(f"  Size: {file_info.get('size')} bytes")
                print(f"  Lines: {file_info.get('lines')}")
                
                if 'yaml_validation' in file_info:
                    print(f"  YAML Validation: {file_info.get('yaml_validation')}")
                elif has_yaml:
                    print(f"  YAML Validation: Performed")
                else:
                    print(f"  YAML Validation: Skipped (PyYAML not installed)")
                
                if 'name_field' in file_info:
                    print(f"  Workflow Name: {file_info.get('name_field')}")
                if 'jobs' in file_info:
                    print(f"  Jobs: {', '.join(file_info.get('jobs', []))}")
            sys.exit(0)
        else:
            print(f"\n✗ Error: {error}")
            sys.exit(1)
    
    # 验证目录中的所有文件
    workflows_dir = args.dir
    print(f"Validating workflows in directory: {workflows_dir}")
    
    results = validate_workflows(workflows_dir)
    
    # 显示验证报告
    print(f"\n===========================================")
    print(f"Validation Report")
    print(f"===========================================")
    print(f"Total files: {results['total']}")
    print(f"Valid files: {results['valid']}")
    print(f"Invalid files: {results['invalid']}")
    
    if results['errors']:
        print(f"\nErrors found:")
        for error_info in results['errors']:
            print(f"  - {os.path.basename(error_info['file'])}: {error_info['error']}")
        print(f"\nValidation failed!")
        sys.exit(1)
    else:
        print(f"\n✓ All workflow files are valid!")
        sys.exit(0)


if __name__ == '__main__':
    main()
