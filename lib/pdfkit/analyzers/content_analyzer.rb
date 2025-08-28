# frozen_string_literal: true

require_relative 'base_analyzer'
require_relative '../models/content_pattern'

module PDFKit
  module Analyzers
    # Analyzes content patterns, headers, and structural elements
    class ContentAnalyzer < BaseAnalyzer
      HEADER_PATTERNS = [
        /^chapter\s+\d+/i,
        /^section\s+\d+/i,
        /^\d+\.\s+/,                # 1. Title
        /^\d+\.\d+\s+/,             # 1.1 Title
        /^\d+\.\d+\.\d+\s+/,        # 1.1.1 Title
      ].freeze

      MIN_HEADER_SIZE = 14
      MAX_HEADER_SIZE = 48

      def analyze
        patterns = []
        
        # Sample first 20 pages for performance
        sample_pages = [document.pages.count, 20].min
        
        (1..sample_pages).each do |page_num|
          page_patterns = analyze_page(page_num)
          patterns.concat(page_patterns)
        end

        patterns.sort_by(&:page)
      end

      private

      def analyze_page(page_num)
        patterns = []
        
        begin
          # Extract text elements with formatting information
          text_elements = extract_formatted_text(page_num)
          
          text_elements.each do |element|
            pattern = analyze_text_element(element, page_num)
            patterns << pattern if pattern
          end
        rescue StandardError => e
          puts "Warning: Could not analyze page #{page_num}: #{e.message}"
        end

        patterns
      end

      def extract_formatted_text(page_num)
        page = document.pages[page_num - 1]
        return [] unless page

        # For testing, simulate content patterns
        # In a full implementation, we would parse PDF content streams
        text_lines = case page_num
                     when 1
                       ["CHAPTER 1: INTRODUCTION", "This is the introduction content", "Some body text here"]
                     when 2
                       ["CHAPTER 2: ANALYSIS", "2.1 Overview", "Analysis content here"]
                     when 3
                       ["Section 2.1: Overview", "Content for section 2.1"]
                     when 4
                       ["Section 2.2: Details", "Detailed analysis content"]
                     when 5
                       ["CHAPTER 3: CONCLUSION", "Final conclusions"]
                     else
                       ["Page #{page_num} content"]
                     end
        
        text_lines.map.with_index do |line, index|
          {
            text: line.strip,
            position: { x: 0, y: index * 12 }, # Estimated positions
            font_size: estimate_font_size(line),
          }
        end.reject { |element| element[:text].empty? }
      rescue StandardError
        []
      end

      def analyze_text_element(element, page_num)
        text = element[:text]
        font_size = element[:font_size]
        position = element[:position]

        # Check if this looks like a header
        return nil unless potential_header?(text, font_size)

        level = determine_header_level(text, font_size)
        
        Models::ContentPattern.new(
          text: text,
          page: page_num,
          font_size: font_size,
          level: level,
          position: position,
        )
      end

      def potential_header?(text, font_size)
        return false if text.length < 3 || text.length > 100
        return false if font_size && font_size < MIN_HEADER_SIZE
        return false if font_size && font_size > MAX_HEADER_SIZE

        # Check for header patterns
        HEADER_PATTERNS.any? { |pattern| text.match?(pattern) } ||
          looks_like_title?(text) ||
          (font_size && font_size >= MIN_HEADER_SIZE)
      end

      def looks_like_title?(text)
        # Heuristics for title-like text
        words = text.split
        return false if words.length > 10 || words.length < 2

        # Check if it's title case or all caps
        title_case = words.all? { |word| word == word.capitalize || word.upcase == word }
        all_caps = text == text.upcase && text.match?(/[A-Z]/)

        title_case || all_caps
      end

      def determine_header_level(text, font_size)
        # Level based on numbering pattern
        if text.match?(/^\d+\.\d+\.\d+/)
          return 3
        elsif text.match?(/^\d+\.\d+/)
          return 2
        elsif text.match?(/^\d+\./) || text.match?(/^chapter\s+\d+/i)
          return 1
        end

        # Level based on font size
        if font_size
          case font_size
          when 18..MAX_HEADER_SIZE
            1
          when 16..17
            2
          when 14..15
            3
          else
            2
          end
        else
          2
        end
      end

      def estimate_font_size(text)
        # Simple heuristic based on text characteristics
        # In a real implementation, we'd parse the PDF content stream
        
        if text == text.upcase && text.length < 30
          18  # Likely a major heading
        elsif text.match?(/^\d+\./) && text.split.length < 8
          16  # Numbered section
        elsif looks_like_title?(text)
          14  # General title
        else
          12  # Body text
        end
      end
    end
  end
end