#!/bin/bash

# Run the prepare script to convert chapters to Jekyll format
echo "Step 1: Preparing Jekyll chapters..."
bash scripts/prepare_jekyll.sh

# Run the permalink fixer script
echo "Step 2: Fixing permalinks..."
ruby scripts/fix-jekyll-permalinks.rb

# Create a .nojekyll file to avoid GitHub Pages processing
echo "Step 3: Creating .nojekyll file..."
touch .nojekyll

echo "Jekyll site preparation complete!"
echo "Note: For local testing, run 'bundle exec jekyll serve' if you have Jekyll installed."
echo "For GitHub Pages, just push your changes to the repository." 