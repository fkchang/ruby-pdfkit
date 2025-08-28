# frozen_string_literal: true

module PDFKit
  module Models
    # Represents detected content patterns in a document
    class ContentPattern
      attr_reader :text, :page, :font_size, :level, :position

      def initialize(text:, page:, font_size: nil, level: 1, position: nil)
        @text = text.strip
        @page = page
        @font_size = font_size
        @level = level
        @position = position
      end

      def to_h
        {
          text: text,
          page: page,
          font_size: font_size,
          level: level,
          position: position,
        }.compact
      end

      def header?
        level <= 3 && font_size && font_size > 12
      end

      def display_text(indent = 0)
        prefix = '  ' * indent
        size_info = font_size ? " (#{font_size}pt)" : ''
        "#{prefix}#{text}#{size_info} [Page #{page}]"
      end
    end
  end
end