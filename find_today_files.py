import os
from datetime import datetime
import glob
import json

today = datetime.now().date()
base_path = 'C:/Users/Administrator/Desktop/fcjgfycrteas'

patterns = ['*.ps1', '*.bat', '*.py', '*temp*', '*tmp*', '*cache*', '*fix_*', '*cleanup*', '*test_*', '*debug*', '*validate_*', '*generate_*']

files = []
for pattern in patterns:
    files.extend(glob.glob(os.path.join(base_path, pattern)))

result = []
for f in set(files):
    if os.path.isfile(f):
        created_time = datetime.fromtimestamp(os.path.getctime(f))
        if created_time.date() == today:
            result.append({
                'name': os.path.basename(f),
                'path': f,
                'created': created_time.strftime('%Y-%m-%d %H:%M:%S'),
                'size_kb': round(os.path.getsize(f)/1024, 2)
            })

print(json.dumps(result, indent=2, ensure_ascii=False))