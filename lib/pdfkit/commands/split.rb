# frozen_string_literal: true

require 'json'
require_relative '../document'
require_relative '../models/document_analysis'
require_relative '../models/split_options'
require_relative '../analyzers/bookmark_analyzer'
require_relative '../analyzers/toc_analyzer'
require_relative '../analyzers/content_analyzer'
require_relative '../analyzers/strategy_recommender'
require_relative '../splitters/smart_splitter'
require_relative '../splitters/bookmark_splitter'
require_relative '../splitters/toc_splitter'
require_relative '../splitters/page_splitter'

module PDFKit
  module Commands
    # Command to perform intelligent PDF splitting
    class Split
      # Custom error classes
      class FileNotFoundError < StandardError; end
      class InvalidPDFError < StandardError; end
      class SplitError < StandardError; end

      VALID_STRATEGIES = %w[auto bookmarks toc pages].freeze

      def initialize(file_path, options = {})
        @file_path = file_path
        @raw_options = options
        @split_options = Models::SplitOptions.new(process_options(options))
      end

      def execute
        validate_file_exists
        validate_options
        
        document = Document.new(@file_path)
        analysis = perform_analysis(document)
        
        splitter = create_splitter(document, analysis)
        result = splitter.split
        
        if @raw_options[:json]
          puts JSON.pretty_generate(result.to_h)
        else
          display_human_readable(result)
        end
        
        exit 1 unless result.success?
        
      rescue HexaPDF::Error => e
        raise InvalidPDFError, "Invalid PDF file: #{e.message}"
      rescue StandardError => e
        raise SplitError, "Unable to split PDF: #{e.message}"
      end

      private

      def validate_file_exists
        return if File.exist?(@file_path)
        
        raise FileNotFoundError, "File not found: #{@file_path}"
      end

      def validate_options
        return if @split_options.strategy == :auto

        unless VALID_STRATEGIES.include?(@split_options.strategy.to_s)
          raise SplitError, "Invalid strategy: #{@split_options.strategy}. Valid options: #{VALID_STRATEGIES.join(', ')}"
        end
      end

      def process_options(options)
        processed = {
          strategy: (options[:strategy] || 'auto').to_sym,
          max_pages: options[:max_pages],
          max_tokens: options[:max_tokens],
          output_dir: options[:output_dir] || './splits',
          progress_callback: create_progress_callback,
        }

        # Convert max-pages and max-tokens from string if needed
        processed[:max_pages] = processed[:max_pages].to_i if processed[:max_pages]
        processed[:max_tokens] = processed[:max_tokens].to_i if processed[:max_tokens]

        processed
      end

      def create_progress_callback
        return nil if @raw_options[:json] # No progress output for JSON mode

        lambda do |progress|
          message = progress[:message]
          if progress[:current] && progress[:total]
            puts "#{message} (#{progress[:current]}/#{progress[:total]})"
          else
            puts message
          end
        end
      end

      def perform_analysis(document)
        analysis = Models::DocumentAnalysis.new(metadata: document.metadata)
        
        # Run analyzers
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

      def create_splitter(document, analysis)
        case @split_options.strategy
        when :bookmarks
          Splitters::BookmarkSplitter.new(document, analysis, @split_options.to_h)
        when :toc
          Splitters::TocSplitter.new(document, analysis, @split_options.to_h)
        when :pages
          Splitters::PageSplitter.new(document, analysis, @split_options.to_h)
        when :auto
          Splitters::SmartSplitter.new(document, analysis, @split_options.to_h)
        else
          raise SplitError, "Unsupported strategy: #{@split_options.strategy}"
        end
      end

      def display_human_readable(result)
        puts "PDF Splitting Results"
        puts "=" * 50
        
        puts "\nSource: #{result.source_file}"
        puts "Strategy: #{result.strategy_used}"
        puts "Total Pages: #{result.total_pages}"
        puts "Output Directory: #{@split_options.output_dir}"
        
        if result.success?
          puts "\n✅ Successfully created #{result.split_count} split files:"
          result.output_files.each_with_index do |file_info, index|
            puts "  #{index + 1}. #{File.basename(file_info.filename)} (#{file_info.pages} pages)"
            puts "     Pages: #{file_info.page_range}"
            puts "     Title: #{file_info.section_title}" if file_info.section_title
          end
        elsif result.partial_success?
          puts "\n⚠️  Partially successful - created #{result.split_count} files with errors:"
          result.errors.each { |error| puts "  ❌ #{error}" }
        else
          puts "\n❌ Split failed:"
          result.errors.each { |error| puts "  • #{error}" }
        end
        
        puts "\n#{result.summary}"
      end
    end
  end
end