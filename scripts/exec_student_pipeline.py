import os
import subprocess

with open('run_all_student.sh', 'r', encoding='utf-8') as f:
    sh_script = f.read()

# Replace any CRLF with LF just in case
sh_script = sh_script.replace('\r\n', '\n')

with open('run_all_student_clean.sh', 'w', newline='\n', encoding='utf-8') as f:
    f.write(sh_script)

print("Running pipeline in WSL...")
result = subprocess.run(['wsl', 'bash', 'run_all_student_clean.sh'], capture_output=True, text=True)
print("STDOUT:", result.stdout)
print("STDERR:", result.stderr)
