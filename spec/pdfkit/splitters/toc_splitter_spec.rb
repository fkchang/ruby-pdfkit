# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PDFKit::Splitters::TocSplitter do
  let(:document) { double('Document', file_path: '/path/to/test.pdf', pages: double('Pages', count: 50), pdf_doc: double('PDF')) }
  let(:analysis) { double('Analysis') }
  let(:options) { { output_dir: './test_splits' } }
  let(:splitter) { described_class.new(document, analysis, options) }

  describe '#max_pages functionality' do
    context 'when max_pages is provided in options' do
      let(:max_pages) { 25 }
      let(:splitter_with_max_pages) { described_class.new(document, analysis, options.merge(max_pages: max_pages)) }

      it 'returns the specified max_pages value' do
        expect(splitter_with_max_pages.max_pages).to eq(25)
      end
    end

    context 'when max_pages is not provided in options' do
      it 'returns the default max_pages value' do
        expect(splitter.max_pages).to eq(described_class::DEFAULT_MAX_PAGES)
      end
    end
  end

  describe 'segment size checking' do
    let(:max_pages) { 10 }
    let(:splitter_with_max_pages) { described_class.new(document, analysis, options.merge(max_pages: max_pages)) }

    context 'when a chapter exceeds max pages' do
      let(:toc_entry) { double('TocEntry', level: 1, page: 1, title: 'Large Chapter') }
      
      before do
        allow(analysis).to receive(:metadata).and_return({ pages: 50 })
      end

      it 'should be able to calculate if a segment exceeds max pages' do
        start_page = 1
        end_page = 25 # 25 pages > 10 max_pages
        
        expect(splitter_with_max_pages).to respond_to(:segment_exceeds_max_pages?)
        expect(splitter_with_max_pages.segment_exceeds_max_pages?(start_page, end_page)).to be true
      end

      it 'should split large segments into smaller ones' do
        # This test will fail initially because the split logic doesn't check max_pages
        expect(splitter_with_max_pages).to respond_to(:split_large_section)
        
        # A 25-page section should be split into 3 segments: 10 + 10 + 5 pages
        toc_entry = double('TocEntry', level: 1, page: 1, title: 'Large Chapter')
        result = double('SplitResult')
        file_namer = double('FileNamer')
        
        allow(result).to receive(:add_split_file)
        allow(file_namer).to receive(:chapter_name).and_return('test.pdf')
        allow(file_namer).to receive(:full_path).and_return('/test.pdf')
        allow(splitter_with_max_pages).to receive(:create_pdf_from_pages)
        
        # Should create 3 split files for a 25-page section with max_pages=10
        expect(result).to receive(:add_split_file).exactly(3).times
        
        splitter_with_max_pages.split_large_section(toc_entry, 1, 25, 1, file_namer, result)
      end
    end
  end

  describe '#split integration with max pages' do
    let(:max_pages) { 10 }
    let(:splitter_with_max_pages) { described_class.new(document, analysis, options.merge(max_pages: max_pages)) }
    let(:toc_entries) do
      [
        double('TocEntry', level: 1, page: 1, title: 'Small Chapter'),    # 5 pages
        double('TocEntry', level: 1, page: 6, title: 'Large Chapter'),    # 20 pages -> should be split
        double('TocEntry', level: 1, page: 26, title: 'Normal Chapter')   # 9 pages
      ]
    end

    before do
      allow(analysis).to receive(:has_toc?).and_return(true)
      allow(analysis).to receive(:toc_entries).and_return(toc_entries)
      allow(analysis).to receive(:metadata).and_return({ pages: 35 })
      allow(splitter_with_max_pages).to receive(:create_result) do
        result = double('SplitResult')
        allow(result).to receive(:add_split_file)
        allow(result).to receive(:set_metadata)
        allow(result).to receive(:add_error)
        result
      end
      allow(splitter_with_max_pages).to receive(:report_progress)
      allow(PDFKit::Utils::FileNamer).to receive(:new) do
        file_namer = double('FileNamer')
        allow(file_namer).to receive(:chapter_name).and_return('test.pdf')
        allow(file_namer).to receive(:full_path).and_return('/test.pdf')
        file_namer
      end
      allow(splitter_with_max_pages).to receive(:create_pdf_from_pages)
    end

    it 'splits large chapters while keeping small ones intact' do
      result = splitter_with_max_pages.split
      
      # We expect add_split_file to be called:
      # - 1 time for Small Chapter (5 pages)
      # - 2 times for Large Chapter (20 pages split into 10+10)
      # - 1 time for Normal Chapter (9 pages)
      # Total: 4 calls
      expect(result).to have_received(:add_split_file).exactly(4).times
    end
  end
end