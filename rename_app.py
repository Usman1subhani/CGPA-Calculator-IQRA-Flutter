import os

app_dir = r"c:\Users\TestElectron\Downloads\Iqra_university\app"
old_name = "flutter_application_1"
new_name = "gpa_calculator_iuic"
app_title = "GPA Calculator ( IUIC )"

extensions = ['.yaml', '.dart', '.kts', '.gradle', '.pbxproj', '.xcscheme', '.txt', '.rc', '.html', '.json', '.xml', '.kt', '.xcconfig', '.sh', '.plist', '.cpp']

def replace_in_file(file_path):
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        modified = False
        
        if old_name in content:
            content = content.replace(old_name, new_name)
            modified = True
            
        if file_path.endswith('AndroidManifest.xml'):
            if 'android:label="gpa_calculator_iuic"' in content:
                content = content.replace('android:label="gpa_calculator_iuic"', f'android:label="{app_title}"')
                modified = True
        elif file_path.endswith('Info.plist'):
            if '<string>gpa_calculator_iuic</string>' in content:
                content = content.replace('<string>gpa_calculator_iuic</string>', f'<string>{app_title}</string>')
                modified = True
        elif file_path.endswith('index.html'):
            if '<title>gpa_calculator_iuic</title>' in content:
                content = content.replace('<title>gpa_calculator_iuic</title>', f'<title>{app_title}</title>')
                modified = True
            if 'content="gpa_calculator_iuic"' in content:
                content = content.replace('content="gpa_calculator_iuic"', f'content="{app_title}"')
                modified = True
        elif file_path.endswith('manifest.json'):
            if '"name": "gpa_calculator_iuic"' in content:
                content = content.replace('"name": "gpa_calculator_iuic"', f'"name": "{app_title}"')
                modified = True
            if '"short_name": "gpa_calculator_iuic"' in content:
                content = content.replace('"short_name": "gpa_calculator_iuic"', f'"short_name": "GPA Calculator"')
                modified = True
        elif file_path.endswith('.cpp'):
            if 'L"gpa_calculator_iuic"' in content:
                content = content.replace('L"gpa_calculator_iuic"', f'L"{app_title}"')
                modified = True

        if modified:
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(content)
            print(f"Updated {file_path}")
    except Exception as e:
        print(f"Error reading/writing {file_path}: {e}")

for root, dirs, files in os.walk(app_dir):
    if '.git' in root or '.dart_tool' in root or 'build' in root or 'ephemeral' in root:
        continue
    for file in files:
        if any(file.endswith(ext) for ext in extensions):
            replace_in_file(os.path.join(root, file))

old_pkg_dir = os.path.join(app_dir, "android", "app", "src", "main", "kotlin", "com", "example", old_name)
new_pkg_dir = os.path.join(app_dir, "android", "app", "src", "main", "kotlin", "com", "example", new_name)

if os.path.exists(old_pkg_dir):
    os.rename(old_pkg_dir, new_pkg_dir)
    print(f"Renamed {old_pkg_dir} to {new_pkg_dir}")
