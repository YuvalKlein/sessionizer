#!/usr/bin/env dart

import 'dart:io';

/// Test runner script for comprehensive testing
/// Usage: dart test_runner.dart [--watch] [--coverage]
void main(List<String> args) async {
  print('🧪 ARENNA Test Runner');
  print('=' * 50);

  final watch = args.contains('--watch');
  final coverage = args.contains('--coverage');

  if (watch) {
    print('👀 Running in watch mode...');
    await runTestsInWatchMode();
  } else {
    await runAllTests(coverage: coverage);
  }
}

Future<void> runAllTests({bool coverage = false}) async {
  print('🚀 Running all tests...\n');

  // Run unit tests
  print('📋 Unit Tests:');
  await runTestCategory('Unit Tests', [
    'test/features/session_type/domain/entities/',
    'test/core/services/',
  ]);

  // Run widget tests (when we create them)
  print('\n🎨 Widget Tests:');
  await runTestCategory('Widget Tests', [
    'test/features/*/presentation/widgets/',
  ]);

  // Run integration tests (when we create them)
  print('\n🔗 Integration Tests:');
  await runTestCategory('Integration Tests', [
    'test/integration/',
  ]);

  print('\n✅ All tests completed!');
}

Future<void> runTestCategory(String category, List<String> paths) async {
  for (final path in paths) {
    final dir = Directory(path);
    if (await dir.exists()) {
      final result = await Process.run(
        'flutter', 
        ['test', path],
        workingDirectory: Directory.current.path,
      );
      
      if (result.exitCode == 0) {
        print('  ✅ $path');
      } else {
        print('  ❌ $path');
        print('     ${result.stderr}');
      }
    } else {
      print('  ⏭️ $path (not found)');
    }
  }
}

Future<void> runTestsInWatchMode() async {
  print('Watching for file changes...');
  print('Press Ctrl+C to exit\n');
  
  // Simple watch mode - run tests every 5 seconds
  while (true) {
    await runAllTests();
    await Future.delayed(Duration(seconds: 5));
    print('\n🔄 Watching for changes...');
  }
}