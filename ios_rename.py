import os

app_dir = r'c:\Users\TestElectron\Downloads\Iqra_university\app'

for root, dirs, files in os.walk(app_dir):
    for file in files:
        if file.endswith('.pbxproj'):
            path = os.path.join(root, file)
            with open(path, 'r', encoding='utf-8') as f:
                content = f.read()
            if 'com.example.flutterApplication1' in content:
                content = content.replace('com.example.flutterApplication1', 'com.example.gpa_calculator_iuic')
                with open(path, 'w', encoding='utf-8') as f:
                    f.write(content)
                print(f'Updated {path}')
