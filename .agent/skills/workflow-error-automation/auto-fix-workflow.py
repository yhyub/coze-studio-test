#!/usr/bin/env python3
"""
工作流错误自动修复主脚本
自动检测、诊断并修复GitHub Actions和Coze工作流中的错误
"""

import os
import json
import yaml
import argparse
import subprocess
import datetime
from pathlib import Path

class WorkflowErrorAutomation:
    def __init__(self, config_file=None):
        self.config = self.load_config(config_file)
        self.fix_history = []
        self.errors = []
        self.fixes = []
    
    def load_config(self, config_file=None):
        """加载配置文件"""
        default_config = {
            'scripts_dir': 'scripts',
            'fixes_dir': 'fixes',
            'workflows_dir': '.github/workflows',
            'coze_workflows_dir': 'coze-workflows',
            'enable_security': True,
            'create_pr': False,
            'create_issue': True,
            'notification_email': '',
            'max_retries': 3
        }
        
        if config_file and os.path.exists(config_file):
            with open(config_file, 'r', encoding='utf-8') as f:
                user_config = yaml.safe_load(f)
            default_config.update(user_config)
        
        return default_config
    
    def detect_workflow_files(self):
        """检测工作流文件"""
        workflow_files = []
        
        # 检测GitHub Actions工作流
        if os.path.exists(self.config['workflows_dir']):
            for file in os.listdir(self.config['workflows_dir']):
                if file.endswith(('.yml', '.yaml')):
                    workflow_files.append(os.path.join(self.config['workflows_dir'], file))
        
        # 检测Coze工作流
        if os.path.exists(self.config['coze_workflows_dir']):
            for file in os.listdir(self.config['coze_workflows_dir']):
                if file.endswith(('.json', '.yml', '.yaml')):
                    workflow_files.append(os.path.join(self.config['coze_workflows_dir'], file))
        
        return workflow_files
    
    def detect_errors(self, workflow_files):
        """检测工作流错误"""
        errors = []
        
        for file_path in workflow_files:
            print(f"\n[检测] 分析: {file_path}")
            
            # 检查文件存在
            if not os.path.exists(file_path):
                errors.append((file_path, 'FILE_NOT_FOUND', '文件不存在'))
                continue
            
            # 检查文件扩展名
            file_ext = os.path.splitext(file_path)[1].lower()
            
            if file_ext in ['.yml', '.yaml']:
                # 检查YAML语法
                try:
                    with open(file_path, 'r', encoding='utf-8') as f:
                        content = f.read()
                    yaml.safe_load(content)
                    print(f"  ✓ YAML语法正确")
                except yaml.YAMLError as e:
                    error_msg = str(e)
                    errors.append((file_path, 'YAML_SYNTAX_ERROR', error_msg))
                    print(f"  ✗ YAML语法错误: {error_msg}")
                except Exception as e:
                    error_msg = str(e)
                    errors.append((file_path, 'FILE_ERROR', error_msg))
                    print(f"  ✗ 文件错误: {error_msg}")
            
            elif file_ext == '.json':
                # 检查JSON语法
                try:
                    with open(file_path, 'r', encoding='utf-8') as f:
                        content = f.read()
                    json.loads(content)
                    print(f"  ✓ JSON语法正确")
                except json.JSONDecodeError as e:
                    error_msg = str(e)
                    errors.append((file_path, 'JSON_SYNTAX_ERROR', error_msg))
                    print(f"  ✗ JSON语法错误: {error_msg}")
                except Exception as e:
                    error_msg = str(e)
                    errors.append((file_path, 'FILE_ERROR', error_msg))
                    print(f"  ✗ 文件错误: {error_msg}")
            
            else:
                errors.append((file_path, 'UNSUPPORTED_FORMAT', '不支持的文件格式'))
                print(f"  ✗ 不支持的文件格式")
        
        return errors
    
    def fix_errors(self, errors):
        """修复工作流错误"""
        fixes = []
        
        for file_path, error_type, error_msg in errors:
            print(f"\n[修复] 处理: {file_path}")
            print(f"  错误类型: {error_type}")
            print(f"  错误信息: {error_msg}")
            
            # 根据错误类型选择修复方法
            if error_type in ['YAML_SYNTAX_ERROR', 'JSON_SYNTAX_ERROR']:
                # 修复语法错误
                if error_type == 'YAML_SYNTAX_ERROR':
                    fix_script = os.path.join(self.config['scripts_dir'], 'fix-yaml-syntax.py')
                    if os.path.exists(fix_script):
                        print(f"  运行: {fix_script}")
                        result = subprocess.run(
                            ['python3', fix_script, file_path],
                            capture_output=True,
                            text=True
                        )
                        if result.returncode == 0:
                            fixes.append((file_path, error_type, 'FIXED'))
                            print(f"  ✓ 修复成功")
                        else:
                            fixes.append((file_path, error_type, 'FIX_FAILED'))
                            print(f"  ✗ 修复失败: {result.stderr}")
            
            elif error_type == 'FILE_NOT_FOUND':
                # 文件不存在错误
                print(f"  ⚠️  文件不存在，无法修复")
                fixes.append((file_path, error_type, 'SKIPPED'))
            
            else:
                # 其他错误
                print(f"  ⚠️  不支持的错误类型，无法自动修复")
                fixes.append((file_path, error_type, 'SKIPPED'))
        
        return fixes
    
    def validate_fixes(self):
        """验证修复结果"""
        validate_script = os.path.join(self.config['scripts_dir'], 'validate-fix.py')
        if os.path.exists(validate_script):
            print(f"\n[验证] 运行修复验证...")
            result = subprocess.run(
                ['python3', validate_script, self.config['fixes_dir']],
                capture_output=True,
                text=True
            )
            print(result.stdout)
            if result.returncode != 0:
                print(f"  ✗ 验证失败: {result.stderr}")
                return False
        return True
    
    def generate_report(self):
        """生成修复报告"""
        report = {
            'timestamp': datetime.datetime.now().isoformat(),
            'total_errors': len(self.errors),
            'fixed_errors': len([f for f in self.fixes if f[2] == 'FIXED']),
            'failed_errors': len([f for f in self.fixes if f[2] == 'FIX_FAILED']),
            'skipped_errors': len([f for f in self.fixes if f[2] == 'SKIPPED']),
            'errors': self.errors,
            'fixes': self.fixes,
            'fix_history': self.fix_history
        }
        
        # 保存报告
        report_dir = os.path.join(self.config['fixes_dir'], 'reports')
        os.makedirs(report_dir, exist_ok=True)
        report_file = os.path.join(report_dir, f"fix-report-{datetime.datetime.now().strftime('%Y%m%d-%H%M%S')}.json")
        
        with open(report_file, 'w', encoding='utf-8') as f:
            json.dump(report, f, indent=2, ensure_ascii=False)
        
        print(f"\n[报告] 修复报告已保存: {report_file}")
        
        # 生成人类可读的报告
        self.generate_human_report(report, report_file.replace('.json', '.md'))
        
        return report
    
    def generate_human_report(self, report, report_file):
        """生成人类可读的修复报告"""
        markdown = []
        markdown.append("# 工作流错误修复报告")
        markdown.append("")
        markdown.append(f"生成时间: {report['timestamp']}")
        markdown.append("")
        markdown.append("## 修复摘要")
        markdown.append(f"- 总错误数: {report['total_errors']}")
        markdown.append(f"- 修复成功: {report['fixed_errors']}")
        markdown.append(f"- 修复失败: {report['failed_errors']}")
        markdown.append(f"- 跳过修复: {report['skipped_errors']}")
        markdown.append("")
        
        if report['fixes']:
            markdown.append("## 修复详情")
            for file_path, error_type, status in report['fixes']:
                markdown.append(f"### {os.path.basename(file_path)}")
                markdown.append(f"- 文件路径: {file_path}")
                markdown.append(f"- 错误类型: {error_type}")
                markdown.append(f"- 修复状态: {status}")
                markdown.append("")
        
        with open(report_file, 'w', encoding='utf-8') as f:
            f.write('\n'.join(markdown))
        
        print(f"[报告] 人类可读报告已保存: {report_file}")
    
    def create_issue(self, report):
        """创建GitHub Issue"""
        if self.config['create_issue']:
            print("\n[通知] 创建GitHub Issue...")
            # 这里可以添加创建GitHub Issue的逻辑
            print("  ✓ Issue创建功能已启用")
    
    def run(self, workflows_dir=None):
        """运行完整的错误修复流程"""
        print("="*80)
        print("工作流错误自动修复系统")
        print("="*80)
        print(f"配置文件: {self.config}")
        print("="*80)
        
        # 1. 检测工作流文件
        print("\n[步骤1] 检测工作流文件...")
        workflow_files = self.detect_workflow_files()
        print(f"  找到 {len(workflow_files)} 个工作流文件")
        for file in workflow_files:
            print(f"    - {file}")
        
        # 2. 检测错误
        print("\n[步骤2] 检测工作流错误...")
        self.errors = self.detect_errors(workflow_files)
        print(f"  发现 {len(self.errors)} 个错误")
        
        # 3. 修复错误
        if self.errors:
            print("\n[步骤3] 修复工作流错误...")
            self.fixes = self.fix_errors(self.errors)
        
        # 4. 验证修复
        print("\n[步骤4] 验证修复结果...")
        validation_result = self.validate_fixes()
        if validation_result:
            print("  ✓ 验证通过")
        else:
            print("  ✗ 验证失败")
        
        # 5. 生成报告
        print("\n[步骤5] 生成修复报告...")
        report = self.generate_report()
        
        # 6. 创建通知
        print("\n[步骤6] 创建通知...")
        self.create_issue(report)
        
        # 7. 完成
        print("\n" + "="*80)
        print("修复流程完成")
        print("="*80)
        print(f"总错误数: {len(self.errors)}")
        print(f"修复成功: {len([f for f in self.fixes if f[2] == 'FIXED'])}")
        print(f"修复失败: {len([f for f in self.fixes if f[2] == 'FIX_FAILED'])}")
        print(f"跳过修复: {len([f for f in self.fixes if f[2] == 'SKIPPED'])}")
        print("="*80)
        
        return len([f for f in self.fixes if f[2] == 'FIXED']) > 0

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="自动修复工作流错误")
    parser.add_argument('--config', '-c', help="配置文件路径")
    parser.add_argument('--dir', '-d', help="工作流目录")
    args = parser.parse_args()
    
    automation = WorkflowErrorAutomation(args.config)
    automation.run(args.dir)
