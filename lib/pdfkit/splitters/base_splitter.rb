# frozen_string_literal: true

require_relative '../models/split_result'

module PDFKit
  module Splitters
    # Base class for all PDF splitting strategies
    class BaseSplitter
      def initialize(document, analysis, options = {})
        @document = document
        @analysis = analysis
        @options = options
      end

      # Abstract method - must be implemented by subclasses
      def split
        raise NotImplementedError, "#{self.class} must implement #split"
      end

      # Returns true if this splitter can handle the given document analysis
      def can_handle?(analysis = @analysis)
        raise NotImplementedError, "#{self.class} must implement #can_handle?"
      end

      # Returns confidence score (0.0 to 1.0) for how well this splitter
      # can handle the document based on analysis
      def confidence_score(analysis = @analysis)
        raise NotImplementedError, "#{self.class} must implement #confidence_score"
      end

      # Strategy name for identification
      def strategy_name
        self.class.name.split('::').last.gsub(/Splitter$/, '').downcase
      end

      protected

      attr_reader :document, :analysis, :options

      def create_result
        Models::SplitResult.new(
          source_file: document.file_path,
          strategy_used: strategy_name,
          total_pages: document.pages.count,
        )
      end

      def report_progress(message, current = nil, total = nil)
        return unless options[:progress_callback]

        progress_data = {
          message: message,
          current: current,
          total: total,
          percentage: calculate_percentage(current, total),
        }

        options[:progress_callback].call(progress_data)
      end

      def calculate_percentage(current, total)
        return nil unless current && total && total > 0

        ((current.to_f / total) * 100).round(1)
      end

      def create_pdf_from_pages(source_doc, page_numbers, output_path)
        # Create a new PDF document
        new_doc = HexaPDF::Document.new

        # Copy pages from source document
        page_numbers.each do |page_num|
          source_page = source_doc.pages[page_num - 1] # Convert to 0-based index
          next unless source_page

          # Import page to new document
          new_doc.pages << new_doc.import(source_page)
        end

        # Copy document metadata
        if source_doc.trailer[:Info]
          source_info = source_doc.trailer[:Info]
          new_doc.trailer.info[:Title] = source_info[:Title] if source_info[:Title]
          new_doc.trailer.info[:Author] = source_info[:Author] if source_info[:Author]
          new_doc.trailer.info[:Creator] = source_info[:Creator] if source_info[:Creator]
          new_doc.trailer.info[:Producer] = source_info[:Producer] if source_info[:Producer]
        end

        # Write the new PDF
        new_doc.write(output_path)
        new_doc
      rescue StandardError => e
        raise "Failed to create PDF from pages #{page_numbers}: #{e.message}"
      end

      def safe_filename(text)
        text.to_s.gsub(/[^\w\s-]/, '').gsub(/\s+/, '_').downcase
      end
    end
  end
end