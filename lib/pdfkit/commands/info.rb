# frozen_string_literal: true

require 'json'
require 'hexapdf'

module PDFKit
  module Commands
    # Command to display PDF information and metadata
    class Info
      # Custom error classes for specific error handling
      class FileNotFoundError < StandardError; end
      class InvalidPDFError < StandardError; end

      def initialize(file_path, options = {})
        @file_path = file_path
        @options = options
      end

      def execute
        validate_file_exists

        pdf_info = extract_pdf_info

        if @options[:json]
          puts JSON.pretty_generate(pdf_info)
        else
          display_human_readable(pdf_info)
        end
      end

      private

      def validate_file_exists
        return if File.exist?(@file_path)

        raise FileNotFoundError, "File not found: #{@file_path}"
      end

      def extract_pdf_info
        doc = HexaPDF::Document.open(@file_path)
        info_dict = doc.trailer[:Info] || {}

        {
          file: @file_path,
          pages: doc.pages.count,
          title: extract_string_value(info_dict[:Title]) || 'Unknown',
          author: extract_string_value(info_dict[:Author]) || 'Unknown',
          creator: extract_string_value(info_dict[:Creator]) || 'Unknown',
          producer: extract_string_value(info_dict[:Producer]) || 'Unknown',
          creation_date: format_date(info_dict[:CreationDate]),
          modification_date: format_date(info_dict[:ModDate]),
          pdf_version: doc.version,
          file_size: File.size(@file_path),
          has_bookmarks: has_bookmarks?(doc),
        }
      rescue HexaPDF::Error => e
        raise InvalidPDFError, "Invalid PDF file: #{e.message}"
      rescue StandardError => e
        raise InvalidPDFError, "Unable to read PDF: #{e.message}"
      end

      def extract_string_value(value)
        return nil if value.nil?

        # Handle HexaPDF string objects
        value.respond_to?(:to_s) ? value.to_s : value
      end

      def format_date(date_value)
        return 'Unknown' if date_value.nil?

        # Handle different date formats from PDFs
        date_str = extract_string_value(date_value)
        return 'Unknown' if date_str.nil? || date_str.empty?

        # PDF dates are often in format: D:YYYYMMDDHHmmSSOHH'mm'
        if date_str =~ /^D:(\d{4})(\d{2})(\d{2})/
          "#{::Regexp.last_match(1)}-#{::Regexp.last_match(2)}-#{::Regexp.last_match(3)}"
        else
          date_str
        end
      end

      def has_bookmarks?(doc)
        outline = doc.outline
        !!(outline && outline[:First])
      rescue StandardError
        false
      end

      def display_human_readable(info)
        puts 'PDF Information:'
        puts "  File: #{info[:file]}"
        puts "  Pages: #{info[:pages]}"
        puts "  Title: #{info[:title]}"
        puts "  Author: #{info[:author]}"
        puts "  Creator: #{info[:creator]}"
        puts "  Producer: #{info[:producer]}"
        puts "  Created: #{info[:creation_date]}"
        puts "  Modified: #{info[:modification_date]}"
        puts "  PDF Version: #{info[:pdf_version]}"
        puts "  File Size: #{format_file_size(info[:file_size])}"
        puts "  Has Bookmarks: #{info[:has_bookmarks] ? 'Yes' : 'No'}"
      end

      def format_file_size(bytes)
        units = %w[B KB MB GB]
        size = bytes.to_f
        unit_index = 0

        while size >= 1024 && unit_index < units.length - 1
          size /= 1024
          unit_index += 1
        end

        "#{size.round(2)} #{units[unit_index]}"
      end
    end
  end
end
