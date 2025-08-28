# frozen_string_literal: true

require 'spec_helper'
require 'tempfile'
require 'json'

RSpec.describe PDFKit::Commands::Info do
  let(:sample_pdf) { File.expand_path('../../fixtures/sample.pdf', __dir__) }
  let(:nonexistent_file) { '/path/to/nonexistent/file.pdf' }

  describe '#execute' do
    context 'with valid PDF file' do
      it 'displays PDF information in human-readable format' do
        command = described_class.new(sample_pdf)

        expect { command.execute }.to output(/PDF Information:/).to_stdout
      end

      it 'includes basic metadata fields' do
        command = described_class.new(sample_pdf)

        expect { command.execute }.to output(
          /File:.*sample\.pdf.*Pages:.*1.*Title:.*Test PDF.*Author:.*PDFKit Test Suite/m,
        ).to_stdout
      end

      it 'displays file size in human-readable format' do
        command = described_class.new(sample_pdf)

        expect { command.execute }.to output(/File Size:.*\d+(\.\d+)?\s+(B|KB|MB)/).to_stdout
      end
    end

    context 'with JSON output option' do
      it 'outputs valid JSON format' do
        command = described_class.new(sample_pdf, json: true)
        output = capture_stdout { command.execute }

        expect { JSON.parse(output) }.not_to raise_error
      end

      it 'includes all expected fields in JSON' do
        command = described_class.new(sample_pdf, json: true)
        output = capture_stdout { command.execute }
        json_data = JSON.parse(output)

        expect(json_data).to include(
          'file' => sample_pdf,
          'pages' => 1,
          'title' => 'Test PDF',
          'author' => 'PDFKit Test Suite',
        )
        expect(json_data['pdf_version']).to be_a(String)
        expect(json_data['file_size']).to be_a(Integer)
        expect(json_data['has_bookmarks']).to be(false)
      end
    end

    context 'with error conditions' do
      it 'raises FileNotFoundError for nonexistent file' do
        command = described_class.new(nonexistent_file)

        expect { command.execute }.to raise_error(
          PDFKit::Commands::Info::FileNotFoundError,
          "File not found: #{nonexistent_file}",
        )
      end

      it 'raises InvalidPDFError for invalid PDF' do
        invalid_file = Tempfile.new(['invalid', '.pdf'])
        invalid_file.write('This is not a PDF file')
        invalid_file.close

        command = described_class.new(invalid_file.path)

        expect { command.execute }.to raise_error(
          PDFKit::Commands::Info::InvalidPDFError,
        )

        invalid_file.unlink
      end
    end
  end

  describe '#format_file_size' do
    let(:command) { described_class.new(sample_pdf) }

    it 'formats bytes correctly' do
      expect(command.send(:format_file_size, 500)).to eq('500.0 B')
    end

    it 'formats kilobytes correctly' do
      expect(command.send(:format_file_size, 1536)).to eq('1.5 KB')
    end

    it 'formats megabytes correctly' do
      expect(command.send(:format_file_size, 1_572_864)).to eq('1.5 MB')
    end
  end

  private

  def capture_stdout
    original_stdout = $stdout
    $stdout = fake = StringIO.new
    yield
    fake.string
  ensure
    $stdout = original_stdout
  end
end
