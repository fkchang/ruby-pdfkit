# frozen_string_literal: true

module PDFKit
  module Models
    # Result of a PDF splitting operation
    class SplitResult
      attr_reader :source_file, :output_files, :strategy_used, :total_pages,
                  :split_count, :metadata, :errors

      def initialize(source_file:, strategy_used:, total_pages: 0)
        @source_file = source_file
        @strategy_used = strategy_used
        @total_pages = total_pages
        @output_files = []
        @metadata = {}
        @errors = []
        @split_count = 0
      end

      def add_split_file(file_info)
        @output_files << file_info
        @split_count += 1
      end

      def add_error(error)
        @errors << error
      end

      def set_metadata(metadata)
        @metadata = metadata
      end

      def success?
        errors.empty? && split_count > 0
      end

      def partial_success?
        split_count > 0 && !errors.empty?
      end

      def failure?
        split_count == 0
      end

      def summary
        if success?
          "Successfully split #{source_file} into #{split_count} files using #{strategy_used} strategy"
        elsif partial_success?
          "Partially split #{source_file} into #{split_count} files with #{errors.length} errors"
        else
          "Failed to split #{source_file}: #{errors.join(', ')}"
        end
      end

      def to_h
        {
          source_file: source_file,
          strategy_used: strategy_used,
          total_pages: total_pages,
          split_count: split_count,
          output_files: output_files.map(&:to_h),
          metadata: metadata,
          errors: errors,
          success: success?,
        }
      end

      # Information about an individual split file
      class SplitFileInfo
        attr_reader :filename, :pages, :page_range, :section_title, :file_size

        def initialize(filename:, pages:, page_range:, section_title: nil)
          @filename = filename
          @pages = pages
          @page_range = page_range
          @section_title = section_title
          @file_size = File.exist?(filename) ? File.size(filename) : 0
        end

        def to_h
          {
            filename: filename,
            pages: pages,
            page_range: page_range,
            section_title: section_title,
            file_size: file_size,
          }
        end
      end
    end
  end
end