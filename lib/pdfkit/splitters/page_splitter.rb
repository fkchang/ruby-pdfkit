# frozen_string_literal: true

require_relative 'base_splitter'
require_relative '../utils/file_namer'

module PDFKit
  module Splitters
    # Splits PDF based on page ranges - fallback strategy
    class PageSplitter < BaseSplitter
      def split
        result = create_result
        
        max_pages = determine_max_pages
        total_pages = document.pages.count
        file_namer = Utils::FileNamer.new(document.file_path, options[:output_dir] || './splits')
        
        page_ranges = calculate_page_ranges(total_pages, max_pages)
        
        report_progress('Starting page-based splitting', 0, page_ranges.length)

        page_ranges.each_with_index do |range, index|
          begin
            split_page_range(range, index + 1, file_namer, result)
            report_progress("Processed pages #{range.first}-#{range.last}", index + 1, page_ranges.length)
          rescue StandardError => e
            result.add_error("Failed to split pages #{range.first}-#{range.last}: #{e.message}")
          end
        end

        result.set_metadata({
          max_pages_per_split: max_pages,
          total_splits: page_ranges.length,
          strategy_confidence: confidence_score,
        })

        result
      end

      def can_handle?(analysis = @analysis)
        # Page splitter can always handle any document as fallback
        true
      end

      def confidence_score(analysis = @analysis)
        # Low confidence - this is the fallback strategy
        if analysis.has_bookmarks? || analysis.has_toc? || analysis.has_content_patterns?
          0.3 # Lower confidence when structure is available
        else
          0.4 # Slightly higher when no structure detected
        end
      end

      private

      def determine_max_pages
        # Priority order for determining page limits
        return options[:max_pages] if options[:max_pages] && options[:max_pages] > 0
        return estimate_pages_from_tokens if options[:max_tokens] && options[:max_tokens] > 0
        
        # Default fallback - reasonable for AI processing
        50
      end

      def estimate_pages_from_tokens
        max_tokens = options[:max_tokens]
        return 50 unless max_tokens

        # Rough estimate: 300 words per page, ~1.3 tokens per word
        # So approximately 400 tokens per page
        estimated_pages = (max_tokens / 400.0).ceil
        [estimated_pages, 1].max
      end

      def calculate_page_ranges(total_pages, max_pages_per_split)
        ranges = []
        current_page = 1

        while current_page <= total_pages
          end_page = [current_page + max_pages_per_split - 1, total_pages].min
          ranges << (current_page..end_page)
          current_page = end_page + 1
        end

        ranges
      end

      def split_page_range(page_range, split_number, file_namer, result)
        pages = page_range.to_a
        
        filename = file_namer.page_range_name(page_range.first, page_range.last)
        output_path = file_namer.full_path(filename)
        
        create_pdf_from_pages(document.pdf_doc, pages, output_path)
        
        file_info = Models::SplitResult::SplitFileInfo.new(
          filename: output_path,
          pages: pages.length,
          page_range: "#{page_range.first}-#{page_range.last}",
          section_title: "Pages #{page_range.first}-#{page_range.last}",
        )
        
        result.add_split_file(file_info)
      end
    end
  end
end