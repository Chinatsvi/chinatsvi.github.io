import os
import glob

workspace = r"c:\Users\china\Documents\AgriBase-Websites"

adsense_meta = '<meta name="google-adsense-account" content="ca-pub-2606126305565597">'
adsense_script = '<script async src="https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js?client=ca-pub-2606126305565597" crossorigin="anonymous"></script>'

updated_count = 0

for root, dirs, files in os.walk(workspace):
    # Exclude chinatsvi.github.io mirror directory from walking since we sync to it later
    if "chinatsvi.github.io" in root or ".git" in root:
        continue
    for file in files:
        if file.endswith(".html"):
            filepath = os.path.join(root, file)
            with open(filepath, "r", encoding="utf-8", errors="ignore") as f:
                content = f.read()
            
            # Check if head exists
            if "<head>" in content or "<head " in content:
                modified = False
                new_head_content = []
                if "google-adsense-account" not in content:
                    new_head_content.append(f"  {adsense_meta}")
                    modified = True
                if "pagead2.googlesyndication.com/pagead/js/adsbygoogle.js" not in content:
                    new_head_content.append(f"  {adsense_script}")
                    modified = True
                
                if modified:
                    # Insert after <head> or <head ...>
                    head_pos = content.find("<head>")
                    if head_pos != -1:
                        insert_pos = head_pos + len("<head>")
                        content = content[:insert_pos] + "\n" + "\n".join(new_head_content) + content[insert_pos:]
                        with open(filepath, "w", encoding="utf-8") as f:
                            f.write(content)
                        updated_count += 1
                        print(f"Updated AdSense tags in: {os.path.relpath(filepath, workspace)}")

print(f"Total HTML files updated with AdSense head tags: {updated_count}")
