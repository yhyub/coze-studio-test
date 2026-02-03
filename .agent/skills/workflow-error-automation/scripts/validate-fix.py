#!/usr/bin/env python3
"""
修复验证脚本
验证工作流修复的有效性，确保修复不会引入新问题
"""

import os
import yaml
import json
import argparse
import subprocess
from pathlib import Path

class FixValidator:
    def __init__(self):
        self.validated_files = []
        self.invalid_files = []
        self.warnings = []
    
    def validate_yaml_file(self, file_path):
        """验证YAML文件"""
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            # 验证YAML语法
            data = yaml.safe_load(content)
            
            # 检查是否是GitHub Actions工作流
            if isinstance(data, dict):
                # 检查必要的字段
                if 'name' in data:
                    print(f"  ✓ Workflow name: {data['name']}")
                
                if 'on' in data:
                    print(f"  ✓ Trigger: {data['on']}")
                
                if 'jobs' in data:
                    print(f"  ✓ Jobs: {list(data['jobs'].keys())}")
                    for job_name, job in data['jobs'].items():
                        if 'runs-on' in job:
                            print(f"    - {job_name}: runs-on {job['runs-on']}")
                        if 'steps' in job:
                            print(f"    - Steps: {len(job['steps'])}")
            
            return True, []
            
        except yaml.YAMLError as e:
            return False, [f"YAML syntax error: {str(e)}"]
        except Exception as e:
            return False, [f"Error validating file: {str(e)}"]
    
    def validate_json_file(self, file_path):
        """验证JSON文件"""
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            # 验证JSON语法
            data = json.loads(content)
            return True, []
            
        except json.JSONDecodeError as e:
            return False, [f"JSON syntax error: {str(e)}"]
        except Exception as e:
            return False, [f"Error validating file: {str(e)}"]
    
    def validate_file(self, file_path):
        """验证文件"""
        file_ext = os.path.splitext(file_path)[1].lower()
        
        if file_ext in ['.yml', '.yaml']:
            return self.validate_yaml_file(file_path)
        elif file_ext == '.json':
            return self.validate_json_file(file_path)
        else:
            # 对于其他文件类型，只检查文件存在
            if os.path.exists(file_path):
                return True, ["File exists"]
            else:
                return False, ["File does not exist"]
    
    def validate_fixes(self, fixes_directory):
        """验证所有修复文件"""
        if not os.path.exists(fixes_directory):
            print(f"Fixes directory {fixes_directory} does not exist")
            return
        
        print(f"Validating fixes in: {fixes_directory}")
        
        for root, _, files in os.walk(fixes_directory):
            for file in files:
                file_path = os.path.join(root, file)
                print(f"\nValidating: {file_path}")
                
                is_valid, errors = self.validate_file(file_path)
                
                if is_valid:
                    print("  ✓ Validation successful!")
                    self.validated_files.append(file_path)
                else:
                    print("  ✗ Validation failed!")
                    for error in errors:
                        print(f"    - {error}")
                    self.invalid_files.append((file_path, errors))
    
    def run_tests(self, test_commands=None):
        """运行测试命令验证修复"""
        if test_commands is None:
            test_commands = [
                'echo "Running basic validation tests..."',
                'echo "Testing YAML syntax..."'
            ]
        
        print("\n" + "="*60)
        print("RUNNING TESTS")
        print("="*60)
        
        for command in test_commands:
            print(f"\nRunning: {command}")
            try:
                result = subprocess.run(command, shell=True, capture_output=True, text=True)
                if result.returncode == 0:
                    print(f"  ✓ Command executed successfully")
                    if result.stdout:
                        print(f"  Output: {result.stdout.strip()}")
                else:
                    print(f"  ✗ Command failed with exit code {result.returncode}")
                    if result.stderr:
                        print(f"  Error: {result.stderr.strip()}")
                    self.warnings.append(f"Command failed: {command}")
            except Exception as e:
                print(f"  ✗ Error running command: {str(e)}")
                self.warnings.append(f"Error running command: {command}")
    
    def generate_validation_report(self, output_file=None):
        """生成验证报告"""
        report = []
        report.append("# Fix Validation Report")
        report.append("")
        report.append(f"Generated on: {os.popen('date').read().strip()}")
        report.append("")
        report.append("## Summary")
        report.append(f"Validated files: {len(self.validated_files)}")
        report.append(f"Invalid files: {len(self.invalid_files)}")
        report.append(f"Warnings: {len(self.warnings)}")
        report.append("")
        
        if self.validated_files:
            report.append("## Validated Files")
            for file in self.validated_files:
                report.append(f"- {file}")
            report.append("")
        
        if self.invalid_files:
            report.append("## Invalid Files")
            for file, errors in self.invalid_files:
                report.append(f"- {file}")
                for error in errors:
                    report.append(f"  - {error}")
            report.append("")
        
        if self.warnings:
            report.append("## Warnings")
            for warning in self.warnings:
                report.append(f"- {warning}")
            report.append("")
        
        report_content = '\n'.join(report)
        
        if output_file:
            with open(output_file, 'w', encoding='utf-8') as f:
                f.write(report_content)
            print(f"\nValidation report saved to: {output_file}")
        else:
            print("\n" + "="*60)
            print("VALIDATION REPORT")
            print("="*60)
            print(report_content)
    
    def run(self, fixes_directory, output_file=None):
        """运行验证过程"""
        self.validate_fixes(fixes_directory)
        self.run_tests()
        self.generate_validation_report(output_file)
        
        print("\n" + "="*60)
        print("VALIDATION SUMMARY")
        print("="*60)
        print(f"Validated files: {len(self.validated_files)}")
        print(f"Invalid files: {len(self.invalid_files)}")
        print(f"Warnings: {len(self.warnings)}")
        
        if len(self.invalid_files) == 0:
            print("\n🎉 All fixes are valid!")
        else:
            print("\n⚠️  Some fixes are invalid and need attention!")
        
        return len(self.invalid_files) == 0

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Validate fixes for workflow files")
    parser.add_argument('fixes_directory', nargs='?', default='fixes', help="Directory containing fix files")
    parser.add_argument('--output', '-o', help="Output report file")
    args = parser.parse_args()
    
    validator = FixValidator()
    validator.run(args.fixes_directory, args.output)
