#!/usr/bin/env ruby

require 'hexapdf'
require 'fileutils'

def split_pdf(input_path, chunk_size = 100)
  puts "Starting PDF split process..."
  
  # Create output directory
  base_name = File.basename(input_path, '.pdf')
  output_dir = File.join(File.dirname(input_path), "#{base_name}_chunks")
  FileUtils.mkdir_p(output_dir)
  
  # Open the source PDF
  doc = HexaPDF::Document.open(input_path)
  total_pages = doc.pages.count
  
  puts "Input PDF: #{File.basename(input_path)}"
  puts "Total pages: #{total_pages}"
  puts "Chunk size: #{chunk_size} pages"
  puts "Output directory: #{output_dir}"
  
  chunks_created = []
  
  # Calculate number of chunks needed
  num_chunks = (total_pages / chunk_size.to_f).ceil
  
  (0...num_chunks).each do |chunk_index|
    start_page = chunk_index * chunk_size
    end_page = [start_page + chunk_size - 1, total_pages - 1].min
    
    # Create new document for this chunk
    chunk_doc = HexaPDF::Document.new
    
    # Copy pages to the new document
    (start_page..end_page).each do |page_index|
      source_page = doc.pages[page_index]
      chunk_doc.pages << chunk_doc.import(source_page)
    end
    
    # Generate output filename
    chunk_filename = "#{base_name}_pages_#{start_page + 1}-#{end_page + 1}.pdf"
    chunk_path = File.join(output_dir, chunk_filename)
    
    # Write the chunk
    chunk_doc.write(chunk_path)
    
    chunk_info = {
      filename: chunk_filename,
      path: chunk_path,
      start_page: start_page + 1,
      end_page: end_page + 1,
      page_count: end_page - start_page + 1
    }
    
    chunks_created << chunk_info
    
    puts "Created chunk #{chunk_index + 1}/#{num_chunks}: #{chunk_filename} (pages #{start_page + 1}-#{end_page + 1})"
  end
  
  # Create manifest file
  manifest_path = File.join(output_dir, "chunks_manifest.txt")
  File.open(manifest_path, 'w') do |f|
    f.puts "PDF Split Manifest"
    f.puts "=================="
    f.puts "Source file: #{File.basename(input_path)}"
    f.puts "Total pages: #{total_pages}"
    f.puts "Chunks created: #{chunks_created.length}"
    f.puts "Created on: #{Time.now}"
    f.puts ""
    
    chunks_created.each_with_index do |chunk, index|
      f.puts "Chunk #{index + 1}: #{chunk[:filename]}"
      f.puts "  Pages: #{chunk[:start_page]}-#{chunk[:end_page]} (#{chunk[:page_count]} pages)"
      f.puts "  Path: #{chunk[:path]}"
      f.puts ""
    end
  end
  
  puts "\nSplit complete!"
  puts "Manifest created: #{manifest_path}"
  
  return chunks_created
end

# Run the split if this script is executed directly
if __FILE__ == $0
  input_path = ARGV[0] || '/Users/fkchang/Documents/family/dad/relationships/Heroic_Husband_Method_eBook_-_final_v2.6-22.pdf'
  chunk_size = (ARGV[1] || 100).to_i
  
  if File.exist?(input_path)
    chunks = split_pdf(input_path, chunk_size)
    puts "\nChunks created:"
    chunks.each { |chunk| puts "  - #{chunk[:filename]} (#{chunk[:page_count]} pages)" }
  else
    puts "Error: PDF file not found at #{input_path}"
    exit 1
  end
end