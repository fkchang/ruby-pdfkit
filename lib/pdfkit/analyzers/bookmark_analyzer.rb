# frozen_string_literal: true

require_relative 'base_analyzer'
require_relative '../models/bookmark'

module PDFKit
  module Analyzers
    # Analyzes PDF bookmark structure and hierarchy
    class BookmarkAnalyzer < BaseAnalyzer
      def analyze
        return [] unless document.has_bookmarks?

        extract_bookmark_hierarchy
      end

      private

      def extract_bookmark_hierarchy
        bookmarks = []
        outline = document.outline

        return bookmarks unless outline && outline[:First]

        traverse_outline(outline[:First], bookmarks, level: 1)
        bookmarks
      end

      def traverse_outline(outline_item, bookmarks, level: 1)
        return unless outline_item

        # Extract bookmark information
        title = extract_title(outline_item)
        page = extract_page_number(outline_item)

        if title && page
          bookmark = Models::Bookmark.new(
            title: title,
            page: page,
            level: level,
          )

          # Process children
          if outline_item[:First]
            children = []
            traverse_outline(outline_item[:First], children, level: level + 1)
            children.each { |child| bookmark.add_child(child) }
          end

          bookmarks << bookmark
        end

        # Process next sibling
        traverse_outline(outline_item[:Next], bookmarks, level: level)
      end

      def extract_title(outline_item)
        title = outline_item[:Title]
        return nil unless title

        # Handle different string encodings from HexaPDF
        case title
        when String
          title.encode('UTF-8', invalid: :replace, undef: :replace)
        else
          title.to_s.encode('UTF-8', invalid: :replace, undef: :replace)
        end
      rescue StandardError
        'Untitled'
      end

      def extract_page_number(outline_item)
        dest = outline_item[:Dest] || outline_item[:A]
        return nil unless dest

        case dest
        when Array, HexaPDF::PDFArray
          # Direct destination array [page_ref, /XYZ, left, top, zoom]
          page_ref = dest[0]
          resolve_page_reference(page_ref)
        when Hash
          # Action dictionary
          if dest[:S] == :GoTo && dest[:D]
            page_ref = dest[:D][0]
            resolve_page_reference(page_ref)
          end
        else
          nil
        end
      rescue StandardError
        nil
      end

      def resolve_page_reference(page_ref)
        return nil unless page_ref
        
        # Handle direct page objects (most common case)
        document.pages.each_with_index do |page, index|
          return index + 1 if page == page_ref || (page.respond_to?(:data) && page.data == page_ref)
        end

        # Handle HexaPDF::Reference objects
        if page_ref.is_a?(HexaPDF::Reference)
          # Find page number from page reference
          document.pages.each_with_index do |page, index|
            if page.is_a?(HexaPDF::Reference) && page.gen == page_ref.gen && page.oid == page_ref.oid
              return index + 1
            elsif page.respond_to?(:data) && page.data.is_a?(HexaPDF::Reference) && 
                  page.data.gen == page_ref.gen && page.data.oid == page_ref.oid
              return index + 1
            end
          end
          
          # Try resolving the reference to get the actual page object
          begin
            resolved_page = document.pdf_doc.object(page_ref)
            document.pages.each_with_index do |page, index|
              return index + 1 if page == resolved_page || (page.respond_to?(:data) && page.data == resolved_page)
            end
          rescue StandardError
            # Ignore resolution errors
          end
        end

        nil
      rescue StandardError
        nil
      end
    end
  end
end