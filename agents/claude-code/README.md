# Claude Code PDF Processing Agents

This directory contains Claude Code specific agents for intelligent PDF processing using ruby-pdfkit.

## Quick Start

1. Copy these agent files to your Claude Code project's `.claude/agents/` directory:
   ```bash
   cp agents/claude-code/*.md /your/project/.claude/agents/
   ```

2. Install ruby-pdfkit:
   ```bash
   gem install ruby-pdfkit
   ```

3. Use the main entry point:
   ```
   Use pdf-processor agent: "Summarize this document: /path/to/file.pdf"
   ```

## Agent Files

- **pdf-processor.md** - Main entry point, routes based on PDF size
- **pdf-splitter-processor.md** - Handles large PDFs with MapReduce processing  
- **pdf-chunk-processor.md** - Processes individual chunks in separate contexts

## System Requirements

- Claude Code environment
- Ruby 3.2+ with ruby-pdfkit gem
- Access to PDF files on the local filesystem

## Processing Flow

```
User Request
     ↓
pdf-processor (size detection)
     ↓
├─ Small PDF (≤100 pages) → Direct processing
└─ Large PDF (>100 pages) → pdf-splitter-processor
                                   ↓
                            Split using pdfkit
                                   ↓  
                         Spawn multiple pdf-chunk-processor agents
                                   ↓
                          Synthesize results → Final output
```

The entire process is automatic - users only need to interact with pdf-processor.