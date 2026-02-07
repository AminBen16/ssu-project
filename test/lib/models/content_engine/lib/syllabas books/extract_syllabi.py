#!/usr/bin/env python3
"""
NCDC Syllabus PDF to Markdown Converter
Extracts text from PDF files and converts to structured markdown
"""

import os
import sys
from pathlib import Path
import PyPDF2
import pdfplumber
from datetime import datetime

class SyllabusExtractor:
    def __init__(self, source_dir, output_dir):
        self.source_dir = Path(source_dir)
        self.output_dir = Path(output_dir)
        self.output_dir.mkdir(exist_ok=True)
        
    def extract_pdf_text(self, pdf_path):
        """Extract text from PDF using pdfplumber for better formatting"""
        text_content = []
        
        try:
            with pdfplumber.open(pdf_path) as pdf:
                for page_num, page in enumerate(pdf.pages, 1):
                    text = page.extract_text()
                    if text:
                        text_content.append(f"--- PAGE {page_num} ---\n{text}\n")
        except Exception as e:
            print(f"Error with pdfplumber for {pdf_path}: {e}")
            # Fallback to PyPDF2
            try:
                with open(pdf_path, 'rb') as file:
                    pdf_reader = PyPDF2.PdfReader(file)
                    for page_num, page in enumerate(pdf_reader.pages, 1):
                        text = page.extract_text()
                        if text:
                            text_content.append(f"--- PAGE {page_num} ---\n{text}\n")
            except Exception as e2:
                print(f"Error with PyPDF2 fallback for {pdf_path}: {e2}")
                return None
        
        return "\n".join(text_content)
    
    def clean_text(self, text):
        """Clean and format extracted text"""
        if not text:
            return ""
        
        # Basic cleaning
        text = text.replace('\x0c', '')  # Remove form feeds
        text = text.replace('\n\n', '\n')  # Reduce excessive newlines
        
        return text.strip()
    
    def create_markdown_file(self, pdf_path, extracted_text):
        """Create markdown file from extracted text"""
        pdf_name = Path(pdf_path).stem
        markdown_file = self.output_dir / f"{pdf_name}.md"
        
        # Create markdown header
        header = f"""# {pdf_name.replace('_', ' ').title()}

**Source:** {pdf_path.name}  
**Extracted:** {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}  
**Extraction Method:** Automated PDF Text Extraction

---

## Extracted Text

"""
        
        # Clean and format content
        cleaned_text = self.clean_text(extracted_text)
        
        # Write to markdown file
        with open(markdown_file, 'w', encoding='utf-8') as f:
            f.write(header)
            f.write(cleaned_text)
        
        return markdown_file
    
    def process_all_pdfs(self):
        """Process all PDF files in the source directory"""
        pdf_files = list(self.source_dir.glob("*.pdf"))
        
        if not pdf_files:
            print("No PDF files found in the source directory.")
            return
        
        print(f"Found {len(pdf_files)} PDF files to process...")
        
        results = []
        
        for pdf_file in pdf_files:
            print(f"\nProcessing: {pdf_file.name}")
            
            # Extract text
            extracted_text = self.extract_pdf_text(pdf_file)
            
            if extracted_text:
                # Create markdown file
                markdown_file = self.create_markdown_file(pdf_file, extracted_text)
                results.append({
                    'pdf': pdf_file.name,
                    'markdown': markdown_file.name,
                    'status': 'Success',
                    'chars': len(extracted_text)
                })
                print(f"✓ Created: {markdown_file.name} ({len(extracted_text)} characters)")
            else:
                results.append({
                    'pdf': pdf_file.name,
                    'markdown': None,
                    'status': 'Failed',
                    'chars': 0
                })
                print(f"✗ Failed to extract text from {pdf_file.name}")
        
        # Create summary report
        self.create_summary_report(results)
        
        return results
    
    def create_summary_report(self, results):
        """Create a summary report of the extraction process"""
        report_file = self.output_dir / "extraction_report.md"
        
        successful = [r for r in results if r['status'] == 'Success']
        failed = [r for r in results if r['status'] == 'Failed']
        
        report = f"""# NCDC Syllabus Extraction Report

**Generated:** {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}  
**Total PDFs Processed:** {len(results)}  
**Successful Extractions:** {len(successful)}  
**Failed Extractions:** {len(failed)}  

---

## Successful Extractions

| PDF File | Markdown File | Characters |
|----------|---------------|------------|
"""
        
        for result in successful:
            report += f"| {result['pdf']} | {result['markdown']} | {result['chars']:,} |\n"
        
        if failed:
            report += "\n## Failed Extractions\n\n"
            for result in failed:
                report += f"- **{result['pdf']}** - Extraction failed\n"
        
        total_chars = sum(r['chars'] for r in successful)
        avg_chars = total_chars // len(successful) if successful else 0
        success_rate = len(successful) / len(results) * 100
        
        report += f"""

## Statistics

- **Total Characters Extracted:** {total_chars:,}
- **Average Characters per PDF:** {avg_chars:,}
- **Success Rate:** {success_rate:.1f}%

---

## Files Generated

All markdown files are located in: `{self.output_dir.absolute()}`

## Next Steps

1. Review the extracted markdown files for accuracy
2. Use the structured text for curriculum data extraction
3. Apply NCDC curriculum extraction protocol to each file

"""
        
        with open(report_file, 'w', encoding='utf-8') as f:
            f.write(report)
        
        print(f"\n📊 Extraction report created: {report_file}")

def main():
    """Main execution function"""
    # Define paths
    source_directory = r"C:\Users\user\SSU\syllabas books"
    output_directory = r"C:\Users\user\SSU\extracted_syllabi"
    
    print("🔧 NCDC Syllabus PDF to Markdown Converter")
    print("=" * 50)
    print(f"Source Directory: {source_directory}")
    print(f"Output Directory: {output_directory}")
    print("=" * 50)
    
    # Check if source directory exists
    if not os.path.exists(source_directory):
        print(f"❌ Error: Source directory does not exist: {source_directory}")
        sys.exit(1)
    
    # Create extractor and process
    extractor = SyllabusExtractor(source_directory, output_directory)
    results = extractor.process_all_pdfs()
    
    print("\n" + "=" * 50)
    print("🎉 Extraction Complete!")
    
    if results:
        successful = len([r for r in results if r['status'] == 'Success'])
        print(f"✅ Successfully processed: {successful}/{len(results)} files")
        print(f"📁 Output directory: {output_directory}")
    else:
        print("❌ No files were processed successfully")

if __name__ == "__main__":
    main()
