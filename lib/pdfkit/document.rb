# frozen_string_literal: true

require 'hexapdf'

module PDFKit
  # Wrapper for PDF document with analysis capabilities
  class Document
    attr_reader :file_path, :pdf_doc

    def initialize(file_path)
      @file_path = file_path
      @pdf_doc = HexaPDF::Document.open(file_path)
    end

    def pages
      pdf_doc.pages
    end

    def metadata
      info_dict = pdf_doc.trailer[:Info] || {}
      {
        pages: pages.count,
        title: extract_string_value(info_dict[:Title]) || 'Unknown',
        author: extract_string_value(info_dict[:Author]) || 'Unknown',
        creator: extract_string_value(info_dict[:Creator]) || 'Unknown',
        producer: extract_string_value(info_dict[:Producer]) || 'Unknown',
        pdf_version: pdf_doc.version,
        file_size: File.size(file_path),
      }
    end

    def has_bookmarks?
      outline = pdf_doc.outline
      !!(outline && outline[:First])
    rescue StandardError
      false
    end

    def outline
      pdf_doc.outline
    rescue StandardError
      nil
    end

    private

    def extract_string_value(value)
      return nil if value.nil?

      # Handle HexaPDF string objects
      value.respond_to?(:to_s) ? value.to_s : value
    end
  end
end