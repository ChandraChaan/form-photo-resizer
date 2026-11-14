import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'preset.dart';
import 'resizer.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const _customLabel = 'Custom';

  String _selected = builtInPresets.first.name;
  final _minCtl = TextEditingController();
  final _maxCtl = TextEditingController();
  final _wCtl = TextEditingController();
  final _hCtl = TextEditingController();

  Uint8List? _original;
  String _originalName = 'photo';
  ResizeResult? _result;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _applyPreset(builtInPresets.first);
  }

  @override
  void dispose() {
    _minCtl.dispose();
    _maxCtl.dispose();
    _wCtl.dispose();
    _hCtl.dispose();
    super.dispose();
  }

  void _applyPreset(Preset p) {
    _minCtl.text = '${p.minKb}';
    _maxCtl.text = '${p.maxKb}';
    _wCtl.text = p.width?.toString() ?? '';
    _hCtl.text = p.height?.toString() ?? '';
  }

  Preset? get _note =>
      builtInPresets.where((p) => p.name == _selected).firstOrNull;

  /// Builds a preset from the text fields, or sets [_error] and returns null.
  Preset? _readFields() {
    final min = int.tryParse(_minCtl.text.trim());
    final max = int.tryParse(_maxCtl.text.trim());
    if (max == null || max < 1) {
      _error = 'Enter the maximum size in KB.';
      return null;
    }
    if (min != null && min > max) {
      _error = 'Minimum size cannot be more than maximum.';
      return null;
    }
    final w = int.tryParse(_wCtl.text.trim());
    final h = int.tryParse(_hCtl.text.trim());
    if ((w == null) != (h == null)) {
      _error = 'Fill both width and height, or leave both empty.';
      return null;
    }
    if (w != null && (w < 16 || h! < 16 || w > 6000 || h > 6000)) {
      _error = 'Width and height must be between 16 and 6000 pixels.';
      return null;
    }
    return Preset(
      name: _selected,
      minKb: min ?? 0,
      maxKb: max,
      width: w,
      height: h,
    );
  }

  Future<void> _pick() async {
    final file = await FilePicker.pickFile(type: FileType.image);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    setState(() {
      _original = bytes;
      _originalName = file.name.replaceFirst(RegExp(r'\.[^.]+$'), '');
      _result = null;
      _error = null;
    });
  }

  Future<void> _resize() async {
    final input = _original;
    if (input == null) return;
    setState(() => _error = null);
    final preset = _readFields();
    if (preset == null) {
      setState(() {});
      return;
    }
    setState(() => _busy = true);
    final r = await resizeToPreset(input, preset);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _result = r.isOk ? r : null;
      _error = switch (r.status) {
        ResizeStatus.ok => null,
        ResizeStatus.unreadable =>
          'This file could not be read as an image. Try a JPG or PNG.',
        ResizeStatus.cannotFit =>
          'These limits cannot both be met: a ${preset.width}x${preset.height} px '
              'image does not fit in ${preset.maxKb} KB. Check the numbers in '
              'your notification, or leave width and height empty.',
      };
    });
  }

  Future<void> _save() async {
    final r = _result;
    if (r == null) return;
    await FileSaver.instance.saveFile(
      name: '${_originalName}_resized',
      bytes: r.bytes!,
      fileExtension: 'jpg',
      mimeType: MimeType.jpeg,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Saved.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final note = _note?.note;
    return Scaffold(
      appBar: AppBar(title: const Text('Form Photo Resizer')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Resize a photo, signature or document to the limits of an '
                  'exam or government form. Your image never leaves this device.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _selected,
                  decoration: const InputDecoration(
                    labelText: 'Starting point',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    for (final p in builtInPresets)
                      DropdownMenuItem(value: p.name, child: Text(p.name)),
                    const DropdownMenuItem(
                        value: _customLabel, child: Text(_customLabel)),
                  ],
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() {
                      _selected = v;
                      final p = _note;
                      if (p != null) _applyPreset(p);
                      _result = null;
                    });
                  },
                ),
                const SizedBox(height: 8),
                Card(
                  color: theme.colorScheme.tertiaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      'These numbers are typical values from third-party '
                      'guides, not official ones. Portals change them. Compare '
                      'with your notification and edit the boxes below.'
                      '${note == null ? '' : '\n$note.'}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: _numField(_minCtl, 'Min size (KB)')),
                  const SizedBox(width: 12),
                  Expanded(child: _numField(_maxCtl, 'Max size (KB)')),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: _numField(_wCtl, 'Width (px, optional)')),
                  const SizedBox(width: 12),
                  Expanded(child: _numField(_hCtl, 'Height (px, optional)')),
                ]),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _busy ? null : _pick,
                  icon: const Icon(Icons.photo_library_outlined),
                  label: Text(_original == null
                      ? 'Choose image'
                      : 'Choose a different image'),
                ),
                if (_original != null) ...[
                  const SizedBox(height: 12),
                  _preview('Original', _original!,
                      '${(_original!.length / 1000).toStringAsFixed(1)} KB'),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _busy ? null : _resize,
                    child: _busy
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Resize'),
                  ),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!,
                      style: TextStyle(color: theme.colorScheme.error)),
                ],
                if (_result != null) ...[
                  const SizedBox(height: 16),
                  _preview(
                    'Result',
                    _result!.bytes!,
                    '${_result!.width}x${_result!.height} px, '
                        '${(_result!.bytes!.length / 1000).toStringAsFixed(1)} KB '
                        '(${(_result!.bytes!.length / 1024).toStringAsFixed(1)} KiB), '
                        'JPEG quality ${_result!.quality}',
                  ),
                  if (_result!.padded)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'The picture was smaller than the minimum size, so '
                        'empty bytes were added at the end of the file to '
                        'reach it. The image itself is unchanged.',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.download),
                    label: const Text('Save JPEG'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _numField(TextEditingController c, String label) => TextField(
        controller: c,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        onChanged: (_) => setState(() {
          _selected = _customLabel;
          _result = null;
        }),
      );

  Widget _preview(String title, Uint8List bytes, String caption) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 4),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 240),
            child: Image.memory(bytes, fit: BoxFit.contain),
          ),
          const SizedBox(height: 4),
          Text(caption, style: Theme.of(context).textTheme.bodySmall),
        ],
      );
}
