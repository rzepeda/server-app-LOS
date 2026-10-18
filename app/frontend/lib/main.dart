import 'dart:math' as math;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'grid_geometry.dart';

void main() => runApp(const LosApp());

class LosApp extends StatelessWidget {
  const LosApp({super.key});

  @override
  Widget build(BuildContext context) => const MaterialApp(
        title: 'appLOS',
        debugShowCheckedModeBanner: false,
        home: GridScreen(),
      );
}

class GridScreen extends StatefulWidget {
  const GridScreen({super.key});

  @override
  State<GridScreen> createState() => _GridScreenState();
}

class _GridScreenState extends State<GridScreen> {
  static const int rows = 20;
  static const int columns = 20;
  static const double cellSize = 32;
  static const double minZoom = 0.25;
  static const double maxZoom = 4.0;

  final List<GridCell> _markers = [];
  Offset? _origin;
  double _zoom = 1;
  Offset? _previousFocalPoint;
  double _startingZoom = 1;

  void _toggleCell(Offset localPosition) {
    final origin = _origin;
    if (origin == null) return;
    final gridPosition = (localPosition - origin) / _zoom;
    final column = (gridPosition.dx / cellSize).floor();
    final row = (gridPosition.dy / cellSize).floor();
    if (row < 0 || row >= rows || column < 0 || column >= columns) return;
    final cell = GridCell(row, column);
    setState(() {
      if (_markers.contains(cell)) {
        _markers.remove(cell);
      } else if (_markers.length < 2) {
        _markers.add(cell);
      }
    });
  }

  void _zoomAt(Offset focalPoint, double factor) {
    final oldOrigin = _origin;
    if (oldOrigin == null) return;
    final next = (_zoom * factor).clamp(minZoom, maxZoom).toDouble();
    setState(() {
      _origin = focalPoint + (oldOrigin - focalPoint) * (next / _zoom);
      _zoom = next;
    });
  }

  void _handleScroll(PointerSignalEvent event) {
    if (event is PointerScrollEvent) {
      _zoomAt(event.localPosition, math.exp(-event.scrollDelta.dy / 500));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;
          _origin ??= Offset(
            (width - columns * cellSize) / 2,
            (height - rows * cellSize) / 2,
          );

          return ClipRect(
            child: Listener(
              onPointerSignal: _handleScroll,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapUp: (details) => _toggleCell(details.localPosition),
                onScaleStart: (details) {
                  _previousFocalPoint = details.localFocalPoint;
                  _startingZoom = _zoom;
                },
                onScaleUpdate: (details) {
                  final last = _previousFocalPoint;
                  final origin = _origin;
                  if (last == null || origin == null) return;
                  final focal = details.localFocalPoint;
                  final next = (_startingZoom * details.scale)
                      .clamp(minZoom, maxZoom)
                      .toDouble();
                  setState(() {
                    _origin = focal +
                        (origin - last) * (next / _zoom);
                    _zoom = next;
                  });
                  _previousFocalPoint = focal;
                },
                onScaleEnd: (_) => _previousFocalPoint = null,
                child: CustomPaint(
                  painter: _GridPainter(
                    origin: _origin!,
                    zoom: _zoom,
                    rows: rows,
                    columns: columns,
                    cellSize: cellSize,
                    markers: List.unmodifiable(_markers),
                  ),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  const _GridPainter({
    required this.origin,
    required this.zoom,
    required this.rows,
    required this.columns,
    required this.cellSize,
    required this.markers,
  });

  final Offset origin;
  final double zoom;
  final int rows;
  final int columns;
  final double cellSize;
  final List<GridCell> markers;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawColor(const Color(0xFFF0F0F0), BlendMode.src);
    canvas.save();
    canvas.translate(origin.dx, origin.dy);
    canvas.scale(zoom);

    final totalWidth = columns * cellSize;
    final totalHeight = rows * cellSize;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, totalWidth, totalHeight),
      Paint()..color = const Color(0xFFCCCCCC),
    );

    if (markers.length == 2) {
      final trace = traceGridLine(markers[0], markers[1],
          rows: rows, columns: columns);
      final fill = Paint()..color = const Color(0xFF8BCF96);
      for (final cell in trace.cells) {
        canvas.drawRect(
          Rect.fromLTWH(cell.column * cellSize, cell.row * cellSize,
              cellSize, cellSize),
          fill,
        );
      }
    }

    final gridPaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 1 / zoom;
    for (var c = 0; c <= columns; c++) {
      final x = c * cellSize;
      canvas.drawLine(Offset(x, 0), Offset(x, totalHeight), gridPaint);
    }
    for (var r = 0; r <= rows; r++) {
      final y = r * cellSize;
      canvas.drawLine(Offset(0, y), Offset(totalWidth, y), gridPaint);
    }

    if (markers.length == 2) {
      final trace = traceGridLine(markers[0], markers[1],
          rows: rows, columns: columns);
      final crossedPaint = Paint()
        ..color = const Color(0xFF176B35)
        ..strokeWidth = 4 / zoom
        ..strokeCap = StrokeCap.butt;
      for (final edge in trace.edges) {
        if (edge.isVertical) {
          final x = edge.columnBoundary * cellSize;
          final y = edge.cellIndex * cellSize;
          canvas.drawLine(
              Offset(x, y), Offset(x, y + cellSize), crossedPaint);
        } else {
          final y = edge.columnBoundary * cellSize;
          final x = edge.cellIndex * cellSize;
          canvas.drawLine(
              Offset(x, y), Offset(x + cellSize, y), crossedPaint);
        }
      }

      canvas.drawLine(
        _markerCenter(markers[0]),
        _markerCenter(markers[1]),
        Paint()
          ..color = const Color(0xFF236F40)
          ..strokeWidth = 2.5 / zoom
          ..strokeCap = StrokeCap.round,
      );
    }

    for (final cell in markers) {
      final center = _markerCenter(cell);
      canvas.drawCircle(
          center, 8 / zoom, Paint()..color = const Color(0xFF171717));
      canvas.drawCircle(
          center,
          8 / zoom,
          Paint()
            ..color = Colors.white
            ..strokeWidth = 1.5 / zoom
            ..style = PaintingStyle.stroke);
    }
    canvas.restore();
  }

  Offset _markerCenter(GridCell cell) => Offset(
        (cell.column + 0.5) * cellSize,
        (cell.row + 0.5) * cellSize,
      );

  @override
  bool shouldRepaint(covariant _GridPainter old) =>
      old.origin != origin ||
      old.zoom != zoom ||
      old.markers.length != markers.length ||
      ! _sameMarkers(old.markers, markers);

  bool _sameMarkers(List<GridCell> a, List<GridCell> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
