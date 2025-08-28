# frozen_string_literal: true

module PDFKit
  module Models
    # Configuration options for PDF splitting operations
    class SplitOptions
      attr_reader :strategy, :max_pages, :max_tokens, :output_dir, :naming_pattern,
                  :preserve_metadata, :progress_callback

      def initialize(options = {})
        @strategy = options[:strategy] || :auto
        @max_pages = options[:max_pages]
        @max_tokens = options[:max_tokens]
        @output_dir = options[:output_dir] || './splits'
        @naming_pattern = options[:naming_pattern] || :default
        @preserve_metadata = options.fetch(:preserve_metadata, true)
        @progress_callback = options[:progress_callback]
      end

      def auto_strategy?
        strategy == :auto
      end

      def forced_strategy?
        !auto_strategy?
      end

      def has_page_limit?
        max_pages && max_pages > 0
      end

      def has_token_limit?
        max_tokens && max_tokens > 0
      end

      def effective_page_limit
        return max_pages if has_page_limit?
        return estimate_pages_from_tokens if has_token_limit?

        50 # Default page limit for fallback
      end

      def to_h
        {
          strategy: strategy,
          max_pages: max_pages,
          max_tokens: max_tokens,
          output_dir: output_dir,
          naming_pattern: naming_pattern,
          preserve_metadata: preserve_metadata,
        }
      end

      private

      def estimate_pages_from_tokens
        # Rough estimate: 300 words per page, 4 characters per word
        # 1 token ≈ 4 characters, so ~300 tokens per page
        return 100 unless max_tokens

        [(max_tokens / 300.0).ceil, 1].max
      end
    end
  end
end