# frozen_string_literal: true

require_relative 'base_splitter'
require_relative '../utils/file_namer'

module PDFKit
  module Splitters
    # Splits PDF based on bookmark structure
    class BookmarkSplitter < BaseSplitter
      def split
        result = create_result
        
        unless can_handle?
          result.add_error('Document does not have reliable bookmark structure')
          return result
        end

        file_namer = Utils::FileNamer.new(document.file_path, options[:output_dir] || './splits')
        # Get top-level bookmarks (Chapter 1, Chapter 2, Chapter 3)
        top_level_bookmarks = analysis.bookmarks.select { |b| b.level == 1 }
        puts "Debug: Found #{top_level_bookmarks.length} top-level bookmarks" if ENV['DEBUG']
        
        report_progress('Starting bookmark-based splitting', 0, top_level_bookmarks.length)

        top_level_bookmarks.each_with_index do |bookmark, index|
          begin
            split_section(bookmark, index + 1, file_namer, result)
            report_progress("Processed section: #{bookmark.title}", index + 1, top_level_bookmarks.length)
          rescue StandardError => e
            result.add_error("Failed to split section '#{bookmark.title}': #{e.message}")
          end
        end

        result.set_metadata({
          bookmarks_processed: top_level_bookmarks.length,
          strategy_confidence: confidence_score,
        })

        result
      end

      def can_handle?(analysis = @analysis)
        return false unless analysis.has_bookmarks?
        
        # Need at least 2 bookmarks for meaningful splitting
        bookmarks = analysis.bookmarks.select { |b| b.level == 1 }
        bookmarks.length >= 2
      end

      def confidence_score(analysis = @analysis)
        return 0.0 unless can_handle?(analysis)

        bookmarks = analysis.bookmarks.select { |b| b.level == 1 }
        total_pages = analysis.metadata[:pages] || 1
        
        # Higher confidence for more bookmarks covering more of the document
        coverage = calculate_coverage(bookmarks, total_pages)
        bookmark_density = [bookmarks.length / 10.0, 1.0].min
        
        base_score = 0.7
        coverage_bonus = coverage * 0.2
        density_bonus = bookmark_density * 0.1
        
        [base_score + coverage_bonus + density_bonus, 1.0].min
      end

      private

      def split_section(bookmark, section_number, file_namer, result)
        start_page = bookmark.page
        end_page = determine_end_page(bookmark)
        
        return if start_page > end_page
        
        page_range = (start_page..end_page).to_a
        section_title = bookmark.title
        
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

      def determine_end_page(current_bookmark)
        # Find the next sibling bookmark at the same or higher level
        all_bookmarks = analysis.bookmarks
        current_index = all_bookmarks.index(current_bookmark)
        
        return analysis.metadata[:pages] unless current_index

        # Look for next bookmark at level 1 (same level as current)
        next_bookmarks = all_bookmarks[(current_index + 1)..]
        next_section = next_bookmarks.find { |b| b.level == 1 }
        
        if next_section
          next_section.page - 1
        else
          analysis.metadata[:pages] || current_bookmark.page
        end
      end

      def calculate_coverage(bookmarks, total_pages)
        return 0.0 if bookmarks.empty? || total_pages <= 0

        first_page = bookmarks.first.page
        last_page = bookmarks.last.page
        
        coverage_pages = last_page - first_page + 1
        coverage_pages.to_f / total_pages
      end
    end
  end
end