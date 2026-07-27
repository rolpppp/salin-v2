import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class BackupService {
  final Logger _logger = Logger();

  Future<File> _getDatabaseFile() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    return File(p.join(dbFolder.path, 'salin.db'));
  }

  /// Exports the local database file by sharing it via the platform's native share sheet.
  Future<bool> exportBackup() async {
    try {
      final dbFile = await _getDatabaseFile();
      if (!await dbFile.exists()) {
        _logger.e('Database file does not exist at ${dbFile.path}');
        return false;
      }

      // Create a temporary copy to share with a descriptive name containing timestamp
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.').first;
      final backupFileName = 'salin_backup_$timestamp.db';
      final tempBackupFile = File(p.join(tempDir.path, backupFileName));
      
      await dbFile.copy(tempBackupFile.path);

      final result = await SharePlus.instance.share(
        ShareParams(
          files: [XFile(tempBackupFile.path)],
          text: 'Salin Database Backup ($timestamp)',
          subject: 'Salin Backup',
        ),
      );

      // Clean up the temporary file after sharing (delayed to allow system reading)
      Future.delayed(const Duration(seconds: 5), () async {
        try {
          if (await tempBackupFile.exists()) {
            await tempBackupFile.delete();
          }
        } catch (_) {}
      });

      return result.status == ShareResultStatus.success;
    } catch (e) {
      _logger.e('Failed to export backup: $e');
      return false;
    }
  }

  /// Lets the user pick a backup SQLite file and overwrites the local database.
  /// Note: The active database connection should be closed before calling this.
  Future<bool> restoreBackup() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
      );

      if (result == null || result.files.single.path == null) {
        _logger.i('User cancelled file picking.');
        return false;
      }

      final selectedPath = result.files.single.path!;
      final selectedFile = File(selectedPath);

      if (!await selectedFile.exists()) {
        _logger.e('Selected backup file does not exist.');
        return false;
      }

      // Perform backup overwrite
      final dbFile = await _getDatabaseFile();
      
      // Keep a backup of the current DB just in case overwrite fails
      final backupOfCurrent = File('${dbFile.path}.old');
      if (await dbFile.exists()) {
        await dbFile.copy(backupOfCurrent.path);
      }

      try {
        await selectedFile.copy(dbFile.path);
        // Clean up temporary old backup if restoration succeeded
        if (await backupOfCurrent.exists()) {
          await backupOfCurrent.delete();
        }
        return true;
      } catch (copyError) {
        _logger.e('Error copying backup: $copyError');
        // Restore current DB if copy failed
        if (await backupOfCurrent.exists()) {
          await backupOfCurrent.copy(dbFile.path);
          await backupOfCurrent.delete();
        }
        return false;
      }
    } catch (e) {
      _logger.e('Failed to restore backup: $e');
      return false;
    }
  }
}

final backupServiceProvider = Provider<BackupService>((ref) {
  return BackupService();
});
