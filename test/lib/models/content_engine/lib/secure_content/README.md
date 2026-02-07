# NCDC Syllabus Project - Secure Content Organization

## Overview
This directory contains all dependent content organized in a secure, structured manner for the NCDC syllabus project.

## Directory Structure

### 📁 `data/`
**Purpose**: Contains processed syllabus data and database files
- `alevel_data.json` - Final A-Level syllabus data (296 entries)
- `olevel_data.json` - Final O-Level syllabus data (356 entries)
- `.processing_cache.json` - Incremental processing cache
- `validation_report.json` - Data quality validation results
- `cleaned_alevel_syllabi/` - Cleaned A-Level syllabus markdown files (24 files)
- `cleaned_olevel_syllabi/` - Cleaned O-Level syllabus markdown files (20 files)

### 📁 `extractors/`
**Purpose**: Contains syllabus extraction and processing tools
- `FINAL_NCDC_EXTRACTOR.py` - Main extraction tool with incremental processing
- Features: Incremental updates, comprehensive data collection, cleanup management

### 📁 `validators/`
**Purpose**: Contains data validation and quality assurance tools
- `syllabus_data_validator.py` - Comprehensive data validation framework
- Features: Structure validation, quality checks, reporting

### 📁 `ui_framework/`
**Purpose**: Contains UI components and web demonstration
- `syllabus_ui_framework.py` - Python UI framework with database integration
- `syllabus_web_demo.py` - Flask web demonstration interface
- Features: Navigation tree, search engine, content generation

### 📁 `documentation/`
**Purpose**: Contains all project documentation and reports
- `README.dev.md` - Development documentation
- `TODO.md` - Project tasks and roadmap
- `OFFLINE_FIRST_IMPLEMENTATION.md` - Architecture documentation
- `FINAL_EXTRACTION_SUMMARY.md` - Extraction process summary
- `ACCURACY_ANALYSIS_REPORT.md` - Data accuracy analysis
- `OUTCOME_TYPE_FIX_REPORT.md` - Classification improvements report

### 📁 `backup/`
**Purpose**: Contains original source files and backup copies
- `extracted_alevel_syllabi/` - Original A-Level source files (25 files)
- `extracted_syllabi/` - Original O-Level source files (24 files)
- **Purpose**: Source reference and recovery

## Security Measures

### 📋 Access Control
- **Read-Only Access**: Most files should be treated as read-only reference
- **Source Files**: Original files in `backup/` should not be modified
- **Processed Data**: Only modify files in `data/` through proper tools

### 🔄 Version Control
- **Immutable Source**: Original syllabus files in `backup/` are immutable
- **Generated Data**: Files in `data/` are generated through extraction tools
- **Tool Updates**: Update extractors in `extractors/` when needed

### 📊 Data Integrity
- **Validation**: Always run validators after data updates
- **Backups**: Maintain backup copies before major changes
- **Verification**: Use validation reports to ensure data quality

## Usage Guidelines

### 🚀 Running Extraction
```bash
cd secure_content/extractors
python FINAL_NCDC_EXTRACTOR.py
```

### 🔍 Validating Data
```bash
cd secure_content/validators
python syllabus_data_validator.py
```

### 🌐 Running Web Demo
```bash
cd secure_content/ui_framework
python syllabus_web_demo.py
```

## File Dependencies

### Core Dependencies
1. **Data Files**: `data/` ← `extractors/` (generation)
2. **Validation**: `validators/` → `data/` (verification)
3. **UI Framework**: `ui_framework/` → `data/` (consumption)
4. **Documentation**: `documentation/` → All components (reference)

### Data Flow
```
backup/ (source) → extractors/ → data/ (processed) → validators/ → ui_framework/
```

## Maintenance

### 📅 Regular Tasks
- **Monthly**: Run data validation to ensure integrity
- **Quarterly**: Review documentation for updates
- **As Needed**: Update extractors for new syllabus versions

### 🔄 Update Process
1. Update source files in `backup/` if new syllabus versions available
2. Run extraction tools to regenerate processed data
3. Run validation to ensure data quality
4. Update documentation as needed

## Contact Information

### 📧 Project Support
- **Data Issues**: Check validation reports first
- **Tool Problems**: Review extractor logs and error messages
- **Documentation**: Check README files in each directory

### 📚 Reference Materials
- **Architecture**: `OFFLINE_FIRST_IMPLEMENTATION.md`
- **Extraction**: `FINAL_EXTRACTION_SUMMARY.md`
- **Validation**: Validation reports in `data/`

---

**Last Updated**: 2026-02-04  
**Version**: 1.0  
**Status**: Secure and Organized  

This structure ensures all dependent content is properly organized, secured, and maintainable for the NCDC syllabus project.
