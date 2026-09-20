import os

handbook_file = r"c:\Users\china\Documents\AgriBase-Websites\assets\handbooks.js"

# Read existing content to preserve handbooks like understanding-soil-ph, tomato-fertilizer-guide, farm-record-keeping, farming-dry-conditions
with open(handbook_file, 'r', encoding='utf-8') as f:
    existing_code = f.read()

# Let's inspect the sections in handbooks.js
print(f"Existing handbooks.js size: {len(existing_code)} bytes")
