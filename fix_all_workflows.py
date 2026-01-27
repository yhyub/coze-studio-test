import os
import re
import shutil

def fix_workflow_file(file_path):
    """修复单个工作流文件"""
    try:
        print(f"正在修复文件: {file_path}")
        
        # 读取文件内容
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        fixed_content = content
        
        # 修复1: 修复environment表达式
        fixed_content = re.sub(r'environment: \$\{\{\s*(github\.event\.inputs\.[^\}]+\s*\|\|\s*[^\}]+)\s*\}\}', 
                             r'environment: ${{ github.event_name == "workflow_dispatch" && \1 }}', 
                             fixed_content)
        
        # 修复2: 修复if表达式
        fixed_content = re.sub(r'if: \$\{\{\s*(github\.event\.inputs\.[^\}]+\s*(==|!=|<=|>=|<|>|&&|\|\|)[^\}]+)\s*\}\}', 
                             r'if: ${{ github.event_name == "workflow_dispatch" && \1 }}', 
                             fixed_content)
        
        # 修复3: 修复env表达式
        fixed_content = re.sub(r'env:\s+[^#]+:\s*\$\{\{\s*github\.event\.inputs\.[^\}]+\s*\}\}', 
                             r'env:\n        \1: ${{ github.event_name == "workflow_dispatch" && \2 }}', 
                             fixed_content)
        
        # 检查是否有未修复的github.event.inputs引用
        unfixed_inputs = re.findall(r'github\.event\.inputs\.[^\{\}]+', fixed_content)
        if unfixed_inputs:
            print(f"  ⚠ 发现未修复的github.event.inputs引用: {set(unfixed_inputs)}")
            
            # 尝试进一步修复
            for input_ref in set(unfixed_inputs):
                # 修复独立的github.event.inputs引用
                fixed_content = re.sub(f'\${{\{input_ref}\}}', 
                                     f'${{ github.event_name == "workflow_dispatch" && {input_ref} }}', 
                                     fixed_content)
        
        # 保存修复后的文件
        if fixed_content != content:
            # 创建备份
            backup_path = f"{file_path}.bak"
            shutil.copy2(file_path, backup_path)
            print(f"  ✅ 创建了备份文件: {backup_path}")
            
            # 写入修复后的内容
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(fixed_content)
            print(f"  ✅ 成功修复了文件: {file_path}")
            return True
        else:
            print(f"  ℹ 文件无需修复: {file_path}")
            return False
            
    except Exception as e:
        print(f"  ❌ 修复文件时出错: {e}")
        return False

# 修复所有工作流文件
def main():
    print("开始修复所有工作流文件...\n")
    
    workflows_dir = ".github/workflows"
    if not os.path.exists(workflows_dir):
        print(f"❌ 工作流目录 {workflows_dir} 不存在")
        return
    
    fixed_count = 0
    total_count = 0
    
    # 获取所有YAML文件
    for root, dirs, files in os.walk(workflows_dir):
        for file in files:
            if file.endswith('.yml') or file.endswith('.yaml'):
                file_path = os.path.join(root, file)
                total_count += 1
                
                if fix_workflow_file(file_path):
                    fixed_count += 1
                
                print()
    
    # 输出总结
    print("="*60)
    print(f"修复完成！")
    print(f"总文件数: {total_count}")
    print(f"修复的文件数: {fixed_count}")
    print(f"无需修复的文件数: {total_count - fixed_count}")
    print("="*60)

if __name__ == "__main__":
    main()
