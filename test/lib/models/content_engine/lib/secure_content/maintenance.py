#!/usr/bin/env python3
"""
NCDC Syllabus Project - Secure Content Maintenance Script
Provides tools for managing, validating, and maintaining secure content organization
"""

import os
import json
import hashlib
import shutil
import tarfile
from pathlib import Path
from datetime import datetime
from typing import Dict, List, Optional, Any

class SecureContentManager:
    def __init__(self, base_dir: str = "C:/Users/user/SSU/secure_content"):
        self.base_dir = Path(base_dir)
        self.directories = {
            'data': self.base_dir / 'data',
            'extractors': self.base_dir / 'extractors',
            'validators': self.base_dir / 'validators',
            'ui_framework': self.base_dir / 'ui_framework',
            'documentation': self.base_dir / 'documentation',
            'backup': self.base_dir / 'backup'
        }
        
        # Ensure directories exist
        for dir_path in self.directories.values():
            dir_path.mkdir(exist_ok=True)
    
    def verify_structure(self) -> Dict[str, Any]:
        """Verify the secure content structure"""
        print("🔍 Verifying secure content structure...")
        
        results = {
            'structure_valid': True,
            'missing_directories': [],
            'file_counts': {},
            'issues': []
        }
        
        # Check directories
        for name, path in self.directories.items():
            if not path.exists():
                results['missing_directories'].append(str(path))
                results['structure_valid'] = False
            else:
                # Count files in directory
                file_count = len([f for f in path.iterdir() if f.is_file()])
                results['file_counts'][name] = file_count
        
        # Check critical files
        critical_files = [
            'data/alevel_data.json',
            'data/olevel_data.json',
            'data/validation_report.json',
            'extractors/FINAL_NCDC_EXTRACTOR.py',
            'validators/syllabus_data_validator.py'
        ]
        
        for file_path in critical_files:
            full_path = self.base_dir / file_path
            if not full_path.exists():
                results['issues'].append(f"Missing critical file: {file_path}")
                results['structure_valid'] = False
        
        return results
    
    def calculate_file_hashes(self) -> Dict[str, str]:
        """Calculate MD5 hashes for all files"""
        print("🔐 Calculating file hashes...")
        
        hashes = {}
        
        for dir_path in self.directories.values():
            for file_path in dir_path.rglob('*'):
                if file_path.is_file():
                    try:
                        with open(file_path, 'rb') as f:
                            file_hash = hashlib.md5(f.read()).hexdigest()
                        hashes[str(file_path.relative_to(self.base_dir))] = file_hash
                    except Exception as e:
                        print(f"  ⚠️  Could not hash {file_path}: {e}")
        
        return hashes
    
    def verify_data_integrity(self) -> Dict[str, Any]:
        """Verify data integrity using validation tools"""
        print("📊 Verifying data integrity...")
        
        results = {
            'validation_passed': False,
            'validation_report': None,
            'issues': []
        }
        
        # Check if validation report exists
        validation_report_path = self.directories['data'] / 'validation_report.json'
        if validation_report_path.exists():
            try:
                with open(validation_report_path, 'r', encoding='utf-8') as f:
                    results['validation_report'] = json.load(f)
                
                # Check if validation passed
                if results['validation_report'].get('overall_status') == 'PASS':
                    results['validation_passed'] = True
                else:
                    results['issues'].append("Data validation did not pass")
            except Exception as e:
                results['issues'].append(f"Error reading validation report: {e}")
        else:
            results['issues'].append("No validation report found")
        
        return results
    
    def create_backup(self, backup_name: Optional[str] = None) -> str:
        """Create a timestamped backup of critical data"""
        if backup_name is None:
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            backup_name = f"backup_{timestamp}"
        
        backup_path = self.base_dir / f"{backup_name}.tar.gz"
        
        print(f"💾 Creating backup: {backup_path.name}")
        
        try:
            with tarfile.open(backup_path, 'w:gz') as tar:
                # Add data directory
                if self.directories['data'].exists():
                    tar.add(self.directories['data'], arcname='data')
                
                # Add documentation
                if self.directories['documentation'].exists():
                    tar.add(self.directories['documentation'], arcname='documentation')
                
                # Add README and SECURITY files
                readme_path = self.base_dir / 'README.md'
                if readme_path.exists():
                    tar.add(readme_path, arcname='README.md')
                
                security_path = self.base_dir / 'SECURITY.md'
                if security_path.exists():
                    tar.add(security_path, arcname='SECURITY.md')
            
            print(f"  ✅ Backup created: {backup_path}")
            return str(backup_path)
            
        except Exception as e:
            print(f"  ❌ Backup failed: {e}")
            return ""
    
    def restore_from_backup(self, backup_path: str) -> bool:
        """Restore data from backup file"""
        backup_file = Path(backup_path)
        
        if not backup_file.exists():
            print(f"❌ Backup file not found: {backup_path}")
            return False
        
        print(f"📦 Restoring from backup: {backup_file.name}")
        
        try:
            with tarfile.open(backup_file, 'r:gz') as tar:
                # Extract to temporary location first
                temp_dir = self.base_dir / 'temp_restore'
                temp_dir.mkdir(exist_ok=True)
                
                tar.extractall(temp_dir)
                
                # Verify extracted content
                temp_data = temp_dir / 'data'
                if temp_data.exists():
                    # Backup current data
                    self.create_backup("before_restore")
                    
                    # Move restored data
                    shutil.rmtree(self.directories['data'])
                    shutil.move(temp_data, self.directories['data'])
                    
                    print("  ✅ Data restored successfully")
                    return True
                else:
                    print("  ❌ No data found in backup")
                    return False
                    
        except Exception as e:
            print(f"  ❌ Restore failed: {e}")
            return False
        finally:
            # Clean up temporary directory
            temp_dir = self.base_dir / 'temp_restore'
            if temp_dir.exists():
                shutil.rmtree(temp_dir)
    
    def run_validation(self) -> Dict[str, Any]:
        """Run data validation and return results"""
        print("🔍 Running data validation...")
        
        validator_path = self.directories['validators'] / 'syllabus_data_validator.py'
        if not validator_path.exists():
            return {'error': 'Validator not found', 'path': str(validator_path)}
        
        try:
            # Import and run validator
            import sys
            sys.path.append(str(self.directories['validators']))
            
            from syllabus_data_validator import main as run_validator
            
            # Run validation
            report = run_validator()
            
            return {
                'success': True,
                'report': report,
                'timestamp': datetime.now().isoformat()
            }
            
        except Exception as run_error:
            return {
                'success': False,
                'error': str(run_error),
                'timestamp': datetime.now().isoformat()
            }
    
    def generate_status_report(self) -> Dict[str, Any]:
        """Generate comprehensive status report"""
        print("📋 Generating status report...")
        
        report = {
            'timestamp': datetime.now().isoformat(),
            'structure': self.verify_structure(),
            'integrity': self.verify_data_integrity(),
            'file_hashes': self.calculate_file_hashes(),
            'directory_info': {}
        }
        
        # Add directory information
        for name, path in self.directories.items():
            if path.exists():
                files = [f for f in path.rglob('*') if f.is_file()]
                dirs = [d for d in path.rglob('*') if d.is_dir()]
                
                report['directory_info'][name] = {
                    'exists': True,
                    'files_count': len(files),
                    'directories_count': len(dirs),
                    'size_mb': sum(f.stat().st_size for f in files) / (1024 * 1024)
                }
            else:
                report['directory_info'][name] = {
                    'exists': False,
                    'files_count': 0,
                    'directories_count': 0,
                    'size_mb': 0
                }
        
        return report
    
    def cleanup_temp_files(self) -> Dict[str, Any]:
        """Clean up temporary files and old backups"""
        print("🧹 Cleaning up temporary files...")
        
        cleaned = {
            'temp_files_removed': 0,
            'old_backups_removed': 0,
            'space_freed_mb': 0
        }
        
        # Clean temporary files
        temp_patterns = ['temp_*', '*.tmp', '*.temp']
        for pattern in temp_patterns:
            for temp_file in self.base_dir.glob(pattern):
                if temp_file.is_file():
                    size_mb = temp_file.stat().st_size / (1024 * 1024)
                    temp_file.unlink()
                    cleaned['temp_files_removed'] += 1
                    cleaned['space_freed_mb'] += size_mb
        
        # Clean old backups (keep last 5)
        backup_files = sorted(self.base_dir.glob('backup_*.tar.gz'), 
                           key=lambda x: x.stat().st_mtime, reverse=True)
        
        for backup_file in backup_files[5:]:  # Keep only 5 most recent
            size_mb = backup_file.stat().st_size / (1024 * 1024)
            backup_file.unlink()
            cleaned['old_backups_removed'] += 1
            cleaned['space_freed_mb'] += size_mb
        
        print(f"  ✅ Cleaned {cleaned['temp_files_removed']} temp files")
        print(f"  ✅ Removed {cleaned['old_backups_removed']} old backups")
        print(f"  ✅ Freed {cleaned['space_freed_mb']:.2f} MB")
        
        return cleaned
    
    def print_status(self):
        """Print current status summary"""
        print("📊 NCDC Syllabus - Secure Content Status")
        print("=" * 50)
        
        # Structure verification
        structure = self.verify_structure()
        if structure['structure_valid']:
            print("✅ Structure: Valid")
        else:
            print("❌ Structure: Issues found")
            for issue in structure['missing_directories']:
                print(f"   Missing: {issue}")
        
        # File counts
        print("\n📁 File Counts:")
        for dir_name, count in structure['file_counts'].items():
            print(f"  {dir_name}: {count} files")
        
        # Data integrity
        integrity = self.verify_data_integrity()
        if integrity['validation_passed']:
            print("\n✅ Data Integrity: Valid")
        else:
            print("\n❌ Data Integrity: Issues found")
            for issue in integrity['issues']:
                print(f"   {issue}")
        
        # Directory sizes
        report = self.generate_status_report()
        print("\n💾 Directory Sizes:")
        for dir_name, info in report['directory_info'].items():
            if info['exists']:
                print(f"  {dir_name}: {info['size_mb']:.2f} MB")
        
        print(f"\n🕒 Last Updated: {report['timestamp']}")

def main():
    """Main maintenance interface"""
    manager = SecureContentManager()
    
    print("🔧 NCDC Syllabus - Secure Content Maintenance")
    print("=" * 50)
    print("Choose an action:")
    print("1. Verify structure")
    print("2. Check data integrity")
    print("3. Run validation")
    print("4. Create backup")
    print("5. Generate status report")
    print("6. Clean up files")
    print("7. Show status")
    print("8. Full system check")
    
    try:
        choice = input("\nEnter choice (1-8): ").strip()
    except KeyboardInterrupt:
        print("\n👋 Maintenance cancelled")
        return
    
    if choice == "1":
        result = manager.verify_structure()
        print(f"\nStructure verification: {'✅ Valid' if result['structure_valid'] else '❌ Issues found'}")
        
    elif choice == "2":
        result = manager.verify_data_integrity()
        print(f"\nData integrity: {'✅ Valid' if result['validation_passed'] else '❌ Issues found'}")
        
    elif choice == "3":
        result = manager.run_validation()
        if result.get('success'):
            print(f"\n✅ Validation completed at {result['timestamp']}")
        else:
            print(f"\n❌ Validation failed: {result.get('error')}")
            
    elif choice == "4":
        backup_path = manager.create_backup()
        if backup_path:
            print(f"\n✅ Backup created: {backup_path}")
        
    elif choice == "5":
        report = manager.generate_status_report()
        print(f"\n📋 Status report generated at {report['timestamp']}")
        
    elif choice == "6":
        cleaned = manager.cleanup_temp_files()
        print(f"\n🧹 Cleanup completed")
        
    elif choice == "7":
        manager.print_status()
        
    elif choice == "8":
        print("\n🔍 Running full system check...")
        
        # Run all checks
        structure = manager.verify_structure()
        integrity = manager.verify_data_integrity()
        validation = manager.run_validation()
        
        print(f"\n📋 Full System Check Results:")
        print(f"  Structure: {'✅ Valid' if structure['structure_valid'] else '❌ Issues found'}")
        print(f"  Integrity: {'✅ Valid' if integrity['validation_passed'] else '❌ Issues found'}")
        print(f"  Validation: {'✅ Passed' if validation.get('success') else '❌ Failed'}")
        
        # Create backup if all checks pass
        if structure['structure_valid'] and integrity['validation_passed'] and validation.get('success'):
            print(f"\n💾 All checks passed - creating backup...")
            backup_path = manager.create_backup()
            if backup_path:
                print(f"✅ Backup created: {backup_path}")
        
    else:
        print("\n❌ Invalid choice")

if __name__ == "__main__":
    main()
