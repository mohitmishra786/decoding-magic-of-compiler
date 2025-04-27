#!/bin/bash
# Script to prepare the chapter files for Jekyll

# Create _chapters directory if it doesn't exist
mkdir -p _chapters

# Process each chapter in the src directory
for chapter_dir in src/ch-*; do
  chapter_name=$(basename "$chapter_dir")
  chapter_num=$(echo "$chapter_name" | sed 's/ch-\([0-9]*\).*/\1/')
  chapter_slug=$(echo "$chapter_name" | sed 's/ch-[0-9]*-//')
  
  # Find the main markdown file
  md_file=$(find "$chapter_dir" -name "*.md" -type f | head -n 1)
  
  if [ -n "$md_file" ]; then
    # Extract the title from the markdown file
    title=$(head -n 1 "$md_file" | sed 's/# //')
    
    # Create the destination file
    dest_file="_chapters/${chapter_num}-${chapter_slug}.md"
    
    # Add front matter and copy content
    echo "---" > "$dest_file"
    echo "layout: chapter" >> "$dest_file"
    echo "title: \"$title\"" >> "$dest_file"
    echo "chapter_number: $chapter_num" >> "$dest_file"
    echo "permalink: /chapters/${chapter_slug}/" >> "$dest_file"
    echo "---" >> "$dest_file"
    
    # Append the content, skipping the first line (title)
    tail -n +2 "$md_file" >> "$dest_file"
    
    echo "Processed: $md_file -> $dest_file"
  fi
done

# Process the appendix directory
for appendix_dir in src/appendix; do
  if [ -d "$appendix_dir" ]; then
    # Find the main markdown file
    md_file=$(find "$appendix_dir" -name "*.md" -type f | head -n 1)
    
    if [ -n "$md_file" ]; then
      # Extract the title from the markdown file
      title=$(head -n 1 "$md_file" | sed 's/# //')
      
      # Create the destination file
      dest_file="_chapters/appendix-compiler-optimization-reference.md"
      
      # Add front matter and copy content
      echo "---" > "$dest_file"
      echo "layout: chapter" >> "$dest_file"
      echo "title: \"$title\"" >> "$dest_file"
      echo "permalink: /chapters/appendix-compiler-optimization-reference/" >> "$dest_file"
      echo "---" >> "$dest_file"
      
      # Append the content, skipping the first line (title)
      tail -n +2 "$md_file" >> "$dest_file"
      
      echo "Processed: $md_file -> $dest_file"
    fi
  fi
done

echo "Processing complete. Jekyll chapters are ready." 