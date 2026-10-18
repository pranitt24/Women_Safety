import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/hotspot_engine.dart';
import '../../services/backend.dart';
import '../../theme/theme.dart';

class CsvImportDialog extends StatefulWidget {
  const CsvImportDialog({super.key});

  @override
  State<CsvImportDialog> createState() => _CsvImportDialogState();
}

class _CsvImportDialogState extends State<CsvImportDialog> {
  final TextEditingController _csvController = TextEditingController();
  bool _importing = false;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    // Pre-populate with sample police incident CSV lines around Mumbai
    _csvController.text =
        'lat,lng,category,hour\n'
        '19.0762,72.8779,harassment,22\n'
        '19.0745,72.8750,stalking,23\n'
        '19.0680,72.8720,poor_lighting,21\n'
        '19.0600,72.8640,unsafe_area,24\n'
        '19.0620,72.8660,harassment,23\n'
        '19.0780,72.8800,poor_lighting,22';
  }

  @override
  void dispose() {
    _csvController.dispose();
    super.dispose();
  }

  Future<void> _processCsv() async {
    final rawText = _csvController.text.trim();
    if (rawText.isEmpty) return;

    setState(() {
      _importing = true;
      _statusMessage = null;
    });

    try {
      const converter = CsvToListConverter(eol: '\n', shouldParseNumbers: true);
      final rows = converter.convert(rawText);

      if (rows.isEmpty) {
        setState(() {
          _importing = false;
          _statusMessage = 'CSV is empty.';
        });
        return;
      }

      int importedCount = 0;
      // Skip header if first row has string 'lat'
      final startIndex = (rows.first.isNotEmpty && rows.first[0].toString().toLowerCase().contains('lat')) ? 1 : 0;

      for (var i = startIndex; i < rows.length; i++) {
        final row = rows[i];
        if (row.length < 4) continue;

        final lat = double.tryParse(row[0].toString()) ?? kCityCenter.latitude;
        final lng = double.tryParse(row[1].toString()) ?? kCityCenter.longitude;
        final category = row[2].toString().trim();
        final hour = int.tryParse(row[3].toString()) ?? 22;

        await Backend.reportIncident(
          lat: lat,
          lng: lng,
          category: category,
          hourBucket: hour,
          source: 'police',
        );
        importedCount++;
      }

      setState(() {
        _importing = false;
        _statusMessage = 'Successfully imported $importedCount incidents from police CSV! Heat map refreshed.';
      });

      await Future.delayed(const Duration(milliseconds: 1200));
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() {
        _importing = false;
        _statusMessage = 'Error parsing CSV: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.file_upload_outlined, color: kAccent),
          const SizedBox(width: 8),
          Text(
            'Import Police Aggregate Incidents (CSV)',
            style: GoogleFonts.bricolageGrotesque(fontWeight: FontWeight.w700, fontSize: 18),
          ),
        ],
      ),
      content: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Load aggregate police reports. Expected columns:\n'
              'lat,lng,category,hour',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _csvController,
              maxLines: 8,
              style: GoogleFonts.jetBrainsMono(fontSize: 12),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'lat,lng,category,hour',
              ),
            ),
            if (_statusMessage != null) ...[
              const SizedBox(height: 10),
              Text(
                _statusMessage!,
                style: TextStyle(
                  fontSize: 12,
                  color: _statusMessage!.startsWith('Error') ? Colors.red : kSafeGreen,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _importing ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          style: FilledButton.styleFrom(backgroundColor: kAccent),
          onPressed: _importing ? null : _processCsv,
          icon: _importing
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.check),
          label: const Text('Process and Import'),
        ),
      ],
    );
  }
}
