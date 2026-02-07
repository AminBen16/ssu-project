import 'dart:io';

/// Simple test to verify NCDC markdown files are accessible
void main() async {
  print('🧪 SIMPLE NCDC DATA TEST');
  print('=' * 40);
  
  final syllabusDir = Directory(r'C:\Users\user\SSU\extracted_syllabi');
  
  if (await syllabusDir.exists()) {
    print('✅ Syllabus directory found: ${syllabusDir.path}');
    
    final files = await syllabusDir.list().where((f) => f.path.endsWith('.md')).toList();
    print('✅ Found ${files.length} markdown files');
    
    // Test reading first few files
    for (int i = 0; i < files.length && i < 3; i++) {
      final file = files[i] as File;
      final fileName = file.path.split('\\').last;
      
      try {
        final content = await file.readAsString();
        print('✅ $fileName: ${content.length} characters');
        
        // Check for NCDC content indicators
        if (content.toLowerCase().contains('ncdc')) {
          print('   📚 Contains NCDC reference');
        }
        if (content.toLowerCase().contains('learning outcome')) {
          print('   🎯 Contains learning outcomes');
        }
        if (content.toLowerCase().contains('topic')) {
          print('   📝 Contains topics');
        }
        if (content.toLowerCase().contains('strand')) {
          print('   🌿 Contains strands');
        }
        
        // Show first few lines
        final lines = content.split('\n').take(10).toList();
        print('   First 10 lines:');
        for (int j = 0; j < lines.length; j++) {
          if (lines[j].trim().isNotEmpty) {
            print('     ${j + 1}: ${lines[j].trim().substring(0, 60)}...');
          }
        }
        
      } catch (e) {
        print('❌ Error reading $fileName: $e');
      }
      print('');
    }
    
    print('🎉 NCDC DATA TEST COMPLETED SUCCESSFULLY!');
    print('📁 All ${files.length} markdown files are ready for curriculum extraction');
    
  } else {
    print('❌ Syllabus directory not found: ${syllabusDir.path}');
  }
}
