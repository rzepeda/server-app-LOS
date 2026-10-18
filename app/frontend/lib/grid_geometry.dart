import 'dart:math' as math;

/// A cell in the finite grid, indexed from the upper-left corner.
class GridCell {
  const GridCell(this.row, this.column);
  final int row;
  final int column;

  @override
  bool operator ==(Object other) =>
      other is GridCell && other.row == row && other.column == column;

  @override
  int get hashCode => Object.hash(row, column);
}

/// A vertical edge is at columnBoundary x, covering row; a horizontal edge
/// is at rowBoundary y, covering column.
class GridEdge {
  const GridEdge.vertical(this.columnBoundary, this.cellIndex)
      : isVertical = true;
  const GridEdge.horizontal(this.columnBoundary, this.cellIndex)
      : isVertical = false;

  final bool isVertical;
  final int columnBoundary;
  final int cellIndex;

  @override
  bool operator ==(Object other) =>
      other is GridEdge &&
      other.isVertical == isVertical &&
      other.columnBoundary == columnBoundary &&
      other.cellIndex == cellIndex;

  @override
  int get hashCode => Object.hash(isVertical, columnBoundary, cellIndex);
}

class GridTrace {
  const GridTrace(this.cells, this.edges);
  final Set<GridCell> cells;
  final Set<GridEdge> edges;
}

/// Traverses the segment between the centers of two grid cells.
///
/// Cell coverage is determined by the midpoint of each interval between
/// crossings. At an exact grid corner, both crossed boundaries are recorded.
/// Out-of-bounds edges are excluded.
GridTrace traceGridLine(
  GridCell start,
  GridCell end, {
  required int rows,
  required int columns,
}) {
  final x0 = start.column + 0.5;
  final y0 = start.row + 0.5;
  final dx = (end.column - start.column).toDouble();
  final dy = (end.row - start.row).toDouble();
  final cuts = <double>[0.0, 1.0];
  final edges = <GridEdge>{};

  if (dx != 0) {
    for (var x = math.min(start.column, end.column) + 1;
        x <= math.max(start.column, end.column);
        x++) {
      final t = (x - x0) / dx;
      if (t <= 0 || t >= 1) continue;
      cuts.add(t);
      final y = y0 + t * dy;
      final row = y.floor();
      if (row >= 0 && row < rows && x > 0 && x < columns) {
        edges.add(GridEdge.vertical(x, row));
      }
    }
  }

  if (dy != 0) {
    for (var y = math.min(start.row, end.row) + 1;
        y <= math.max(start.row, end.row);
        y++) {
      final t = (y - y0) / dy;
      if (t <= 0 || t >= 1) continue;
      cuts.add(t);
      final x = x0 + t * dx;
      final column = x.floor();
      if (column >= 0 && column < columns && y > 0 && y < rows) {
        edges.add(GridEdge.horizontal(y, column));
      }
    }
  }

  cuts.sort();
  final cells = <GridCell>{};
  for (var i = 0; i < cuts.length - 1; i++) {
    if (cuts[i + 1] - cuts[i] < 1e-10) continue;
    final t = (cuts[i] + cuts[i + 1]) / 2;
    final column = (x0 + t * dx).floor();
    final row = (y0 + t * dy).floor();
    if (row >= 0 && row < rows && column >= 0 && column < columns) {
      cells.add(GridCell(row, column));
    }
  }
  if (start == end) cells.add(start);
  return GridTrace(cells, edges);
}
