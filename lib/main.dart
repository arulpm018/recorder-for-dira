import 'dart:async';
import 'dart:io';
import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart' as rec;
import 'package:share_plus/share_plus.dart';


void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const RecorderApp());
}

class RecorderApp extends StatelessWidget {
  const RecorderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Recorder for Dira',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF34495e)),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // CSV state
  String? _csvLocalPath;
  String? _csvFileName;
  List<String> _headers = [];
  List<Map<String, String>> _rows = [];
  String? _transcriptionKey; // 'transcriptions' or 'transcription'

  // Recording/session state
  String? _dateFolderName; // e.g., 11_08_2025_transcriptions
  String? _audioFolderPath; // appDocDir/audio_recordings/<date>_transcriptions
  int _currentIndex = 0;
  final AudioPlayer _audioPlayer = AudioPlayer();
  final rec.AudioRecorder _recorder = rec.AudioRecorder();
  bool _isRecording = false;
  String? _tempRecordingPath; // path to last stopped recording (non-web)

  @override
  void dispose() {
    _audioPlayer.dispose();
    _recorder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/logo.png',
              width: 32,
              height: 32,
            ),
            SizedBox(width: 8),
            Text('Recorder for Dira'),
          ],
        ),
        backgroundColor: const Color(0xFF34495e),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header dengan logo mic
              Center(
                child: Column(
                  children: [
                    Image.asset(
                      'assets/logo.png',
                      width: 64,
                      height: 64,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Recorder for Dira',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF34495e),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
              const Text('Select CSV', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _pickAndLoadCsv,
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Load CSV'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _csvFileName != null ? 'Loaded: ${_csvFileName!}' : 'No CSV loaded',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _rows.isEmpty || _transcriptionKey == null
                    ? const Center(
                        child: Text(
                          'Load a CSV with a "transcription" or "transcriptions" column to begin.',
                          textAlign: TextAlign.center,
                        ),
                      )
                    : _buildRecordingUI(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecordingUI() {
    final int total = _rows.length;
    final int completed = _countCompletedRecordings();
    final double progress = total == 0 ? 0 : (completed / total);
    final int humanIndex = _currentIndex + 1;
    final String currentText = _rows[_currentIndex][_transcriptionKey!] ?? '';

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LinearProgressIndicator(value: progress),
          const SizedBox(height: 8),
          Text('Progress: $completed/$total'),
          const SizedBox(height: 16),
          const SizedBox(height: 16),
          Text('Item $humanIndex of $total', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('📝 Edit transcription if needed:'),
          const SizedBox(height: 8),
          TextFormField(
            key: ValueKey('editor_${_csvFileName}_$_currentIndex'),
            initialValue: currentText,
            minLines: 3,
            maxLines: null,
            onChanged: (value) {
              _rows[_currentIndex][_transcriptionKey!] = value;
            },
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Transcription text',
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: _saveTextOnly,
                icon: const Icon(Icons.save),
                label: const Text('Save Text'),
              ),
              const SizedBox(width: 12),
              if (!kIsWeb && _csvLocalPath != null)
                ElevatedButton.icon(
                  onPressed: _shareCsvFile,
                  icon: const Icon(Icons.ios_share),
                  label: const Text('Share CSV'),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('📝 Read this text:\n\n${_rows[_currentIndex][_transcriptionKey!] ?? ''}'),
          ),
          const SizedBox(height: 16),
          const Text('🎙️ Click to start/stop recording:'),
          const SizedBox(height: 8),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: _toggleRecording,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isRecording ? const Color(0xFFe74c3c) : const Color(0xFF34495e),
                  foregroundColor: Colors.white,
                ),
                icon: Icon(_isRecording ? Icons.stop : Icons.mic),
                label: Text(_isRecording ? 'Stop' : 'Record'),
              ),
              const SizedBox(width: 12),
              if (!kIsWeb && _audioFolderPath != null)
                ElevatedButton.icon(
                  onPressed: _playLastRecording,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Preview'),
                ),
              const SizedBox(width: 12),
              if (!kIsWeb && _audioFolderPath != null)
                ElevatedButton.icon(
                  onPressed: _openRecordingsViewer,
                  icon: const Icon(Icons.list),
                  label: const Text('View Files'),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (_currentIndex > 0)
                OutlinedButton(
                  onPressed: _goPrevious,
                  child: const Text('Previous'),
                ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: _skip,
                child: const Text('Next'),
              ),
              const SizedBox(width: 8),

              const SizedBox(width: 12),
              if (!kIsWeb && _audioFolderPath != null)
                OutlinedButton.icon(
                  onPressed: _shareAudioFolder,
                  icon: const Icon(Icons.ios_share),
                  label: const Text('Share'),
                ),
            ],
          ),
          const SizedBox(height: 24),
          if (_currentIndex >= _rows.length)
            Column(
              children: const [
                Text('🎉 All recordings completed!'),
              ],
            ),
        ],
      ),
    );
  }

  Future<void> _pickAndLoadCsv() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowMultiple: false,
        allowedExtensions: ['csv'],
        withData: kIsWeb, // ensure bytes available on web
      );
      if (result == null) return;

      final platformFile = result.files.single;
      final fileName = platformFile.name;

      // Extract date from filename
      final date = _extractDateFromFilename(fileName);
      if (date == null) {
        if (!mounted) return;
        _showSnack('Invalid filename format! Please use: DD_MM_YYYY_name_transcriptions.csv');
        return;
      }

      String content;
      String? localCsvPath;
      String? audioFolderPath;

      if (kIsWeb) {
        // On web, path is unavailable; use in-memory bytes
        final bytes = platformFile.bytes;
        if (bytes == null) {
          _showSnack('Failed to read file bytes on web');
          return;
        }
        content = utf8.decode(bytes);
        localCsvPath = null; // no filesystem path on web
        audioFolderPath = null; // no filesystem for audio on web
      } else {
        // Prepare app directories (IO platforms)
        final pickedPath = platformFile.path!;
        final docs = await getApplicationDocumentsDirectory();
        final csvsDir = Directory(p.join(docs.path, 'csvs'));
        await csvsDir.create(recursive: true);

        // Copy CSV to app storage for editing
        localCsvPath = p.join(csvsDir.path, fileName);
        await File(pickedPath).copy(localCsvPath);

        // Create audio folder
        final audioFolder = Directory(p.join(docs.path, 'audio_recordings', '${date}_transcriptions'));
        await audioFolder.create(recursive: true);
        audioFolderPath = audioFolder.path;

        // Read content
        content = await File(localCsvPath).readAsString();
      }

      // Parse CSV
      final rows = const CsvToListConverter(eol: '\n').convert(content);
      if (rows.isEmpty) {
        _showSnack('CSV is empty');
        return;
      }

      final headers = rows.first.map((e) => e.toString()).toList();
      final List<Map<String, String>> mapped = [];
      for (int i = 1; i < rows.length; i++) {
        final row = rows[i];
        final map = <String, String>{};
        for (int j = 0; j < headers.length; j++) {
          final key = headers[j];
          final value = j < row.length ? row[j]?.toString() ?? '' : '';
          map[key] = value;
        }
        mapped.add(map);
      }

      // Find transcription column
      String? transcriptionKey;
      if (headers.contains('transcriptions')) {
        transcriptionKey = 'transcriptions';
      } else if (headers.contains('transcription')) {
        transcriptionKey = 'transcription';
      }
      if (transcriptionKey == null) {
        _showSnack('CSV must have a "transcription" or "transcriptions" column');
        return;
      }

      // Compute next number (web: 1, IO: scan folder)
      final nextNumber = kIsWeb
          ? 1
          : await _getNextAudioNumber(audioFolderPath!);

      setState(() {
        _csvLocalPath = localCsvPath;
        _csvFileName = fileName;
        _headers = headers;
        _rows = mapped;
        _transcriptionKey = transcriptionKey;
        _dateFolderName = '${date}_transcriptions';
        _audioFolderPath = audioFolderPath;
        // Always start from 0 for new CSV, regardless of existing audio files
        _currentIndex = 0;
        _isRecording = false;
        _tempRecordingPath = null;
      });

      _showSnack('Loaded ${_rows.length} transcriptions${kIsWeb ? ' (web preview)' : ''}');
      if (!kIsWeb && nextNumber > 1) {
        _showSnack('Found existing recordings. Resuming from audio #$nextNumber');
      }
    } catch (e) {
      _showSnack('Error loading CSV: $e');
    }
  }

  Future<int> _getNextAudioNumber(String audioFolderPath) async {
    if (kIsWeb) return 1;
    final dir = Directory(audioFolderPath);
    if (!await dir.exists()) return 1;
    final files = dir
        .listSync()
        .whereType<File>()
        .where((f) => p.extension(f.path).toLowerCase() == '.wav')
        .toList();
    if (files.isEmpty) return 1;
    final numbers = <int>[];
    for (final f in files) {
      final base = p.basenameWithoutExtension(f.path);
      final n = int.tryParse(base);
      if (n != null) numbers.add(n);
    }
    if (numbers.isEmpty) return 1;
    final present = numbers.toSet();
    int candidate = 1;
    while (true) {
      if (!present.contains(candidate)) return candidate;
      candidate += 1;
    }
  }

  Future<void> _saveTextOnly() async {
    if (_transcriptionKey == null) return;
    final ok = await _saveCsvChanges();
    if (ok && mounted) {
      _showSnack(kIsWeb ? 'Text updated (web session only)' : 'Text saved to CSV');
      setState(() {});
    }
  }

  Future<void> _toggleRecording() async {
    try {
      if (kIsWeb) {
        _showSnack('Recording to files is not enabled on web in this app. Use mobile/desktop.');
        return;
      }

      if (_audioFolderPath == null) {
        _showSnack('Load a CSV first.');
        return;
      }

      if (_isRecording) {
        final stoppedPath = await _recorder.stop();
        if (stoppedPath == null) {
          setState(() {
            _isRecording = false;
          });
          _showSnack('No recording captured');
          return;
        }
        // Auto-save mapped to current transcription index (overwrite if exists)
        final destPath = p.join(_audioFolderPath!, '${_currentIndex + 1}.wav');
        final file = File(stoppedPath);
        if (await file.exists()) {
          final destFile = File(destPath);
          if (await destFile.exists()) {
            await destFile.delete();
          }
          await file.rename(destPath);
          // Give Android a moment to index/flush the new content to avoid stale cache
          await Future.delayed(const Duration(milliseconds: 120));
          await _writeTimestampForRow(_currentIndex);
          setState(() {
            _isRecording = false;
            _tempRecordingPath = destPath;
          });
        } else {
          setState(() {
            _isRecording = false;
            _tempRecordingPath = null;
          });
          _showSnack('Temporary recording not found');
        }
      } else {
        final hasPerm = await _recorder.hasPermission();
        if (!hasPerm) {
          _showSnack('Microphone permission denied');
          return;
        }
        // Record to a temporary path inside the audio folder
        final tempPath = p.join(_audioFolderPath!, 'temp_current.wav');
        await _recorder.start(
          rec.RecordConfig(encoder: rec.AudioEncoder.wav),
          path: tempPath,
        );
        setState(() {
          _isRecording = true;
          _tempRecordingPath = null;
        });
      }
    } catch (e) {
      _showSnack('Recording error: $e');
    }
  }

  Future<void> _playLastRecording() async {
    try {
      if (_audioFolderPath == null) return;
      final path = p.join(_audioFolderPath!, '${_currentIndex + 1}.wav');
      final file = File(path);
      if (!await file.exists()) {
        _showSnack('Preview file not found for this item.');
        return;
      }
      await _playFile(path);
    } catch (e) {
      _showSnack('Playback error: $e');
    }
  }

  Future<void> _playFile(String path) async {
    try {
      final file = File(path);
      if (!await file.exists()) {
        _showSnack('File not found');
        return;
      }
      await _audioPlayer.stop();
      await _audioPlayer.release();
      final Uint8List bytes = await file.readAsBytes();
      await _audioPlayer.setSource(BytesSource(bytes));
      await _audioPlayer.setVolume(1.0);
      await _audioPlayer.setReleaseMode(ReleaseMode.stop);
      await _audioPlayer.resume();
    } catch (e) {
      _showSnack('Playback error: $e');
    }
  }

  Future<void> _openRecordingsViewer() async {
    try {
      if (_audioFolderPath == null) return;
      final dir = Directory(_audioFolderPath!);
      if (!await dir.exists()) {
        _showSnack('Folder not found');
        return;
      }
      final files = dir
          .listSync()
          .whereType<File>()
          .where((f) => p.extension(f.path).toLowerCase() == '.wav')
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));
      if (!mounted) return;
      await showModalBottomSheet(
        context: context,
        builder: (ctx) {
          return SafeArea(
            child: files.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('No recordings yet'),
                  )
                : ListView.builder(
                    itemCount: files.length,
                    itemBuilder: (context, index) {
                      final f = files[index];
                      final name = p.basename(f.path);
                      return ListTile(
                        title: Text(name),
                        subtitle: Text(f.path, maxLines: 1, overflow: TextOverflow.ellipsis),
                        leading: const Icon(Icons.audiotrack),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.play_arrow),
                              onPressed: () => _playFile(f.path),
                            ),
                            IconButton(
                              icon: const Icon(Icons.ios_share),
                              onPressed: () => Share.shareXFiles([XFile(f.path)], text: name),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          );
        },
      );
    } catch (e) {
      _showSnack('Error opening recordings: $e');
    }
  }

  Future<void> _shareAudioFolder() async {
    try {
      if (_audioFolderPath == null) return;
      final dir = Directory(_audioFolderPath!);
      if (!await dir.exists()) {
        _showSnack('Folder not found');
        return;
      }
      final files = dir
          .listSync()
          .whereType<File>()
          .where((f) => p.extension(f.path).toLowerCase() == '.wav')
          .map((f) => XFile(f.path))
          .toList();
      if (files.isEmpty) {
        _showSnack('No audio files to share');
        return;
      }
      await Share.shareXFiles(files, text: 'Audio recordings');
    } catch (e) {
      _showSnack('Share error: $e');
    }
  }

  Future<void> _shareCsvFile() async {
    try {
      if (_csvLocalPath == null) {
        _showSnack('No CSV file loaded to share.');
        return;
      }
      final file = File(_csvLocalPath!);
      if (!await file.exists()) {
        _showSnack('CSV file not found.');
        return;
      }
      await Share.shareXFiles([XFile(file.path)], text: 'Shared CSV file');
    } catch (e) {
      _showSnack('Share error: $e');
    }
  }

  Future<void> _saveRecordingAndContinue() async {
    if (kIsWeb) {
      _showSnack('Saving recordings is disabled on web in this app.');
      return;
    }

    try {
      if (_audioFolderPath == null) return;

      if (_tempRecordingPath == null) {
        _showSnack('No recording to save.');
        return;
      }

      // Save mapped to current transcription index (overwrite if exists)
      final destPath = p.join(_audioFolderPath!, '${_currentIndex + 1}.wav');

      // Move/rename file (overwrite existing)
      final file = File(_tempRecordingPath!);
      if (await file.exists()) {
        final destFile = File(destPath);
        if (await destFile.exists()) {
          await destFile.delete();
        }
        await file.rename(destPath);
      } else {
        _showSnack('Temporary recording not found');
        return;
      }

      // Update CSV timestamp for current row
      await _writeTimestampForRow(_currentIndex);

      // Advance index
      if (_currentIndex < _rows.length - 1) {
        setState(() {
          _currentIndex += 1;
          _tempRecordingPath = null;
        });
      } else {
        _showSnack('All recordings completed!');
      }
    } catch (e) {
      _showSnack('Save error: $e');
    }
  }

  Future<void> _goPrevious() async {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex -= 1;
      });
    }
  }

  Future<void> _skip() async {
    if (_currentIndex < _rows.length - 1) {
      setState(() {
        _currentIndex += 1;
      });
    }
  }

  Future<void> _writeTimestampForRow(int rowIndex) async {
    // Ensure timestamp column exists
    if (!_headers.contains('timestamp')) {
      _headers.add('timestamp');
      for (final row in _rows) {
        row['timestamp'] = '';
      }
    }

    final now = DateTime.now().toUtc().add(const Duration(hours: 7));
    final formatted = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);
    _rows[rowIndex]['timestamp'] = formatted;

    await _saveCsvChanges();
  }

  Future<bool> _saveCsvChanges() async {
    try {
      // Build CSV content from in-memory state
      final list = <List<String>>[];
      list.add(_headers);
      for (final row in _rows) {
        final List<String> values = [];
        for (final h in _headers) {
          values.add(row[h] ?? '');
        }
        list.add(values);
      }
      final csvContent = const ListToCsvConverter().convert(list);

      if (kIsWeb) {
        // On web, no filesystem write. In a future iteration, trigger browser download.
        // For now, we keep it in memory and inform the user.
        return true;
      }

      if (_csvLocalPath == null) return false;
      await File(_csvLocalPath!).writeAsString(csvContent);
      return true;
    } catch (_) {
      return false;
    }
  }

  int _countCompletedRecordings() {
    if (kIsWeb) return 0;
    if (_audioFolderPath == null) return 0;
    final dir = Directory(_audioFolderPath!);
    if (!dir.existsSync()) return 0;
    final files = dir
        .listSync()
        .whereType<File>()
        .where((f) => p.extension(f.path).toLowerCase() == '.wav')
        .toList();
    return files.length;
  }

  String? _extractDateFromFilename(String filename) {
    final reg = RegExp(r'^(\d{2})_(\d{2})_(\d{4})_');
    final m = reg.firstMatch(filename);
    if (m == null) return null;
    final day = m.group(1);
    final month = m.group(2);
    final year = m.group(3);
    return '${day}_${month}_${year}';
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
} 