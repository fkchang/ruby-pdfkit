# frozen_string_literal: true

require 'thor'
require_relative 'commands/info'
require_relative 'commands/analyze'
require_relative 'commands/split'

module PDFKit
  # Command Line Interface for PDFKit
  class CLI < Thor
    def self.exit_on_failure?
      true
    end

    desc 'version', 'Show version information'
    def version
      puts "PDFKit #{PDFKit::VERSION}"
    end
    map %w[-v --version] => :version

    desc 'info FILE', 'Display PDF metadata and basic information'
    option :json, type: :boolean, default: false, desc: 'Output in JSON format'
    def info(file_path)
      Commands::Info.new(file_path, options).execute
    rescue Commands::Info::FileNotFoundError => e
      puts "Error: #{e.message}"
      exit 2
    rescue Commands::Info::InvalidPDFError => e
      puts "Error: #{e.message}"
      exit 3
    rescue StandardError => e
      puts "Error: #{e.message}"
      exit 1
    end

    desc 'analyze FILE', 'Perform comprehensive PDF structure analysis'
    option :json, type: :boolean, default: false, desc: 'Output in JSON format'
    def analyze(file_path)
      Commands::Analyze.new(file_path, options).execute
    rescue Commands::Analyze::FileNotFoundError => e
      puts "Error: #{e.message}"
      exit 2
    rescue Commands::Analyze::InvalidPDFError => e
      puts "Error: #{e.message}"
      exit 3
    rescue StandardError => e
      puts "Error: #{e.message}"
      exit 1
    end

    desc 'split FILE', 'Split PDF using intelligent strategy selection'
    option :json, type: :boolean, default: false, desc: 'Output in JSON format'
    option :strategy, type: :string, desc: 'Force specific strategy (auto, bookmarks, toc, pages)'
    option :max_pages, type: :numeric, desc: 'Maximum pages per split'
    option :max_tokens, type: :numeric, desc: 'Maximum tokens per split (estimated)'
    option :output_dir, type: :string, default: './splits', desc: 'Output directory for split files'
    def split(file_path)
      Commands::Split.new(file_path, options).execute
    rescue Commands::Split::FileNotFoundError => e
      puts "Error: #{e.message}"
      exit 2
    rescue Commands::Split::InvalidPDFError => e
      puts "Error: #{e.message}"
      exit 3
    rescue Commands::Split::SplitError => e
      puts "Error: #{e.message}"
      exit 4
    rescue StandardError => e
      puts "Error: #{e.message}"
      exit 1
    end
  end
end
