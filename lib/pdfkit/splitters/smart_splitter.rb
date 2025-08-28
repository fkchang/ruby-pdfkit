# frozen_string_literal: true

require_relative 'bookmark_splitter'
require_relative 'toc_splitter'
require_relative 'page_splitter'

module PDFKit
  module Splitters
    # Intelligent strategy selection for PDF splitting
    class SmartSplitter < BaseSplitter
      def split
        strategy = select_best_strategy
        puts "Selected strategy: #{strategy.strategy_name} (confidence: #{strategy.confidence_score.round(2)})"
        
        strategy.split
      end

      def can_handle?(analysis = @analysis)
        # Smart splitter can always handle - it will find an appropriate strategy
        true
      end

      def confidence_score(analysis = @analysis)
        # Return the confidence of the best available strategy
        best_strategy = select_best_strategy(analysis)
        best_strategy ? best_strategy.confidence_score : 0.0
      end

      private

      def select_best_strategy(analysis = @analysis)
        strategies = available_strategies(analysis)
        
        # Filter to strategies that can handle this document
        capable_strategies = strategies.select { |s| s.can_handle? }
        
        return strategies.last if capable_strategies.empty? # Fallback to page splitter
        
        # Select strategy with highest confidence
        capable_strategies.max_by { |s| s.confidence_score }
      end

      def available_strategies(analysis = @analysis)
        [
          BookmarkSplitter.new(document, analysis, options),
          TocSplitter.new(document, analysis, options),
          # HeaderSplitter.new(document, analysis, options),   # TODO: Future implementation
          PageSplitter.new(document, analysis, options),      # Always available fallback
        ]
      end
    end
  end
end