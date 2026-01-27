#!/usr/bin/env python3
"""
Docker & GitHub 急速访问修复器 - .crx文件生成脚本
"""

import os
import sys
from pathlib import Path

# 安装pycrx3库
try:
    import crx3
except ImportError:
    print('正在安装pycrx3库...')
    import subprocess
    subprocess.run([sys.executable, '-m', 'pip', 'install', 'pycrx3'], check=True)
    import crx3

def generate_crx(extension_dir, output_path=None):
    """生成.crx文件"""
    print(f'\n正在生成.crx文件，源目录: {extension_dir}')
    
    extension_path = Path(extension_dir)
    if not extension_path.exists():
        print(f'错误: 源目录不存在: {extension_dir}')
        return False
    
    manifest_path = extension_path / 'manifest.json'
    if not manifest_path.exists():
        print(f'错误: 缺少manifest.json文件')
        return False
    
    try:
        # 生成私钥
        private_key_path = extension_path.parent / 'docker_github_fixer.pem'
        if not private_key_path.exists():
            print('正在生成私钥...')
            crx3.generate_key(private_key_path)
            print(f'私钥已生成: {private_key_path}')
        
        # 生成.crx文件
        print('正在生成.crx文件...')
        crx_path = output_path or extension_path.parent / 'docker_github_fixer.crx'
        crx3.load(extension_dir, private_key_path, crx_path)
        print(f'.crx文件已生成: {crx_path}')
        return True
    except Exception as e:
        print(f'生成.crx文件失败: {e}')
        return False

def main():
    """主函数"""
    extension_dir = 'docker_github_fixer'
    success = generate_crx(extension_dir)
    
    if success:
        print('\n✅ .crx文件生成成功！')
        print('使用方法：')
        print('1. 打开浏览器扩展管理页面')
        print('2. 开启"开发者模式"')
        print('3. 将生成的.crx文件拖放到扩展管理页面')
        print('4. 确认安装')
    else:
        print('\n❌ .crx文件生成失败！')
        print('\n请按照以下步骤手动生成.crx文件：')
        print('1. 打开Chrome浏览器')
        print('2. 访问 chrome://extensions/')
        print('3. 启用开发者模式')
        print('4. 点击"加载已解压的扩展程序"，选择 docker_github_fixer 文件夹')
        print('5. 点击"打包扩展程序"')
        print('6. 选择 docker_github_fixer 文件夹作为根目录')
        print('7. 点击"打包扩展程序"，生成.crx文件')
        sys.exit(1)

if __name__ == '__main__':
    main()