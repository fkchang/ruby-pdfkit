# frozen_string_literal: true

require 'json'
require_relative '../document'
require_relative '../models/document_analysis'
require_relative '../analyzers/bookmark_analyzer'
require_relative '../analyzers/toc_analyzer'
require_relative '../analyzers/content_analyzer'
require_relative '../analyzers/strategy_recommender'

module PDFKit
  module Commands
    # Command to perform comprehensive PDF structure analysis
    class Analyze
      # Custom error classes
      class FileNotFoundError < StandardError; end
      class InvalidPDFError < StandardError; end

      def initialize(file_path, options = {})
        @file_path = file_path
        @options = options
      end

      def execute
        validate_file_exists
        
        document = Document.new(@file_path)
        analysis = perform_analysis(document)
        
        if @options[:json]
          puts JSON.pretty_generate(analysis.to_h)
        else
          display_human_readable(analysis)
        end
      rescue HexaPDF::Error => e
        raise InvalidPDFError, "Invalid PDF file: #{e.message}"
      rescue StandardError => e
        raise InvalidPDFError, "Unable to analyze PDF: #{e.message}"
      end

      private

      def validate_file_exists
        return if File.exist?(@file_path)
        
        raise FileNotFoundError, "File not found: #{@file_path}"
      end

      def perform_analysis(document)
        analysis = Models::DocumentAnalysis.new(metadata: document.metadata)
        
        # Run all analyzers
        bookmarks = Analyzers::BookmarkAnalyzer.new(document).analyze
        toc_entries = Analyzers::TocAnalyzer.new(document).analyze
        content_patterns = Analyzers::ContentAnalyzer.new(document).analyze
        
        # Add results to analysis
        bookmarks.each { |bookmark| analysis.add_bookmark(bookmark) }
        toc_entries.each { |entry| analysis.add_toc_entry(entry) }
        content_patterns.each { |pattern| analysis.add_content_pattern(pattern) }
        
        # Generate recommendations
        recommendations = Analyzers::StrategyRecommender.new(analysis).analyze
        analysis.set_recommendations(recommendations)
        
        analysis
      end

      def display_human_readable(analysis)
        puts "PDF Structure Analysis"
        puts "=" * 50
        
        display_metadata(analysis)
        display_bookmarks(analysis) if analysis.has_bookmarks?
        display_toc(analysis) if analysis.has_toc?
        display_content_patterns(analysis) if analysis.has_content_patterns?
        display_recommendations(analysis)
      end

      def display_metadata(analysis)
        puts "\nDocument Metadata:"
        metadata = analysis.metadata
        puts "  File: #{@file_path}"
        puts "  Pages: #{metadata[:pages]}"
        puts "  Title: #{metadata[:title]}"
        puts "  Author: #{metadata[:author]}"
        puts "  PDF Version: #{metadata[:pdf_version]}"
      end

      def display_bookmarks(analysis)
        puts "\nBookmark Structure:"
        puts "  Found #{analysis.bookmarks.length} bookmarks"
        
        if analysis.bookmarks.length <= 20
          analysis.bookmarks.each do |bookmark|
            puts bookmark.display_text
          end
        else
          puts "  (Showing first 10 bookmarks - use --json for complete list)"
          analysis.bookmarks.first(10).each do |bookmark|
            puts bookmark.display_text
          end
        end
      end

      def display_toc(analysis)
        puts "\nTable of Contents:"
        puts "  Found #{analysis.toc_entries.length} TOC entries"
        
        if analysis.toc_entries.length <= 15
          analysis.toc_entries.each do |entry|
            puts entry.display_text(entry.level - 1)
          end
        else
          puts "  (Showing first 10 entries - use --json for complete list)"
          analysis.toc_entries.first(10).each do |entry|
            puts entry.display_text(entry.level - 1)
          end
        end
      end

      def display_content_patterns(analysis)
        headers = analysis.content_patterns.select(&:header?)
        return unless headers.any?

        puts "\nContent Patterns:"
        puts "  Found #{headers.length} header patterns"
        
        if headers.length <= 15
          headers.each do |header|
            puts header.display_text(header.level - 1)
          end
        else
          puts "  (Showing first 10 patterns - use --json for complete list)"
          headers.first(10).each do |header|
            puts header.display_text(header.level - 1)
          end
        end
      end

      def display_recommendations(analysis)
        recs = analysis.recommendations
        puts "\nRecommendations:"
        puts "  Primary Strategy: #{recs[:primary_strategy]}"
        puts "  Confidence: #{(recs[:confidence] * 100).round}%"
        puts "  Reasoning: #{recs[:reasoning]}"
        
        if recs[:fallback_strategies]&.any?
          puts "  Fallback Strategies: #{recs[:fallback_strategies].join(', ')}"
        end
      end
    end
  end
end