# PDFKit

A Ruby command-line tool for intelligent PDF analysis and manipulation, designed specifically for AI/LLM workflows that need to process large documents within context limits.

## Purpose

Large PDFs present a challenge for AI systems due to context window limitations. PDFKit solves this by providing intelligent document analysis and segmentation capabilities, allowing you to:

- **Analyze PDF structure** - Understand document organization before processing
- **Extract meaningful segments** - Split PDFs by logical boundaries (chapters, sections) rather than arbitrary page counts
- **Optimize for LLM consumption** - Create chunks that respect content boundaries and context limits
- **Preserve document context** - Maintain metadata and relationships between document sections

## Core Philosophy

PDFKit follows a **content-aware approach** to PDF processing:

1. **Understand first** - Analyze document structure before making decisions
2. **Respect boundaries** - Split along logical divisions (bookmarks, TOC, sections)
3. **Fallback gracefully** - Use page-based splitting when structure detection fails
4. **Preserve context** - Maintain metadata and section relationships

## Installation

```bash
gem install pdfkit
```

Or add to your Gemfile:
```ruby
gem 'pdfkit'
```

## Usage

### Basic Information
```bash
# Get document metadata and structure overview
pdfkit info document.pdf

# JSON output for programmatic use
pdfkit info --json document.pdf
```

### Structure Analysis
```bash
# Comprehensive document structure analysis
pdfkit analyze document.pdf

# Extract bookmark hierarchy
pdfkit bookmarks document.pdf

# Parse table of contents
pdfkit toc document.pdf
```

### Intelligent Splitting
```bash
# Smart splitting (uses best available strategy)
pdfkit split document.pdf

# Force specific strategy
pdfkit split document.pdf --strategy bookmarks
pdfkit split document.pdf --strategy pages --max-pages 50

# Split with LLM context awareness
pdfkit split document.pdf --max-tokens 4000
```

### Content Extraction
```bash
# Extract specific page ranges
pdfkit extract document.pdf 1-10,25-30

# Preview content from sections
pdfkit preview document.pdf --section "Chapter 1"
```

## Splitting Strategies

PDFKit automatically selects the best splitting strategy based on document characteristics:

1. **Bookmark-based** - Uses PDF outline/bookmarks (preferred)
2. **TOC-based** - Parses table of contents from document text
3. **Header detection** - Analyzes formatting patterns to detect sections
4. **Content-aware** - Maintains paragraph and section integrity
5. **Page-based** - Fallback option with configurable page limits

## Output Formats

- **Human-readable** - Default formatted text output
- **JSON** - Machine-readable format with `--json` flag
- **Metadata preservation** - All outputs include source page numbers and section context

## Use Cases

### AI/LLM Document Processing
- Split research papers by sections (Abstract, Introduction, Methods, Results)
- Process technical manuals chapter by chapter
- Segment legal documents by clauses and sections
- Break down books while preserving narrative flow

### Document Analysis
- Understand PDF structure before manual processing
- Extract specific sections for focused analysis
- Generate document summaries with section context
- Validate PDF accessibility and organization

### Content Management
- Prepare PDFs for content management systems
- Create focused document segments for team review
- Extract appendices and references separately
- Maintain document version control with section tracking

## Design Principles

PDFKit is built following clean architecture principles:

- **Single Responsibility** - Each component has one clear purpose
- **Strategy Pattern** - Pluggable splitting algorithms
- **Command Pattern** - Consistent operation interface
- **Dependency Injection** - Testable and extensible design

## Examples

### Academic Paper Processing
```bash
# Analyze structure
pdfkit analyze research_paper.pdf
# Output: Found sections: Abstract, Introduction, Methodology, Results, Discussion, References

# Split by sections
pdfkit split research_paper.pdf
# Creates: paper_01_abstract.pdf, paper_02_introduction.pdf, etc.
```

### Technical Manual Segmentation  
```bash
# Check for bookmarks
pdfkit bookmarks manual.pdf
# Output: Chapter 1: Setup, Chapter 2: Configuration, Chapter 3: Troubleshooting

# Split preserving chapters
pdfkit split manual.pdf --strategy bookmarks
# Creates: manual_ch01_setup.pdf, manual_ch02_configuration.pdf, etc.
```

### Large Document with No Structure
```bash
# Fallback to page-based splitting optimized for LLM context
pdfkit split large_document.pdf --max-tokens 3500
# Creates: document_pages_001-045.pdf, document_pages_046-089.pdf, etc.
```

## Claude Code Integration

Ruby-PDFKit includes intelligent agents designed specifically for Claude Code that provide seamless PDF processing with automatic handling of large documents.

### Agent System

The `agents/claude-code/` directory contains a **MapReduce-style PDF processing system**:

- **pdf-processor**: Main entry point that automatically routes based on PDF size
- **pdf-splitter-processor**: Orchestrates processing of large PDFs (>100 pages)
- **pdf-chunk-processor**: Handles individual chunks in separate context windows

### Quick Start with Claude Code

1. Copy agents to your Claude Code project:
   ```bash
   cp agents/claude-code/*.md /your/project/.claude/agents/
   ```

2. Use the main agent for any PDF processing:
   ```
   Use pdf-processor agent: "Please summarize this document: /path/to/file.pdf"
   ```

The system automatically:
- Detects PDF size and chooses optimal processing strategy
- Splits large PDFs using content-aware strategies (bookmarks, TOC, headers)
- Processes chunks in parallel with separate context windows
- Synthesizes results into comprehensive output

See `agents/README.md` for complete documentation.

## Contributing

PDFKit is designed for extensibility. New splitting strategies, analyzers, and formatters can be added easily through the plugin architecture.

## License

MIT License - see LICENSE file for details.

## Status

Currently in active development. Core functionality is stable, with ongoing enhancements for advanced document analysis features.