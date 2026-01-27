import yaml
import os
import re

def fix_workflow_file(file_path):
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        print(f"Original content of {file_path}:")
        print(content)
        print("\n" + "="*50 + "\n")
        
        # Fix common syntax issues
        fixed_content = content
        
        # Fix 1: Ensure consistent line endings
        fixed_content = re.sub(r'\r\n?', '\n', fixed_content)
        
        # Fix 2: Fix conditional expressions
        # Fix if expressions with missing github.event_name check
        fixed_content = re.sub(r'if: \$\{\{\s*(github\.event\.inputs\.[^\}]+\s*(==|!=|<=|>=|<|>|&&|\|\|)[^\}]+)\s*\}\}', 
                             r'if: ${{ github.event_name == "workflow_dispatch" && \1 }}', 
                             fixed_content)
        
        # Fix 3: Fix environment expressions with missing github.event_name check
        fixed_content = re.sub(r'environment: \$\{\{\s*(github\.event\.inputs\.[^\}]+\s*\|\|\s*[^\}]+)\s*\}\}', 
                             r'environment: ${{ github.event_name == "workflow_dispatch" && \1 }}', 
                             fixed_content)
        
        print(f"Fixed content of {file_path}:")
        print(fixed_content)
        print("\n" + "="*50 + "\n")
        
        # Write back the fixed content
        if fixed_content != content:
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(fixed_content)
            return True
        else:
            return False
            
    except Exception as e:
        print(f"Error fixing {file_path}: {e}")
        return False

# Test the fix on our test workflow file
if __name__ == "__main__":
    test_file = ".github/workflows/test-error-workflow.yml"
    if os.path.exists(test_file):
        print(f"Testing auto-fix on {test_file}...")
        fixed = fix_workflow_file(test_file)
        if fixed:
            print(f"✅ Successfully fixed {test_file}")
        else:
            print(f"ℹ No changes needed for {test_file}")
    else:
        print(f"❌ File {test_file} not found")
