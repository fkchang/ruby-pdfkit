# frozen_string_literal: true

require_relative 'base_splitter'
require_relative '../utils/file_namer'

module PDFKit
  module Splitters
    # Splits PDF based on table of contents structure
    class TocSplitter < BaseSplitter
      # Default max pages per segment (can be overridden in options)
      DEFAULT_MAX_PAGES = 100

      def max_pages
        options[:max_pages] || DEFAULT_MAX_PAGES
      end

      def segment_exceeds_max_pages?(start_page, end_page)
        page_count = end_page - start_page + 1
        page_count > max_pages
      end

      def split_large_section(toc_entry, start_page, end_page, section_number, file_namer, result)
        current_page = start_page
        part_number = 1
        
        while current_page <= end_page
          segment_end = [current_page + max_pages - 1, end_page].min
          
          section_title = if segment_end == end_page && current_page == start_page
            # Single segment, use original title
            toc_entry.title
          else
            # Multiple segments, add part number
            "#{toc_entry.title} (Part #{part_number})"
          end
          
          create_single_segment(current_page, segment_end, section_title, section_number, file_namer, result)
          
          current_page = segment_end + 1
          part_number += 1
        end
      end

      # Helper method to create a single PDF segment
      def create_single_segment(start_page, end_page, section_title, section_number, file_namer, result)
        page_range = (start_page..end_page).to_a
        
        filename = file_namer.chapter_name(section_number, section_title)
        output_path = file_namer.full_path(filename)
        
        create_pdf_from_pages(document.pdf_doc, page_range, output_path)
        
        file_info = Models::SplitResult::SplitFileInfo.new(
          filename: output_path,
          pages: page_range.length,
          page_range: "#{start_page}-#{end_page}",
          section_title: section_title,
        )
        
        result.add_split_file(file_info)
      end
      def split
        result = create_result
        
        unless can_handle?
          result.add_error('Document does not have detectable table of contents')
          return result
        end

        file_namer = Utils::FileNamer.new(document.file_path, options[:output_dir] || './splits')
        # Get chapter-level TOC entries (level 1)
        chapters = analysis.toc_entries.select { |entry| entry.level == 1 }
        puts "Debug: Found #{chapters.length} chapter-level TOC entries" if ENV['DEBUG']
        
        # Check if we need to handle pages before first TOC entry
        first_toc_page = chapters.first&.page || 1
        total_sections = chapters.length
        if first_toc_page > 1
          total_sections += 1 # Add front matter section
          puts "Debug: Will create front matter section for pages 1-#{first_toc_page - 1}" if ENV['DEBUG']
        end
        
        report_progress('Starting TOC-based splitting', 0, total_sections)

        section_index = 0
        
        # Handle front matter if exists
        if first_toc_page > 1
          split_front_matter(first_toc_page - 1, section_index + 1, file_namer, result)
          section_index += 1
          report_progress("Processed front matter (pages 1-#{first_toc_page - 1})", section_index, total_sections)
        end

        chapters.each_with_index do |toc_entry, index|
          begin
            split_section(toc_entry, section_index + index + 1, file_namer, result)
            report_progress("Processed section: #{toc_entry.title}", section_index + index + 1, total_sections)
          rescue StandardError => e
            result.add_error("Failed to split section '#{toc_entry.title}': #{e.message}")
          end
        end

        result.set_metadata({
          toc_entries_processed: chapters.length,
          strategy_confidence: confidence_score,
        })

        result
      end

      def can_handle?(analysis = @analysis)
        return false unless analysis.has_toc?
        
        # Need at least 2 chapter-level TOC entries for meaningful splitting
        chapters = analysis.toc_entries.select { |entry| entry.level == 1 }
        chapters.length >= 2
      end

      def confidence_score(analysis = @analysis)
        return 0.0 unless can_handle?(analysis)

        chapters = analysis.toc_entries.select { |entry| entry.level == 1 }
        total_pages = analysis.metadata[:pages] || 1
        
        # Higher confidence for more chapters covering more of the document
        coverage = calculate_coverage(chapters, total_pages)
        chapter_density = [chapters.length / 10.0, 1.0].min
        
        # TOC entries are generally more reliable than content patterns
        base_score = 0.8
        coverage_bonus = coverage * 0.15
        density_bonus = chapter_density * 0.05
        
        [base_score + coverage_bonus + density_bonus, 1.0].min
      end

      private

      def split_front_matter(end_page, section_number, file_namer, result)
        start_page = 1
        
        return if start_page > end_page
        
        # Check if front matter exceeds max_pages limit
        if segment_exceeds_max_pages?(start_page, end_page)
          # Create a mock TOC entry for front matter to use split_large_section
          front_matter_entry = Struct.new(:title).new("Front Matter")
          split_large_section(front_matter_entry, start_page, end_page, section_number, file_namer, result)
        else
          # Normal single front matter section
          create_single_segment(start_page, end_page, "Front Matter", section_number, file_namer, result)
        end
      end

      def split_section(toc_entry, section_number, file_namer, result)
        start_page = toc_entry.page
        end_page = determine_end_page(toc_entry)
        
        return if start_page > end_page
        
        # Check if this section exceeds max_pages limit
        if segment_exceeds_max_pages?(start_page, end_page)
          # Split large section into smaller segments
          split_large_section(toc_entry, start_page, end_page, section_number, file_namer, result)
        else
          # Normal single section split
          create_single_segment(start_page, end_page, toc_entry.title, section_number, file_namer, result)
        end
      end

      def determine_end_page(current_toc_entry)
        # Find the next sibling TOC entry at the same or higher level
        all_entries = analysis.toc_entries
        current_index = all_entries.index(current_toc_entry)
        
        return analysis.metadata[:pages] unless current_index

        # Look for next TOC entry at level 1 (same level as current)
        next_entries = all_entries[(current_index + 1)..]
        next_section = next_entries.find { |entry| entry.level == 1 }
        
        if next_section
          next_section.page - 1
        else
          analysis.metadata[:pages] || current_toc_entry.page
        end
      end

      def calculate_coverage(chapters, total_pages)
        return 0.0 if chapters.empty? || total_pages <= 0

        first_page = chapters.first.page
        last_page = chapters.last.page
        
        coverage_pages = last_page - first_page + 1
        coverage_pages.to_f / total_pages
      end
    end
  end
end