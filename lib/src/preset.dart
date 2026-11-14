/// Limits a form portal puts on an uploaded image.
///
/// [width] and [height] are either both set (exact pixel size, the image is
/// centre-cropped to fit) or both null (keep the aspect ratio, only shrink if
/// the file is too big).
class Preset {
  const Preset({
    required this.name,
    required this.minKb,
    required this.maxKb,
    this.width,
    this.height,
    this.note,
  }) : assert((width == null) == (height == null),
            'width and height must both be set or both be null');

  final String name;
  final int minKb;
  final int maxKb;
  final int? width;
  final int? height;
  final String? note;

  bool get hasExactSize => width != null && height != null;

  Preset copyWith({
    String? name,
    int? minKb,
    int? maxKb,
    int? Function()? width,
    int? Function()? height,
  }) =>
      Preset(
        name: name ?? this.name,
        minKb: minKb ?? this.minKb,
        maxKb: maxKb ?? this.maxKb,
        width: width != null ? width() : this.width,
        height: height != null ? height() : this.height,
        note: note,
      );

  @override
  String toString() =>
      '$name: $minKb-$maxKb KB${hasExactSize ? ', ${width}x$height px' : ''}';
}

/// Starting points only. These figures were collected from third-party guides
/// in November 2026 and they do not always agree with each other. Portals
/// change their limits between notifications, so always check the figures in
/// your own notification and edit the fields before you resize.
const List<Preset> builtInPresets = [
  Preset(
    name: 'IBPS photo',
    minKb: 20,
    maxKb: 50,
    width: 200,
    height: 230,
    note: 'IBPS PO/Clerk style',
  ),
  Preset(
    name: 'IBPS signature',
    minKb: 10,
    maxKb: 20,
    width: 140,
    height: 60,
    note: 'IBPS PO/Clerk style',
  ),
  Preset(
    name: 'IBPS left thumb impression',
    minKb: 20,
    maxKb: 50,
    width: 240,
    height: 240,
    note: 'IBPS PO/Clerk style',
  ),
  Preset(
    name: 'IBPS handwritten declaration',
    minKb: 50,
    maxKb: 100,
    width: 800,
    height: 400,
    note: 'IBPS PO/Clerk style',
  ),
  Preset(
    name: 'SSC signature',
    minKb: 10,
    maxKb: 20,
    note: 'Sources agree on size, not on pixels',
  ),
  Preset(
    name: 'UPSC photograph',
    minKb: 20,
    maxKb: 200,
    note: 'Sources disagree on pixels, so none is set',
  ),
  Preset(
    name: 'UPSC signature',
    minKb: 20,
    maxKb: 100,
    note: 'Sources disagree on pixels, so none is set',
  ),
];
