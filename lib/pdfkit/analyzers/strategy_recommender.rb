# frozen_string_literal: true

require_relative 'base_analyzer'

module PDFKit
  module Analyzers
    # Recommends optimal splitting strategies based on document analysis
    class StrategyRecommender < BaseAnalyzer
      STRATEGIES = %w[bookmarks toc headers pages].freeze

      def analyze
        analysis = document
        recommendations = {
          primary_strategy: determine_primary_strategy(analysis),
          fallback_strategies: determine_fallback_strategies(analysis),
          confidence: calculate_confidence(analysis),
          reasoning: generate_reasoning(analysis),
        }

        recommendations
      end

      private

      def determine_primary_strategy(analysis)
        return 'bookmarks' if reliable_bookmarks?(analysis)
        return 'toc' if reliable_toc?(analysis)
        return 'headers' if reliable_headers?(analysis)

        'pages'
      end

      def determine_fallback_strategies(analysis)
        fallbacks = []
        
        fallbacks << 'toc' if analysis.has_toc? && !reliable_bookmarks?(analysis)
        fallbacks << 'headers' if analysis.has_content_patterns? && !reliable_bookmarks?(analysis)
        fallbacks << 'pages' unless fallbacks.include?('pages')

        fallbacks
      end

      def calculate_confidence(analysis)
        return 0.95 if reliable_bookmarks?(analysis)
        return 0.80 if reliable_toc?(analysis)
        return 0.65 if reliable_headers?(analysis)

        0.40 # Page-based fallback
      end

      def generate_reasoning(analysis)
        primary = determine_primary_strategy(analysis)

        case primary
        when 'bookmarks'
          reason = 'Document has comprehensive bookmark structure'
          bookmark_count = analysis.bookmarks.length
          reason += " with #{bookmark_count} bookmarks" if bookmark_count > 0
        when 'toc'
          toc_count = analysis.toc_entries.length
          "Document has detectable table of contents with #{toc_count} entries"
        when 'headers'
          header_count = analysis.content_patterns.select(&:header?).length
          "Document has structured headers with #{header_count} detected patterns"
        when 'pages'
          'No reliable structure detected, falling back to page-based splitting'
        else
          'Analysis completed'
        end
      end

      def reliable_bookmarks?(analysis)
        return false unless analysis.has_bookmarks?

        bookmarks = analysis.bookmarks
        return false if bookmarks.length < 2

        # Check for reasonable page distribution
        pages = bookmarks.map(&:page).sort
        total_pages = analysis.metadata[:pages] || 1
        
        # Bookmarks should cover reasonable portion of document
        coverage = (pages.last - pages.first).to_f / total_pages
        coverage > 0.3 && pages.uniq.length > 1
      end

      def reliable_toc?(analysis)
        return false unless analysis.has_toc?

        entries = analysis.toc_entries
        return false if entries.length < 3

        # Check that page numbers make sense
        pages = entries.map(&:page).compact.sort
        return false if pages.empty?

        # TOC pages should be sequential and reasonable
        total_pages = analysis.metadata[:pages] || 1
        pages.all? { |p| p > 0 && p <= total_pages } && pages.uniq.length > 2
      end

      def reliable_headers?(analysis)
        return false unless analysis.has_content_patterns?

        headers = analysis.content_patterns.select(&:header?)
        return false if headers.length < 3

        # Check for hierarchical structure
        levels = headers.map(&:level).uniq.sort
        levels.include?(1) && headers.length > 3
      end
    end
  end
end