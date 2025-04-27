source "https://rubygems.org"

# Use specific Jekyll version for GitHub Pages
gem "jekyll", "~> 3.9.3"

# This is the default theme for new Jekyll sites
gem "minima", "~> 2.5"

# GitHub Pages requirements
gem "github-pages", "~> 231"

# If you have any plugins, put them here!
group :jekyll_plugins do
  gem "jekyll-feed", "~> 0.15"
  gem "jekyll-seo-tag", "~> 2.8"
end

# Windows and JRuby does not include zoneinfo files, so bundle the tzinfo-data gem
# and associated library.
platforms :mingw, :x64_mingw, :mswin, :jruby do
  gem "tzinfo", "~> 1.2"
  gem "tzinfo-data"
end

# Performance-booster for watching directories on Windows
gem "wdm", "~> 0.1.1", :platforms => [:mingw, :x64_mingw, :mswin]

# Lock `http_parser.rb` gem to `v0.6.x` on JRuby builds since newer versions of the gem
# do not have a Java counterpart.
gem "http_parser.rb", "~> 0.6.0", :platforms => [:jruby]

# Required for Ruby 3+
gem "webrick", "~> 1.7"

# Required for GitHub Pages
gem "kramdown-parser-gfm" 