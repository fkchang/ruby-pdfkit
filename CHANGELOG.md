# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2025-08-28

### Added
- Initial release of ruby-pdfkit
- PDF analysis capabilities with bookmark and table of contents detection
- Intelligent PDF splitting strategies (bookmark-based, TOC-based, page-based)
- Command-line interface with analyze, info, and split commands
- Support for content-aware document segmentation optimized for AI/LLM workflows
- Comprehensive test suite with RSpec
- Ruby 3.2+ support

### Features
- **Document Analysis**: Extract PDF structure including bookmarks, TOC, and metadata
- **Smart Splitting**: Multiple strategies for content-aware PDF segmentation
- **CLI Interface**: Easy-to-use command-line tools for PDF processing
- **AI/LLM Optimization**: Split documents respecting context limits and content boundaries
- **Extensible Architecture**: Plugin-based system for analyzers and splitters