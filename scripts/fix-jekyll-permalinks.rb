#!/usr/bin/env ruby
# This script fixes the permalinks in Jekyll chapter files

require 'yaml'

def fix_permalinks
  puts "Fixing permalinks in _chapters files..."
  
  Dir.glob('_chapters/*.md').each do |file|
    content = File.read(file)
    
    # Parse front matter
    if content =~ /\A---\s*\n(.*?)\n---\s*\n/m
      front_matter = YAML.load($1)
      
      # Update permalink if needed
      if front_matter['permalink']
        permalink = front_matter['permalink']
        
        # Remove ch-N- pattern from permalink if present
        if permalink.include?('ch-')
          new_permalink = permalink.gsub(/\/ch-\d+-/, '/')
          
          # Replace the permalink in the content
          content.gsub!(/permalink: (.*)$/, "permalink: #{new_permalink}")
          
          # Write back to file
          File.write(file, content)
          puts "Updated #{file}: #{permalink} -> #{new_permalink}"
        end
      end
    end
  end
  
  puts "Permalink fixing complete!"
end

fix_permalinks 