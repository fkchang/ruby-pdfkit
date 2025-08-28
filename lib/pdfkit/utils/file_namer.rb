# frozen_string_literal: true

require 'fileutils'

module PDFKit
  module Utils
    # Utility for consistent file naming conventions
    class FileNamer
      def initialize(source_file, output_dir = './splits')
        @source_file = source_file
        @output_dir = output_dir
        @base_name = File.basename(source_file, '.*')
        ensure_output_directory
      end

      def section_name(index, section_title = nil)
        if section_title
          safe_title = sanitize_filename(section_title)
          "#{@base_name}_#{format('%03d', index)}_#{safe_title}.pdf"
        else
          "#{@base_name}_section_#{format('%03d', index)}.pdf"
        end
      end

      def page_range_name(start_page, end_page)
        start_str = format('%03d', start_page)
        end_str = format('%03d', end_page)
        "#{@base_name}_pages_#{start_str}-#{end_str}.pdf"
      end

      def chapter_name(chapter_number, chapter_title = nil)
        if chapter_title
          safe_title = sanitize_filename(chapter_title)
          "#{@base_name}_ch#{format('%02d', chapter_number)}_#{safe_title}.pdf"
        else
          "#{@base_name}_chapter_#{format('%02d', chapter_number)}.pdf"
        end
      end

      def full_path(filename)
        File.join(@output_dir, filename)
      end

      def output_directory
        @output_dir
      end

      private

      def ensure_output_directory
        return if Dir.exist?(@output_dir)

        begin
          FileUtils.mkdir_p(@output_dir)
        rescue StandardError => e
          raise "Failed to create output directory #{@output_dir}: #{e.message}"
        end
      end

      def sanitize_filename(filename)
        # Remove or replace invalid filename characters
        filename.gsub(/[^\w\s-]/, '')        # Remove special chars except word chars, spaces, hyphens
                .gsub(/\s+/, '_')            # Replace spaces with underscores
                .gsub(/_+/, '_')             # Collapse multiple underscores
                .gsub(/^_|_$/, '')           # Remove leading/trailing underscores
                .slice(0, 50)                # Limit length
                .downcase                    # Convert to lowercase
      end
    end
  end
end