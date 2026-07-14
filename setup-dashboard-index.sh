#!/bin/bash

###############################################################################
# Dashboard Index Auto-Generator Setup Script
# For: rogueonomist.github.io
###############################################################################

set -e

echo "🚀 Setting up automated dashboard index generation..."
echo ""

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Step 1: Create directories
echo -e "${BLUE}Step 1: Creating directories...${NC}"
mkdir -p .github/workflows
mkdir -p scripts
echo -e "${GREEN}✓ Directories created${NC}"
echo ""

# Step 2: Create GitHub Actions workflow
echo -e "${BLUE}Step 2: Creating GitHub Actions workflow...${NC}"
cat > .github/workflows/generate-dashboard-index.yml << 'WORKFLOW_EOF'
name: Auto-Generate Dashboard Index

on:
  push:
    branches: [main]

jobs:
  generate-index:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Set up Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.9'
      
      - name: Generate dashboard index
        run: python3 scripts/generate-index.py
      
      - name: Commit and push if changed
        run: |
          git config user.name "Dashboard Index Bot"
          git config user.email "noreply@github.com"
          git add index.html
          git diff --quiet && git diff --staged --quiet || (git commit -m "Auto-generate dashboard index" && git push)
WORKFLOW_EOF
echo -e "${GREEN}✓ Workflow file created${NC}"
echo ""

# Step 3: Create Python generator script
echo -e "${BLUE}Step 3: Creating Python index generator...${NC}"
cat > scripts/generate-index.py << 'PYTHON_EOF'
#!/usr/bin/env python3
import os
from pathlib import Path
from html import escape

def get_dashboard_category(name):
    if name.startswith('NCGCL'):
        return 'Credit Guarantee'
    elif any(x in name for x in ['Pakistan', 'Pak', 'Cooling', 'Electrification', 'IGCEP', 'ISMO', 'Thar']):
        return 'Power & Energy'
    elif any(x in name for x in ['Residential', 'TPT']):
        return 'Tariff Design'
    elif any(x in name for x in ['RLNG', 'Kerosene', 'Diesel', 'Fuel', 'Gas']):
        return 'Commodities'
    elif any(x in name for x in ['fertilizer', 'food', 'hajj', 'tourism']):
        return 'Thematic Analysis'
    else:
        return 'Other'

def generate_index():
    dashboards = []
    for html_file in sorted(Path('.').glob('*.html')):
        filename = html_file.name
        if filename == 'index.html':
            continue
        readable_name = filename.replace('.html', '').replace('_', ' ').replace('-', ' – ')
        category = get_dashboard_category(readable_name)
        dashboards.append({'name': readable_name, 'path': f'./{filename}', 'category': category})
    
    categories = {}
    for dash in dashboards:
        cat = dash['category']
        if cat not in categories:
            categories[cat] = []
        categories[cat].append(dash)
    
    html = """<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Dashboard Directory — Ammar H. Khan</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: Calibri, -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif; background: #fff; color: #333; padding: 40px 20px; line-height: 1.6; }
        .container { max-width: 1000px; margin: 0 auto; }
        h1 { font-family: Georgia, 'Times New Roman', serif; font-size: 2.5em; font-weight: normal; margin-bottom: 10px; color: #1a1a1a; border-bottom: 2px solid #daa520; padding-bottom: 15px; }
        .subtitle { font-family: Georgia, serif; font-size: 1.1em; color: #666; margin-bottom: 40px; font-style: italic; }
        .category { margin: 50px 0 30px 0; }
        .category-title { font-family: Georgia, serif; font-size: 1.4em; color: #1a1a1a; border-left: 3px solid #daa520; padding-left: 15px; margin-bottom: 20px; }
        .dashboard-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(300px, 1fr)); gap: 20px; }
        .dashboard-card { background: #fafafa; border: 1px solid #e5e5e5; padding: 20px; text-decoration: none; color: #333; border-left: 4px solid #daa520; transition: all 0.2s; display: flex; flex-direction: column; justify-content: space-between; min-height: 100px; }
        .dashboard-card:hover { background: #f5f5f5; box-shadow: 0 2px 6px rgba(0,0,0,0.08); }
        .dashboard-name { font-family: Georgia, serif; font-size: 1.1em; margin-bottom: 8px; color: #1a1a1a; }
        .dashboard-link { font-size: 0.9em; color: #0066cc; font-weight: 500; }
        .dashboard-card:hover .dashboard-link { text-decoration: underline; }
        .count { color: #daa520; font-weight: bold; }
        .footer { margin-top: 60px; padding-top: 20px; border-top: 1px solid #e5e5e5; font-size: 0.9em; color: #666; font-family: Georgia, serif; }
        @media (max-width: 768px) { h1 { font-size: 2em; } .dashboard-grid { grid-template-columns: 1fr; } }
    </style>
</head>
<body>
    <div class="container">
        <h1>📊 Dashboard Directory</h1>
        <p class="subtitle">Interactive analytics, forecasts, and policy models</p>
"""
    
    for category in sorted(categories.keys()):
        dashes = categories[category]
        html += f'\n        <div class="category">\n            <h2 class="category-title">{escape(category)} <span class="count">({len(dashes)})</span></h2>\n            <div class="dashboard-grid">\n'
        for dash in dashes:
            html += f'                <a href="{escape(dash["path"])}" class="dashboard-card">\n                    <div>\n                        <div class="dashboard-name">{escape(dash["name"])}</div>\n                        <div class="dashboard-link">Open →</div>\n                    </div>\n                </a>\n'
        html += '            </div>\n        </div>\n'
    
    html += """
        <div class="footer">
            <p>© 2026 Ammar H. Khan. All dashboards represent economic analysis, policy research, and development finance work.</p>
        </div>
    </div>
</body>
</html>"""
    
    with open('index.html', 'w', encoding='utf-8') as f:
        f.write(html)
    return len(dashboards), len(categories)

if __name__ == '__main__':
    num_dashboards, num_categories = generate_index()
    print(f"✓ Generated index.html")
    print(f"  Dashboards found: {num_dashboards}")
    print(f"  Categories: {num_categories}")
PYTHON_EOF

chmod +x scripts/generate-index.py
echo -e "${GREEN}✓ Python script created${NC}"
echo ""

# Step 4: Test the generator
echo -e "${BLUE}Step 4: Testing generator locally...${NC}"
python3 scripts/generate-index.py
echo ""

# Step 5: Success
echo -e "${GREEN}✅ Setup complete!${NC}"
echo ""
echo -e "${YELLOW}Final steps:${NC}"
echo ""
echo "1. Verify index.html was created and looks good"
echo ""
echo "2. Commit and push:"
echo "   git add .github/ scripts/ index.html"
echo "   git commit -m 'Add automated dashboard index generation'"
echo "   git push origin main"
echo ""
echo "3. Verify on GitHub:"
echo "   https://github.com/rogueonomist/rogueonomist.github.io/actions"
echo "   https://rogueonomist.github.io/"
echo ""
echo -e "${GREEN}🎉 Done! Every future push will auto-update your dashboard index.${NC}"
