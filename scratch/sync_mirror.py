import os
import shutil

src_root = r"c:\Users\china\Documents\AgriBase-Websites"
dst_root = r"c:\Users\china\Documents\AgriBase-Websites\chinatsvi.github.io"

# List of root files to sync
root_files = ["ads.txt", "robots.txt", "sitemap.xml", "404.html", "index.html"]

for f in root_files:
    src_path = os.path.join(src_root, f)
    dst_path = os.path.join(dst_root, f)
    if os.path.exists(src_path):
        shutil.copy2(src_path, dst_path)
        print(f"Copied root file: {f}")

# List of folders to sync
folders = ["about", "academy", "assets", "calculators", "calendar", "community", "contact", "decision-tools", "disclaimer", "faq", "guides", "privacy", "resources", "terms"]

for folder in folders:
    src_dir = os.path.join(src_root, folder)
    dst_dir = os.path.join(dst_root, folder)
    if os.path.exists(src_dir):
        if os.path.exists(dst_dir):
            shutil.rmtree(dst_dir)
        shutil.copytree(src_dir, dst_dir)
        print(f"Synced directory: {folder}")

print("Mirror sync complete!")
