#!/bin/bash

# Run the prepare script to convert chapters to Jekyll format
echo "Step 1: Preparing Jekyll chapters..."
bash scripts/prepare_jekyll.sh

# Run the permalink fixer script
echo "Step 2: Fixing permalinks..."
ruby scripts/fix-jekyll-permalinks.rb

# Remove .nojekyll file if it exists (we want GitHub Pages to process the site as Jekyll)
if [ -f ".nojekyll" ]; then
  echo "Step 3: Removing .nojekyll file..."
  rm .nojekyll
else
  echo "Step 3: No .nojekyll file found, skipping..."
fi

# Ensure the assets/css directory exists
echo "Step 4: Setting up CSS..."
mkdir -p assets/css

# For GitHub Pages, we need to make sure CSS is properly processed
if [ -f "assets/css/main.scss" ]; then
  # If SCSS exists, make sure it has front matter
  if ! grep -q "^---" "assets/css/main.scss"; then
    echo "---" > assets/css/main.scss.new
    echo "---" >> assets/css/main.scss.new
    cat assets/css/main.scss >> assets/css/main.scss.new
    mv assets/css/main.scss.new assets/css/main.scss
  fi
elif [ -f "assets/css/main.css" ]; then
  # If only CSS exists, create basic SCSS with front matter for GitHub Pages
  echo "---" > assets/css/main.scss
  echo "---" >> assets/css/main.scss
  echo "@import 'minima';" >> assets/css/main.scss 
  echo "" >> assets/css/main.scss
  cat assets/css/main.css >> assets/css/main.scss
  # We can remove the CSS file as we've migrated to SCSS
  rm assets/css/main.css
fi

echo "Jekyll site preparation complete!"
echo "For GitHub Pages, push your changes to the repository."
echo "For local testing, run 'bundle exec jekyll serve --config _config.yml,_config_dev.yml' if you have Jekyll installed." 