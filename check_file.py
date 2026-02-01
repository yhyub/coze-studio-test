try:
    # 检查文件是否存在并可读
    with open('.github/workflows/新建文本文档.yml', 'r', encoding='utf-8') as f:
        content = f.read()
    print('File is readable!')
    print('File size:', len(content), 'bytes')
    
    # 检查基本结构
    lines = content.split('\n')
    print('Number of lines:', len(lines))
    
    # 检查关键部分
    has_name = False
    has_on = False
    has_jobs = False
    
    for line in lines:
        if line.strip().startswith('name:'):
            has_name = True
            print('Found name:', line.strip())
        elif line.strip().startswith('on:'):
            has_on = True
            print('Found on: section')
        elif line.strip().startswith('jobs:'):
            has_jobs = True
            print('Found jobs: section')
    
    if has_name and has_on and has_jobs:
        print('Basic workflow structure is valid!')
    else:
        print('Missing required sections:')
        print('name:', has_name)
        print('on:', has_on)
        print('jobs:', has_jobs)
        
except Exception as e:
    print('Error:', e)
