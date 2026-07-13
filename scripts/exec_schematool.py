import subprocess

with open('run_schematool.sh', 'r', encoding='utf-8') as f:
    sh_script = f.read().replace('\r\n', '\n')

with open('run_schematool_clean.sh', 'w', newline='\n', encoding='utf-8') as f:
    f.write(sh_script)

result = subprocess.run(['wsl', 'bash', 'run_schematool_clean.sh'], capture_output=True, text=True)
print("STDOUT:", result.stdout)
print("STDERR:", result.stderr)
