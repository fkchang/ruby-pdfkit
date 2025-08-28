# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PDFKit::CLI do
  let(:sample_pdf) { File.expand_path('../fixtures/sample.pdf', __dir__) }
  let(:nonexistent_file) { '/path/to/nonexistent/file.pdf' }

  describe 'version command' do
    it 'displays version information' do
      expect { described_class.start(['version']) }.to output(
        "PDFKit #{PDFKit::VERSION}\n",
      ).to_stdout
    end

    it 'supports --version flag' do
      expect { described_class.start(['--version']) }.to output(
        "PDFKit #{PDFKit::VERSION}\n",
      ).to_stdout
    end

    it 'supports -v flag' do
      expect { described_class.start(['-v']) }.to output(
        "PDFKit #{PDFKit::VERSION}\n",
      ).to_stdout
    end
  end

  describe 'info command' do
    context 'with valid PDF file' do
      it 'displays PDF information' do
        expect { described_class.start(['info', sample_pdf]) }.to output(
          /PDF Information:/,
        ).to_stdout
      end

      it 'supports JSON output' do
        output = capture_stdout { described_class.start(['info', sample_pdf, '--json']) }
        expect { JSON.parse(output) }.not_to raise_error
      end
    end

    context 'with error conditions' do
      it 'exits with code 2 for missing file' do
        expect do
          described_class.start(['info', nonexistent_file])
        end.to raise_error(SystemExit) do |error|
          expect(error.status).to eq(2)
        end
      end

      it 'displays error message for missing file' do
        output = capture_stdout_and_stderr do
          described_class.start(['info', nonexistent_file])
        rescue SystemExit
          # Expected to exit
        end

        expect(output).to match(/Error: File not found/)
      end
    end
  end

  describe 'help command' do
    it 'displays help information' do
      expect { described_class.start(['help']) }.to output(
        /Commands:/,
      ).to_stdout
    end

    it 'shows info command help' do
      expect { described_class.start(%w[help info]) }.to output(
        /Display PDF metadata/,
      ).to_stdout
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

  def capture_stdout_and_stderr
    original_stdout = $stdout
    original_stderr = $stderr
    $stdout = $stderr = fake = StringIO.new
    yield
    fake.string
  ensure
    $stdout = original_stdout
    $stderr = original_stderr
  end
end
