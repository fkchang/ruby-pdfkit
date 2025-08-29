# Ruby-PDFKit Agents

This directory contains intelligent agents designed to work with various AI/LLM systems for PDF processing tasks.

## Directory Structure

```
agents/
├── README.md              # This file
├── claude-code/          # Claude Code specific agents
│   ├── pdf-processor.md
│   ├── pdf-splitter-processor.md
│   └── pdf-chunk-processor.md
└── [future-system]/      # Reserved for other agentic systems
```

## Agent Hierarchy

Ruby-PDFKit implements a **MapReduce-style PDF processing system** with three specialized agents:

### 1. pdf-processor (Main Entry Point)
- **Purpose**: Routes all PDF processing requests based on document size
- **Decision Logic**: Uses `pdfkit info` to detect page count
  - ≤100 pages: Processes directly
  - >100 pages: Delegates to pdf-splitter-processor
- **Use Cases**: Summarization, analysis, data extraction, Q&A on any PDF

### 2. pdf-splitter-processor (MapReduce Orchestrator)  
- **Purpose**: Handles large PDFs that exceed Claude's 100-page limit
- **Process**: 
  1. Intelligently splits PDFs using ruby-pdfkit CLI tools
  2. Automatically delegates each chunk to pdf-chunk-processor subagents
  3. Synthesizes results from all subagents into comprehensive output
- **Splitting Strategies**: Bookmark-based, TOC-based, header detection, page-based fallback

### 3. pdf-chunk-processor (Individual Chunk Handler)
- **Purpose**: Processes individual PDF chunks (<100 pages)
- **Context**: Each agent gets its own context window for thorough processing
- **Output**: Detailed analysis of assigned chunk with page references
- **Persistence**: Saves comprehensive analysis to `[chunk_name]_analysis.md` files

## For Claude Code Users

### Installation
1. Copy the `claude-code/` agents to your project's `.claude/agents/` directory
2. Ensure ruby-pdfkit gem is installed: `gem install ruby-pdfkit`

### Usage Examples

**Basic PDF Processing (any size):**
```
Use pdf-processor agent: "Please summarize this research paper: /path/to/document.pdf"
```

**Large PDF Processing (>100 pages):**
```  
Use pdf-processor agent: "Analyze this 300-page technical manual: /path/to/manual.pdf"
```

The system automatically handles the complexity - no need to choose specific agents.

### Features

- **Intelligent Routing**: Automatically selects optimal processing strategy
- **Content-Aware Splitting**: Respects document structure (chapters, sections)
- **Parallel Processing**: Each chunk processed in separate context windows
- **Persistent Analysis**: Detailed chunk analyses saved as markdown files
- **Efficient Follow-ups**: Subsequent questions use saved analyses instead of re-processing
- **Comprehensive Synthesis**: Combines chunk results into coherent output
- **Ruby-PDFKit Integration**: Leverages CLI tools for reliable PDF handling

### Output Structure

After processing a large PDF, you'll find:
```
splits/
├── document_ch01_intro.pdf           # Split PDF chunk
├── document_ch01_intro_analysis.md   # Detailed analysis
├── document_ch02_methods.pdf         # Split PDF chunk  
├── document_ch02_methods_analysis.md # Detailed analysis
└── document_processing_manifest.md   # Processing summary
```

### Requirements

- Claude Code environment
- Ruby-PDFKit gem (`gem install ruby-pdfkit`)
- PDF files accessible to the system

## Design Principles

1. **Never Read Large PDFs Directly**: Always use ruby-pdfkit CLI for file operations
2. **MapReduce Architecture**: Split large tasks, process in parallel, synthesize results
3. **Content-Aware Processing**: Respect document structure when splitting
4. **Automatic Orchestration**: Minimal user intervention required
5. **Extensible Design**: Easy to add new processing capabilities

## Future Extensions

This agent system is designed to be extended with:
- Additional splitting strategies
- New analysis capabilities  
- Integration with other agentic systems
- Custom processing workflows

## Contributing

When adding new agents:
1. Follow the established naming convention
2. Include clear documentation in agent headers
3. Maintain the MapReduce processing pattern
4. Test with various PDF types and sizes