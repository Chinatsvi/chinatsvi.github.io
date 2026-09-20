import os

handbooks_path = r"c:\Users\china\Documents\AgriBase-Websites\assets\handbooks.js"

with open(handbooks_path, "r", encoding="utf-8") as f:
    text = f.read()

# Let's extract unique replace blocks using regex or string splitting
import re

# Find all replace('slug', ... `...`) blocks
pattern = r"replace\s*\(\s*'([^']+)'\s*,\s*'([^']+)'\s*,\s*'([^']+)'\s*,\s*`([\s\S]*?)`\s*\);"

matches = re.findall(pattern, text)
print(f"Found {len(matches)} replace blocks")

unique_blocks = {}
for slug, title, desc, body in matches:
    # Keep the longest body for each slug (which corresponds to our expanded handbooks!)
    if slug not in unique_blocks or len(body) > len(unique_blocks[slug][2]):
        unique_blocks[slug] = (title, desc, body)

print(f"Unique slugs ({len(unique_blocks)}): {list(unique_blocks.keys())}")

# Reconstruct clean handbooks.js
js_lines = [
    "(function () {",
    "  const articles = window.AGRIBASE_CONTENT && window.AGRIBASE_CONTENT.articles;",
    "  if (!articles) return;",
    "",
    "  const replace = (slug, title, description, body) => {",
    "    const article = articles.find(item => item.slug === slug);",
    "    if (!article) return;",
    "    article.title = title;",
    "    article.description = description;",
    "    article.body = body;",
    "  };",
    ""
]

for slug, (title, desc, body) in unique_blocks.items():
    # Clean up single quotes in title and desc if needed
    clean_title = title.replace("'", "\\'")
    clean_desc = desc.replace("'", "\\'")
    js_lines.append(f"  // ==========================================")
    js_lines.append(f"  // HANDBOOK: {slug.upper()}")
    js_lines.append(f"  // ==========================================")
    js_lines.append(f"  replace('{slug}', '{clean_title}', '{clean_desc}', `{body}`);\n")

js_lines.append("})();\n")

clean_js = "\n".join(js_lines)

with open(handbooks_path, "w", encoding="utf-8") as f:
    f.write(clean_js)

print(f"Cleaned handbooks.js saved! Size: {len(clean_js)} bytes.")
