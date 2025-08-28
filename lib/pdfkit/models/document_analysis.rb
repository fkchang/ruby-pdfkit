# frozen_string_literal: true

require_relative 'bookmark'
require_relative 'toc_entry'
require_relative 'content_pattern'

module PDFKit
  module Models
    # Container for complete document analysis results
    class DocumentAnalysis
      attr_reader :metadata, :bookmarks, :toc_entries, :content_patterns, :recommendations

      def initialize(metadata: {})
        @metadata = metadata
        @bookmarks = []
        @toc_entries = []
        @content_patterns = []
        @recommendations = {}
      end

      def add_bookmark(bookmark)
        @bookmarks << bookmark
      end

      def add_toc_entry(entry)
        @toc_entries << entry
      end

      def add_content_pattern(pattern)
        @content_patterns << pattern
      end

      def set_recommendations(recommendations)
        @recommendations = recommendations
      end

      def has_bookmarks?
        !bookmarks.empty?
      end

      def has_toc?
        !toc_entries.empty?
      end

      def has_content_patterns?
        !content_patterns.empty?
      end

      def to_h
        {
          metadata: metadata,
          bookmarks: bookmarks.map(&:to_h),
          toc: {
            detected: has_toc?,
            entries: toc_entries.map(&:to_h),
          },
          content_patterns: {
            headers: content_patterns.select(&:header?).map(&:to_h),
            sections: derive_sections,
          },
          recommendations: recommendations,
        }
      end

      def summary
        {
          total_pages: metadata[:pages] || 0,
          has_bookmarks: has_bookmarks?,
          bookmark_count: bookmarks.length,
          has_toc: has_toc?,
          toc_entries: toc_entries.length,
          content_patterns: content_patterns.length,
          recommended_strategy: recommendations[:primary_strategy],
          confidence: recommendations[:confidence],
        }
      end

      private

      def derive_sections
        # Simple section derivation from bookmarks or content patterns
        return bookmark_sections if has_bookmarks?
        return pattern_sections if has_content_patterns?

        []
      end

      def bookmark_sections
        bookmarks.select { |b| b.level == 1 }.map do |bookmark|
          {
            title: bookmark.title,
            start_page: bookmark.page,
            end_page: estimate_end_page(bookmark),
          }
        end
      end

      def pattern_sections
        headers = content_patterns.select(&:header?).select { |p| p.level == 1 }
        headers.map.with_index do |header, index|
          next_header = headers[index + 1]
          {
            title: header.text,
            start_page: header.page,
            end_page: next_header ? next_header.page - 1 : metadata[:pages],
          }
        end.compact
      end

      def estimate_end_page(bookmark)
        # Find next sibling bookmark at same or higher level
        current_index = bookmarks.index(bookmark)
        return metadata[:pages] unless current_index

        next_bookmarks = bookmarks[(current_index + 1)..]
        next_major = next_bookmarks.find { |b| b.level <= bookmark.level }
        
        next_major ? next_major.page - 1 : metadata[:pages]
      end
    end
  end
end