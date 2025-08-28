# frozen_string_literal: true

module PDFKit
  module Analyzers
    # Base class for all document analyzers
    class BaseAnalyzer
      def initialize(document)
        @document = document
      end

      # Abstract method - must be implemented by subclasses
      def analyze
        raise NotImplementedError, "#{self.class} must implement #analyze"
      end

      private

      attr_reader :document
    end
  end
end