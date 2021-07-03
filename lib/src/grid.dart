import 'package:collection/collection.dart';

class GridAddress {
  GridAddress(this.column, this.row);

  final int column;
  final int row;
}

class Grid<T> {
  Grid({
    required this.rowCount,
    required this.columnCount,
  }) : _values = List.filled(rowCount * columnCount, null);

  Grid.unmodifiableView(Grid<T> source)
      : rowCount = source.rowCount,
        columnCount = source.columnCount,
        _values = source.values;

  final int rowCount;
  final int columnCount;

  bool get isFull => _values.every((value) => value != null);

  late final values = UnmodifiableListView(_values);
  final List<T?> _values;

  late Iterable<GridAddress> addresses = () sync* {
    for (var column = 0; column < columnCount; column++) {
      for (var row = 0; row < rowCount; row++) {
        yield GridAddress(column, row);
      }
    }
  }()
      .toList();

  Iterable<GridAddress> addressesWhereValue(
    bool Function(T? value) f,
  ) sync* {
    var i = 0;
    for (final value in _values) {
      if (f(value)) {
        yield GridAddress(i % columnCount, (i / columnCount).floor());
      }
      i++;
    }
  }

  Iterable<GridAddress> get emptyAddresses =>
      addressesWhereValue((value) => value == null);

  Iterable<MapEntry<GridAddress, T?>> get entries sync* {
    var i = 0;
    for (final value in _values) {
      yield MapEntry(
        GridAddress(i % columnCount, (i / columnCount).floor()),
        value,
      );
      i++;
    }
  }

  Iterable<MapEntry<GridAddress, T?>> entriesWhereValue(
    bool Function(T? value) f,
  ) sync* {
    var i = 0;
    for (final value in _values) {
      if (f(value)) {
        yield MapEntry(
          GridAddress(i % columnCount, (i / columnCount).floor()),
          value,
        );
      }
      i++;
    }
  }

  T? operator [](GridAddress address) =>
      _values[address.row * columnCount + address.column];

  void operator []=(GridAddress address, T? value) =>
      _values[address.row * columnCount + address.column] = value;

  Iterable<T?> rowValues(int index) => _values.sublist(
        index * columnCount,
        (index + 1) * columnCount,
      );

  Iterable<MapEntry<GridAddress, T?>> rowEntries(int index) =>
      rowValues(index).mapIndexed(
        (column, value) => MapEntry(GridAddress(column, index), value),
      );

  Iterable<Iterable<T?>> get allRowsValues =>
      Iterable.generate(rowCount, rowValues);

  Iterable<Iterable<MapEntry<GridAddress, T?>>> get allRowsEntries =>
      Iterable.generate(rowCount, rowEntries);

  Iterable<T?> columnValues(int index) sync* {
    for (var row = 0; row < rowCount; row++) {
      yield this[GridAddress(index, row)];
    }
  }

  Iterable<MapEntry<GridAddress, T?>> columnEntries(int index) =>
      columnValues(index)
          .mapIndexed((row, value) => MapEntry(GridAddress(index, row), value));

  Iterable<Iterable<T?>> get allColumnsValues =>
      Iterable.generate(columnCount, columnValues);

  Iterable<Iterable<MapEntry<GridAddress, T?>>> get allColumnsEntries =>
      Iterable.generate(columnCount, columnEntries);

  Iterable<Iterable<T?>> get allDiagonalsValues sync* {
    yield topLeftBottomRightDiagonalValues;
    yield topRightBottomLeftDiagonalValues;
  }

  Iterable<Iterable<MapEntry<GridAddress, T?>>> get allDiagonalsEntries sync* {
    yield topLeftBottomRightDiagonalEntries;
    yield topRightBottomLeftDiagonalEntries;
  }

  Iterable<T?> get topLeftBottomRightDiagonalValues sync* {
    var row = 0;
    var column = 0;
    while (row < rowCount && column < columnCount) {
      yield this[GridAddress(column++, row++)];
    }
  }

  Iterable<MapEntry<GridAddress, T?>>
      get topLeftBottomRightDiagonalEntries sync* {
    var row = 0;
    var column = 0;
    while (row < rowCount && column < columnCount) {
      final address = GridAddress(column++, row++);
      yield MapEntry(address, this[address]);
    }
  }

  Iterable<T?> get topRightBottomLeftDiagonalValues sync* {
    var row = 0;
    var column = columnCount - 1;
    while (row < rowCount && column >= 0) {
      yield this[GridAddress(column--, row++)];
    }
  }

  Iterable<MapEntry<GridAddress, T?>>
      get topRightBottomLeftDiagonalEntries sync* {
    var row = 0;
    var column = columnCount - 1;
    while (row < rowCount && column >= 0) {
      final address = GridAddress(column--, row++);
      yield MapEntry(address, this[address]);
    }
  }

  Iterable<Iterable<T?>> get allLinesValues sync* {
    yield* allRowsValues;
    yield* allColumnsValues;
    yield* allDiagonalsValues;
  }

  Iterable<Iterable<MapEntry<GridAddress, T?>>> get allLinesEntries sync* {
    yield* allRowsEntries;
    yield* allColumnsEntries;
    yield* allDiagonalsEntries;
  }
}
