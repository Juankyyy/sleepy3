// Applies the curated notes to a published GitHub release.
//
// Usage:
//   dart run tool/apply_release_notes.dart v0.1.0
//
// The notes live in release-notes/<tag>.md (ignored by Git) and carry the release
// title on their first line:
//
//   <!-- title: v0.1.0 - The Quiet Night Update -->
//
// This script reads that title and runs:
//
//   gh release edit <tag> --title <title> --notes-file release-notes/<tag>.md
//
// Install and authenticate the GitHub CLI first: https://cli.github.com/

import 'dart:io';

Future<void> main(List<String> arguments) async {
  if (arguments.length != 1) {
    stderr.writeln(
      'Usage: dart run tool/apply_release_notes.dart <tag>\n'
      'Example: dart run tool/apply_release_notes.dart v0.1.0',
    );
    exitCode = 64;
    return;
  }

  final tag = arguments.single;
  if (!RegExp(r'^v\d+\.\d+\.\d+$').hasMatch(tag)) {
    stderr.writeln('Invalid tag "$tag". Expected vX.Y.Z.');
    exitCode = 64;
    return;
  }

  final notesFile = File('release-notes/$tag.md');
  if (!notesFile.existsSync()) {
    stderr.writeln('Notes file not found: ${notesFile.path}');
    exitCode = 66;
    return;
  }

  final lines = notesFile.readAsLinesSync();
  final firstLine = lines.isEmpty ? '' : lines.first.trim();
  final titleMatch = RegExp(r'^<!--\s*title:\s*(.+?)\s*-->$')
      .firstMatch(firstLine);
  if (titleMatch == null) {
    stderr.writeln(
      'The first line of ${notesFile.path} must look like:\n'
      '<!-- title: $tag - The <Theme> Update -->',
    );
    exitCode = 65;
    return;
  }

  final title = titleMatch.group(1)!;
  final result = await Process.run('gh', <String>[
    'release',
    'edit',
    tag,
    '--title',
    title,
    '--notes-file',
    notesFile.path,
  ]);

  stdout.write(result.stdout);
  stderr.write(result.stderr);

  if (result.exitCode != 0) {
    stderr.writeln('gh release edit failed with exit code ${result.exitCode}.');
    exitCode = result.exitCode;
    return;
  }

  stdout.writeln('Updated $tag: $title');
}
