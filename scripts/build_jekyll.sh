#!/bin/bash

# Run the prepare script to convert chapters to Jekyll format
echo "Step 1: Preparing Jekyll chapters..."
bash scripts/prepare_jekyll.sh

# Run the permalink fixer script
echo "Step 2: Fixing permalinks..."
ruby scripts/fix-jekyll-permalinks.rb

# Build the Jekyll site
echo "Step 3: Building Jekyll site..."
JEKYLL_ENV=production bundle exec jekyll build

echo "Jekyll site built successfully! Files are in the _site directory." 