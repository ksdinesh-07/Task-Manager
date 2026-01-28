#!/usr/bin/env python3
import re

with open('Jenkinsfile', 'r') as f:
    content = f.read()

# Replace all sh ''' ... ''' with sh """ ... """
lines = content.split('\n')
in_single_quote_block = False
fixed_lines = []

for i, line in enumerate(lines):
    if 'sh \'\'\'' in line and not in_single_quote_block:
        # Start of single quote block
        line = line.replace('sh \'\'\'', 'sh \"\"\"')
        in_single_quote_block = True
    elif '\'\'\'' in line and in_single_quote_block:
        # End of single quote block
        line = line.replace('\'\'\'', '\"\"\"')
        in_single_quote_block = False
    
    fixed_lines.append(line)

# Write back
with open('Jenkinsfile', 'w') as f:
    f.write('\n'.join(fixed_lines))

print("✅ Fixed all sh ''' blocks to sh \"\"\"")
