#!/usr/bin/env python3
"""
GitHub Actions Fixer

This script detects and fixes common GitHub Actions errors in workflow files.
"""

import os
import re
import sys
import yaml
from pathlib import Path

class ActionFixer:
    def __init__(self, workflows_dir=".github/workflows", dry_run=False):
        self.workflows_dir = Path(workflows_dir)
        self.dry_run = dry_run
        self.fixed_files = []
        self.errors_found = []
        
    def run(self):
        """Run the fixer on all workflow files"""
        print(f"🔍 Scanning workflow files in {self.workflows_dir}")
        
        if not self.workflows_dir.exists():
            print(f"❌ Directory {self.workflows_dir} does not exist")
            return False
        
        workflow_files = list(self.workflows_dir.glob("*.yml")) + list(self.workflows_dir.glob("*.yaml"))
        
        if not workflow_files:
            print(f"ℹ️ No workflow files found in {self.workflows_dir}")
            return True
        
        print(f"📁 Found {len(workflow_files)} workflow files")
        
        for workflow_file in workflow_files:
            print(f"\n📄 Processing {workflow_file.name}")
            try:
                self.process_workflow_file(workflow_file)
            except Exception as e:
                print(f"❌ Error processing {workflow_file.name}: {e}")
                self.errors_found.append(f"{workflow_file.name}: {e}")
        
        self.print_summary()
        return len(self.errors_found) == 0
    
    def process_workflow_file(self, workflow_file):
        """Process a single workflow file"""
        # Read the file
        with open(workflow_file, 'r', encoding='utf-8') as f:
            content = f.read()
        
        original_content = content
        
        # Fix common issues
        content = self.fix_action_versions(content)
        content = self.fix_permissions(content)
        content = self.fix_timeout_settings(content)
        content = self.fix_syntax_errors(content)
        content = self.fix_matrix_config(content)
        content = self.fix_env_variables(content)
        
        # Write the fixed content back if changes were made
        if content != original_content:
            if self.dry_run:
                print(f"📋 Would fix {workflow_file.name}")
                print("\nChanges:")
                self.show_diff(original_content, content)
            else:
                with open(workflow_file, 'w', encoding='utf-8') as f:
                    f.write(content)
                print(f"✅ Fixed {workflow_file.name}")
                self.fixed_files.append(workflow_file.name)
        else:
            print(f"✅ No issues found in {workflow_file.name}")
    
    def fix_action_versions(self, content):
        """Fix outdated action versions"""
        fixes = {
            r'actions/checkout@v[123]': 'actions/checkout@v4',
            r'actions/setup-node@v[123]': 'actions/setup-node@v4',
            r'actions/setup-go@v[1234]': 'actions/setup-go@v5',
            r'actions/setup-python@v[1234]': 'actions/setup-python@v5',
            r'actions/cache@v[123]': 'actions/cache@v4',
            r'actions/upload-artifact@v[123]': 'actions/upload-artifact@v4',
            r'actions/download-artifact@v[123]': 'actions/download-artifact@v4',
            r'github/codeql-action/init@v[12]': 'github/codeql-action/init@v3',
            r'github/codeql-action/analyze@v[12]': 'github/codeql-action/analyze@v3',
        }
        
        for pattern, replacement in fixes.items():
            content = re.sub(pattern, replacement, content)
        
        return content
    
    def fix_permissions(self, content):
        """Fix permission issues"""
        # Fix empty permissions
        content = re.sub(r'permissions:\s*{}', 'permissions:\n  contents: read', content)
        
        # Add permissions if missing for certain actions
        if 'actions/deploy-pages' in content and 'permissions:' not in content:
            # Find a good place to insert permissions
            if 'on:' in content:
                # Insert after on section
                content = re.sub(r'(on:.*?)(\n\w+:)\s', r'\1\n\npermissions:\n  contents: read\n  pages: write\n  id-token: write\n\2 ', content, flags=re.DOTALL)
        
        return content
    
    def fix_timeout_settings(self, content):
        """Fix timeout settings"""
        # Increase minimum timeout
        content = re.sub(r'timeout-minutes:\s*[1-9]', 'timeout-minutes: 10', content)
        
        # Add timeout if missing in jobs
        try:
            # Parse YAML to check for timeouts
            data = yaml.safe_load(content)
            if 'jobs' in data:
                for job_name, job_data in data['jobs'].items():
                    if 'timeout-minutes' not in job_data:
                        # This is more complex, would need to insert in the right place
                        pass
        except:
            pass
        
        return content
    
    def fix_syntax_errors(self, content):
        """Fix common syntax errors"""
        # Fix trailing commas in YAML
        content = re.sub(r',\s*\n(\s*\w+:)', r'\n\1', content)
        
        # Fix indentation issues
        # This is a simple fix, more complex cases would need proper parsing
        lines = content.split('\n')
        fixed_lines = []
        for line in lines:
            # Fix common indentation issues
            if line.strip().startswith('-') and not line.startswith(' '):
                fixed_lines.append(f"  {line}")
            else:
                fixed_lines.append(line)
        
        return '\n'.join(fixed_lines)
    
    def fix_matrix_config(self, content):
        """Fix matrix configuration issues"""
        # Fix matrix syntax
        content = re.sub(r'matrix:\s*\[', 'matrix:\n        ', content)
        content = re.sub(r'\]\s*:', '\n    ', content)
        
        return content
    
    def fix_env_variables(self, content):
        """Fix environment variable issues"""
        # Fix env variable syntax
        content = re.sub(r'\$\{(\s*secrets\.[A-Z_]+\s*)\}', r'\${{ \1 }}', content)
        content = re.sub(r'\$\{(\s*env\.[A-Z_]+\s*)\}', r'\${{ \1 }}', content)
        content = re.sub(r'\$\{(\s*github\.[a-z_]+\s*)\}', r'\${{ \1 }}', content)
        
        return content
    
    def show_diff(self, original, fixed):
        """Show the diff between original and fixed content"""
        original_lines = original.split('\n')
        fixed_lines = fixed.split('\n')
        
        for i, (orig_line, fixed_line) in enumerate(zip(original_lines, fixed_lines)):
            if orig_line != fixed_line:
                print(f"- {orig_line}")
                print(f"+ {fixed_line}")
        
        # Show any extra lines in fixed content
        if len(fixed_lines) > len(original_lines):
            for line in fixed_lines[len(original_lines):]:
                print(f"+ {line}")
        
        # Show any missing lines in fixed content
        if len(original_lines) > len(fixed_lines):
            for line in original_lines[len(fixed_lines):]:
                print(f"- {line}")
    
    def print_summary(self):
        """Print the summary of fixes"""
        print("\n" + "="*60)
        print("📊 SUMMARY")
        print("="*60)
        
        if self.fixed_files:
            print(f"✅ Fixed {len(self.fixed_files)} files:")
            for file in self.fixed_files:
                print(f"  - {file}")
        else:
            print("✅ No files needed fixing")
        
        if self.errors_found:
            print(f"\n❌ Encountered {len(self.errors_found)} errors:")
            for error in self.errors_found:
                print(f"  - {error}")
        else:
            print("\n✅ No errors encountered")
        
        print("="*60)

if __name__ == "__main__":
    dry_run = "--dry-run" in sys.argv
    fixer = ActionFixer(dry_run=dry_run)
    success = fixer.run()
    sys.exit(0 if success else 1)
