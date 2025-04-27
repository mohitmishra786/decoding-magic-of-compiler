# Setting Up GitHub Pages for "Decoding the Magic of Compilers"

Follow these steps to publish your compiler book as a website using GitHub Pages:

## 1. Push to GitHub

First, push this repository to GitHub:

```bash
# Initialize the repository if not already done
git init
git add .
git commit -m "Initial commit of compiler book with Jekyll setup"

# Add your GitHub repository as a remote
git remote add origin https://github.com/yourusername/decoding-magic-of-compiler.git
git branch -M main
git push -u origin main
```

Replace `yourusername` with your actual GitHub username.

## 2. Configure GitHub Pages

1. Go to your repository on GitHub.com
2. Navigate to "Settings" > "Pages"
3. Under "Build and deployment":
   - Source: Select "GitHub Actions"
4. The workflow file included in this project (`.github/workflows/jekyll.yml`) will handle the build and deployment process.

## 3. Wait for Deployment

- The GitHub Actions workflow will run automatically after you push to the `main` branch.
- You can monitor the deployment progress in the "Actions" tab of your repository.
- Once complete, your site will be available at `https://yourusername.github.io/decoding-magic-of-compiler/`

## 4. Customize Your Site

You can update your site by:

1. Modifying the content in the `src/` directory
2. Running `./scripts/prepare_jekyll.sh` to update the Jekyll-ready files
3. Committing and pushing your changes
4. The GitHub Actions workflow will automatically rebuild and deploy the site

## 5. Local Development

To preview the site locally:

```bash
# Install dependencies
gem install bundler jekyll
bundle install

# Run the prepare script to generate _chapters files
./scripts/prepare_jekyll.sh

# Start the local server
bundle exec jekyll serve
```

Then open your browser to `http://localhost:4000/decoding-magic-of-compiler/` to preview the site.

## 6. Updating Content

When you add or update chapter content:

1. Place the Markdown files in the appropriate `src/ch-*` directory
2. Run the prepare script to update the Jekyll files:
   ```bash
   ./scripts/prepare_jekyll.sh
   ```
3. Commit and push your changes
4. GitHub Actions will rebuild and deploy the updated site

## Troubleshooting

If your site isn't building correctly:

1. Check the GitHub Actions logs in the "Actions" tab
2. Ensure your repository has GitHub Pages enabled
3. Verify that the baseurl in `_config.yml` matches your repository name
4. Make sure all your Markdown files have the correct format and frontmatter 