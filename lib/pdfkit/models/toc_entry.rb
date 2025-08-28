# frozen_string_literal: true

module PDFKit
  module Models
    # Represents a table of contents entry
    class TocEntry
      attr_reader :title, :page, :level

      def initialize(title:, page:, level: 1)
        @title = title.strip
        @page = page
        @level = level
      end

      def to_h
        {
          title: title,
          page: page,
          level: level,
        }
      end

      def display_text(indent = 0)
        prefix = '  ' * indent
        "#{prefix}#{title} ... #{page}"
      end
    end
  end
end