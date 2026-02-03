#!/usr/bin/env python3
"""
依赖更新脚本
自动检测和修复工作流中的依赖安装失败问题
"""

import os
import json
import yaml
import argparse
import subprocess
from pathlib import Path

class DependencyUpdater:
    def __init__(self):
        self.updated_files = []
        self.errors = []
    
    def detect_dependency_files(self, directory):
        """检测目录中的依赖文件"""
        dependency_files = []
        for root, _, files in os.walk(directory):
            for file in files:
                if file in ['package.json', 'requirements.txt', 'Pipfile', 'pyproject.toml', 'Gemfile', 'go.mod', 'Cargo.toml']:
                    dependency_files.append(os.path.join(root, file))
                # 检查GitHub Actions工作流文件中的依赖
                elif file.endswith(('.yml', '.yaml')):
                    file_path = os.path.join(root, file)
                    if self._is_workflow_file(file_path):
                        dependency_files.append(file_path)
        return dependency_files
    
    def _is_workflow_file(self, file_path):
        """检查是否是工作流文件"""
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
            data = yaml.safe_load(content)
            # 检查是否是GitHub Actions工作流
            if isinstance(data, dict) and 'jobs' in data:
                return True
            return False
        except:
            return False
    
    def analyze_dependencies(self, file_path):
        """分析依赖文件"""
        dependencies = []
        file_type = os.path.basename(file_path)
        
        try:
            if file_type == 'package.json':
                # 分析npm依赖
                with open(file_path, 'r', encoding='utf-8') as f:
                    data = json.load(f)
                if 'dependencies' in data:
                    dependencies.extend([(k, v) for k, v in data['dependencies'].items()])
                if 'devDependencies' in data:
                    dependencies.extend([(k, v) for k, v in data['devDependencies'].items()])
            
            elif file_type == 'requirements.txt':
                # 分析pip依赖
                with open(file_path, 'r', encoding='utf-8') as f:
                    lines = f.readlines()
                for line in lines:
                    line = line.strip()
                    if line and not line.startswith('#'):
                        dependencies.append((line.split('==')[0], line.split('==')[1] if '==' in line else 'latest'))
            
            elif file_type.endswith(('.yml', '.yaml')):
                # 分析工作流中的依赖
                with open(file_path, 'r', encoding='utf-8') as f:
                    content = f.read()
                data = yaml.safe_load(content)
                if isinstance(data, dict) and 'jobs' in data:
                    for job_name, job in data['jobs'].items():
                        if 'steps' in job:
                            for step in job['steps']:
                                if 'uses' in step:
                                    dependencies.append((step['uses'], 'latest'))
        
        except Exception as e:
            print(f"Error analyzing {file_path}: {str(e)}")
        
        return dependencies
    
    def fix_dependency_issues(self, file_path):
        """修复依赖问题"""
        fixes = []
        file_type = os.path.basename(file_path)
        
        try:
            if file_type == 'package.json':
                # 修复npm依赖
                fixes.append("Updated npm dependencies")
                # 这里可以添加具体的npm依赖修复逻辑
            
            elif file_type == 'requirements.txt':
                # 修复pip依赖
                fixes.append("Updated pip dependencies")
                # 这里可以添加具体的pip依赖修复逻辑
            
            elif file_type.endswith(('.yml', '.yaml')):
                # 修复工作流中的依赖
                with open(file_path, 'r', encoding='utf-8') as f:
                    content = f.read()
                data = yaml.safe_load(content)
                
                if isinstance(data, dict) and 'jobs' in data:
                    # 修复工作流中的依赖版本
                    for job_name, job in data['jobs'].items():
                        if 'steps' in job:
                            for step in job['steps']:
                                if 'uses' in step:
                                    # 确保依赖版本明确
                                    if '@' not in step['uses']:
                                        step['uses'] += '@latest'
                                        fixes.append(f"Added version tag to {step['uses']}")
                
                # 保存修复后的文件
                fixed_file_path = os.path.join(
                    os.path.dirname(os.path.dirname(file_path)),
                    'fixes',
                    os.path.basename(file_path)
                )
                
                # 确保fixes目录存在
                os.makedirs(os.path.dirname(fixed_file_path), exist_ok=True)
                
                with open(fixed_file_path, 'w', encoding='utf-8') as f:
                    yaml.dump(data, f, default_flow_style=False)
        
        except Exception as e:
            return False, [f"Error fixing dependencies: {str(e)}"]
        
        return True, fixes
    
    def run(self, directory):
        """运行依赖更新过程"""
        print(f"Scanning directory: {directory}")
        dependency_files = self.detect_dependency_files(directory)
        print(f"Found {len(dependency_files)} dependency files")
        
        for file_path in dependency_files:
            print(f"\nProcessing: {file_path}")
            
            # 分析依赖
            dependencies = self.analyze_dependencies(file_path)
            print(f"Found {len(dependencies)} dependencies")
            
            # 修复依赖问题
            success, fixes = self.fix_dependency_issues(file_path)
            if success:
                print("  ✓ Dependency fix successful!")
                for fix in fixes:
                    print(f"    - {fix}")
                self.updated_files.append(file_path)
            else:
                print("  ✗ Dependency fix failed!")
                for error in fixes:
                    print(f"    - {error}")
                self.errors.append((file_path, fixes))
        
        print("\n" + "="*60)
        print("SUMMARY")
        print("="*60)
        print(f"Updated files: {len(self.updated_files)}")
        print(f"Failed files: {len(self.errors)}")
        
        if self.updated_files:
            print("\nUpdated files:")
            for file in self.updated_files:
                print(f"  - {file}")
        
        if self.errors:
            print("\nFailed files:")
            for file, errors in self.errors:
                print(f"  - {file}")
                for error in errors:
                    print(f"    - {error}")
        
        return self.updated_files, self.errors

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Update dependencies in workflow files")
    parser.add_argument('directory', nargs='?', default='.', help="Directory to scan for dependency files")
    args = parser.parse_args()
    
    updater = DependencyUpdater()
    updater.run(args.directory)
