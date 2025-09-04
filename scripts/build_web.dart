import 'dart:io';
import 'dart:convert';

void main(List<String> args) async {
  // Read the keys.json file
  final keysFile = File('keys.json');
  if (!keysFile.existsSync()) {
    print('Error: keys.json file not found');
    exit(1);
  }

  final keysContent = await keysFile.readAsString();
  final keys = json.decode(keysContent) as Map<String, dynamic>;
  
  final googleClientId = keys['GOOGLE_CLIENT_ID'] as String?;
  if (googleClientId == null) {
    print('Error: GOOGLE_CLIENT_ID not found in keys.json');
    exit(1);
  }

  // Read the index.html file
  final indexFile = File('web/index.html');
  if (!indexFile.existsSync()) {
    print('Error: web/index.html file not found');
    exit(1);
  }

  String indexContent = await indexFile.readAsString();
  
  // Replace the placeholder with the actual Client ID
  indexContent = indexContent.replaceAll('GOOGLE_CLIENT_ID_PLACEHOLDER', googleClientId);
  
  // Write the updated content back
  await indexFile.writeAsString(indexContent);
  
  print('✅ Successfully updated web/index.html with Google Client ID');
  print('🔒 Client ID is now securely managed via environment variables');
}
