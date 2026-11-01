/// Where the far end of a splay is, in metres east, north and up from the
/// station it was shot from.
///
/// A splay end has no name, so this offset is all that identifies it; it
/// holds while the model is the same file.
class ModelSplayOffset {
  const ModelSplayOffset(this.east, this.north, this.up);

  final double east;
  final double north;
  final double up;

  /// Two offsets this close name the same splay end: the viewer's numbers
  /// and a stored copy differ only by rounding.
  static const matchToleranceMetres = 0.10;

  bool matches(ModelSplayOffset other) =>
      (east - other.east).abs() <= matchToleranceMetres &&
      (north - other.north).abs() <= matchToleranceMetres &&
      (up - other.up).abs() <= matchToleranceMetres;

  List<double> toList() => [east, north, up];

  static ModelSplayOffset? fromList(Object? value) {
    if (value is! List || value.length != 3) return null;
    final numbers = value.whereType<num>().toList();
    if (numbers.length != 3) return null;
    return ModelSplayOffset(
      numbers[0].toDouble(),
      numbers[1].toDouble(),
      numbers[2].toDouble(),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ModelSplayOffset &&
      other.east == east &&
      other.north == north &&
      other.up == up;

  @override
  int get hashCode => Object.hash(east, north, up);
}
