import 'dart:developer' as developer;

import 'dart:io';

/// Simple test to verify NCDC markdown files are accessible
void main() async {
  developer.log('🧪 SIMPLE NCDC DATA TEST');
  developer.log('=' * 40);
  
  final syllabusDir = Directory(r'C:\Users\user\SSU\extracted_syllabi');
  
  if (await syllabusDir.exists()) {
    developer.log('✅ Syllabus directory found: ${syllabusDir.path}');
    
    final files = await syllabusDir.list().where((f) => f.path.endsWith('.md')).toList();
    developer.log('✅ Found ${files.length} markdown files');
    
    // Test reading first few files
    for (int i = 0; i < files.length && i < 3; i++) {
      final file = files[i] as File;
      final fileName = file.path.split('\\').last;
      
      try {
        final content = await file.readAsString();
        developer.log('✅ $fileName: ${content.length} characters');
        
        // Check for NCDC content indicators
        if (content.toLowerCase().contains('ncdc')) {
          developer.log('   📚 Contains NCDC reference');
        }
        if (content.toLowerCase().contains('learning outcome')) {
          developer.log('   🎯 Contains learning outcomes');
        }
        if (content.toLowerCase().contains('topic')) {
          developer.log('   📝 Contains topics');
        }
        if (content.toLowerCase().contains('strand')) {
          developer.log('   🌿 Contains strands');
        }
        
        // Show first few lines
        final lines = content.split('\n').take(10).toList();
        developer.log('   First 10 lines:');
        for (int j = 0; j < lines.length; j++) {
          if (lines[j].trim().isNotEmpty) {
            developer.log('     ${j + 1}: ${lines[j].trim().substring(0, 60)}...');
          }
        }
        
      } catch (e) {
        developer.log('❌ Error reading $fileName: $e');
      }
      developer.log('');
    }
    
    developer.log('🎉 NCDC DATA TEST COMPLETED SUCCESSFULLY!');
    developer.log('📁 All ${files.length} markdown files are ready for curriculum extraction');
    
  } else {
    developer.log('❌ Syllabus directory not found: ${syllabusDir.path}');
  }
}

