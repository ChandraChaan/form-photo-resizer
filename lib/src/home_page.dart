import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'look.dart';
import 'preset.dart';
import 'resizer.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, this.initialImage});

  /// For tests: start with an image already chosen.
  final Uint8List? initialImage;

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
    _original = widget.initialImage;
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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Saved.')));
  }

  bool get _hasSize =>
      _wCtl.text.trim().isNotEmpty && _hCtl.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final l = Look.of(context);
    final note = _note?.note;
    final r = _result;
    final min = int.tryParse(_minCtl.text.trim()) ?? 0;
    final max = int.tryParse(_maxCtl.text.trim()) ?? 0;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
              children: [
                Text('FORM PHOTO', style: l.label()),
                const SizedBox(height: 2),
                Text(
                  'Make your photo fit the form',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: l.ink,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Exact pixels and KB for exam and job forms. The photo never leaves this device.',
                  style: TextStyle(color: l.muted, height: 1.35),
                ),
                const SizedBox(height: 16),
                Text('START FROM', style: l.label()),
                const SizedBox(height: 8),
                SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      for (final p in [
                        ...builtInPresets.map((e) => e.name),
                        _customLabel,
                      ])
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ChoiceChip(
                            label: Text(
                              p,
                              style: TextStyle(
                                color: p == _selected ? l.sheet : l.ink,
                              ),
                            ),
                            selected: p == _selected,
                            onSelected: (_) => setState(() {
                              _selected = p;
                              final preset = _note;
                              if (preset != null) _applyPreset(preset);
                              _result = null;
                            }),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, size: 16, color: l.marigold),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Typical values from third-party guides, not official. Check your notification and edit the numbers.'
                        '${note == null ? '' : ' $note.'}',
                        style: TextStyle(
                          color: l.muted,
                          fontSize: 12.5,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(child: _numField(_minCtl, 'Min KB')),
                    const SizedBox(width: 14),
                    Expanded(child: _numField(_maxCtl, 'Max KB')),
                    const SizedBox(width: 14),
                    Expanded(child: _numField(_wCtl, 'Width px')),
                    const SizedBox(width: 14),
                    Expanded(child: _numField(_hCtl, 'Height px')),
                  ],
                ),
                const SizedBox(height: 18),
                if (_original == null)
                  _DropZone(onTap: _busy ? null : _pick)
                else
                  _Frames(
                    original: _original!,
                    result: r,
                    min: min,
                    max: max,
                    exactSize: _hasSize,
                    onChange: _busy ? null : _pick,
                  ),
                if (_error != null) ...[
                  const SizedBox(height: 10),
                  Text(_error!, style: TextStyle(color: l.bad)),
                ],
                if (r != null && r.padded)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      'The picture was smaller than the minimum, so empty bytes were added at the end of the file to '
                      'reach it. The image itself is unchanged.',
                      style: TextStyle(color: l.muted, fontSize: 12.5),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _original == null
          ? null
          : Material(
              color: l.sheet,
              child: SafeArea(
                top: false,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: l.rule)),
                  ),
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                  child: r == null
                      ? FilledButton(
                          onPressed: _busy ? null : _resize,
                          child: _busy
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: l.ink,
                                  ),
                                )
                              : const Text('Resize'),
                        )
                      : FilledButton.icon(
                          onPressed: _save,
                          icon: const Icon(Icons.download),
                          label: const Text('Save JPEG'),
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
    style: const TextStyle(
      fontFeatures: Look.figures,
      fontWeight: FontWeight.w700,
      fontSize: 16,
    ),
    decoration: InputDecoration(labelText: label),
    onChanged: (_) => setState(() {
      _selected = _customLabel;
      _result = null;
    }),
  );
}

/// Before anything is chosen: a dashed slot like the photo box on a form.
class _DropZone extends StatelessWidget {
  const _DropZone({required this.onTap});
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l = Look.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: CustomPaint(
        painter: _Dashes(l.muted.withValues(alpha: 0.7)),
        child: Container(
          height: 190,
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_a_photo_outlined, size: 34, color: l.ink),
              const SizedBox(height: 8),
              Text(
                'Choose photo or signature',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: l.ink,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'JPG, PNG and most phone photos',
                style: TextStyle(color: l.muted, fontSize: 12.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Before and after, side by side. The after frame is drawn like the box on
/// the form, labelled with its exact size, with a meter for the KB band.
class _Frames extends StatelessWidget {
  const _Frames({
    required this.original,
    required this.result,
    required this.min,
    required this.max,
    required this.exactSize,
    required this.onChange,
  });

  final Uint8List original;
  final ResizeResult? result;
  final int min;
  final int max;
  final bool exactSize;
  final VoidCallback? onChange;

  @override
  Widget build(BuildContext context) {
    final l = Look.of(context);
    final r = result;
    Widget frame(
      String title,
      Widget child,
      String caption, {
      bool slot = false,
    }) => Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: l.label()),
          const SizedBox(height: 6),
          CustomPaint(
            painter: slot ? _Dashes(l.ink.withValues(alpha: 0.5)) : null,
            child: Container(
              height: 200,
              padding: const EdgeInsets.all(8),
              decoration: slot
                  ? null
                  : BoxDecoration(
                      border: Border.all(color: l.rule),
                      color: l.sheet,
                    ),
              alignment: Alignment.center,
              child: child,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            caption,
            style: TextStyle(
              color: l.muted,
              fontSize: 12,
              fontFeatures: Look.figures,
            ),
          ),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            frame(
              'YOUR PHOTO',
              Image.memory(original, fit: BoxFit.contain),
              '${(original.length / 1000).toStringAsFixed(0)} KB',
            ),
            const SizedBox(width: 12),
            frame(
              'FOR THE FORM',
              r == null
                  ? Text('Press Resize', style: TextStyle(color: l.muted))
                  : Image.memory(r.bytes!, fit: BoxFit.contain),
              r == null
                  ? (exactSize
                        ? 'Cropped to the size above'
                        : 'Shrunk only if needed')
                  : '${r.width} × ${r.height} px · quality ${r.quality}',
              slot: true,
            ),
          ],
        ),
        if (r != null) ...[
          const SizedBox(height: 14),
          _KbMeter(bytes: r.bytes!.length, min: min, max: max),
        ],
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: onChange,
            icon: const Icon(Icons.swap_horiz, size: 18),
            label: const Text('Choose a different image'),
          ),
        ),
      ],
    );
  }
}

/// The allowed KB band and where the file landed.
class _KbMeter extends StatelessWidget {
  const _KbMeter({required this.bytes, required this.min, required this.max});
  final int bytes;
  final int min;
  final int max;

  @override
  Widget build(BuildContext context) {
    final l = Look.of(context);
    final kb = bytes / 1000;
    final kib = bytes / 1024;
    final ok = bytes <= max * 1000 && bytes >= min * 1024;
    final top = (max * 1.25).clamp(1, double.infinity).toDouble();
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: l.sheet,
        border: Border.all(color: ok ? l.ok : l.bad, width: 1.3),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                ok ? Icons.check_circle : Icons.error_outline,
                color: ok ? l.ok : l.bad,
                size: 20,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  ok
                      ? 'Fits: ${kb.toStringAsFixed(1)} KB'
                      : 'Outside the limits: ${kb.toStringAsFixed(1)} KB',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: l.ink,
                    fontFeatures: Look.figures,
                  ),
                ),
              ),
              Text(
                '${kib.toStringAsFixed(1)} KiB',
                style: TextStyle(
                  color: l.muted,
                  fontSize: 12,
                  fontFeatures: Look.figures,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, box) {
              final w = box.maxWidth;
              double x(double v) => (v / top).clamp(0.0, 1.0) * w;
              return SizedBox(
                height: 30,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 8,
                      child: Container(height: 8, color: l.rule),
                    ),
                    Positioned(
                      left: x(min.toDouble()),
                      width: x(max.toDouble()) - x(min.toDouble()),
                      top: 8,
                      child: Container(
                        height: 8,
                        color: l.ok.withValues(alpha: 0.35),
                      ),
                    ),
                    Positioned(
                      left: (x(kb) - 1.5).clamp(0, w - 3),
                      top: 2,
                      child: Container(width: 3, height: 20, color: l.ink),
                    ),
                    Positioned(
                      left: x(min.toDouble()),
                      top: 20,
                      child: Text(
                        '$min',
                        style: TextStyle(
                          fontSize: 10.5,
                          color: l.muted,
                          fontFeatures: Look.figures,
                        ),
                      ),
                    ),
                    Positioned(
                      left: (x(max.toDouble()) - 18).clamp(0, w - 36),
                      top: 20,
                      child: Text(
                        '$max KB',
                        style: TextStyle(
                          fontSize: 10.5,
                          color: l.muted,
                          fontFeatures: Look.figures,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Dashes extends CustomPainter {
  _Dashes(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size s) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & s, const Radius.circular(8)),
      );
    for (final m in path.computeMetrics()) {
      for (var d = 0.0; d < m.length; d += 10) {
        canvas.drawPath(m.extractPath(d, d + 5), p);
      }
    }
  }

  @override
  bool shouldRepaint(_Dashes o) => o.color != color;
}
