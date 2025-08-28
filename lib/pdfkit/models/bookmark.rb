# frozen_string_literal: true

module PDFKit
  module Models
    # Represents a bookmark in a PDF document
    class Bookmark
      attr_reader :title, :page, :level, :children

      def initialize(title:, page:, level: 1, children: [])
        @title = title
        @page = page
        @level = level
        @children = children
      end

      def add_child(bookmark)
        @children << bookmark
      end

      def to_h
        {
          title: title,
          page: page,
          level: level,
          children: children.map(&:to_h),
        }
      end

      def has_children?
        !children.empty?
      end

      def display_text(indent = 0)
        prefix = '  ' * indent
        text = "#{prefix}#{title} (Page #{page})"
        
        if has_children?
          child_texts = children.map { |child| child.display_text(indent + 1) }
          "#{text}\n#{child_texts.join("\n")}"
        else
          text
        end
      end
    end
  end
end