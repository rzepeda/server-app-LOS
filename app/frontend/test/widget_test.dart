import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_starter/grid_geometry.dart';
import 'package:app_starter/main.dart';

void main() {
  test('horizontal segment crosses expected cells and vertical edges', () {
    final trace = traceGridLine(
      const GridCell(2, 1),
      const GridCell(2, 4),
      rows: 20,
      columns: 20,
    );
    expect(trace.cells, {
      const GridCell(2, 1),
      const GridCell(2, 2),
      const GridCell(2, 3),
      const GridCell(2, 4),
    });
    expect(trace.edges, {
      const GridEdge.vertical(2, 2),
      const GridEdge.vertical(3, 2),
      const GridEdge.vertical(4, 2),
    });
  });

  test('diagonal segment highlights crossing boundaries', () {
    final trace = traceGridLine(
      const GridCell(1, 1),
      const GridCell(3, 2),
      rows: 20,
      columns: 20,
    );
    expect(trace.cells.contains(const GridCell(1, 1)), isTrue);
    expect(trace.cells.contains(const GridCell(3, 2)), isTrue);
    expect(trace.edges.any((e) => e.isVertical), isTrue);
    expect(trace.edges.any((e) => !e.isVertical), isTrue);
  });

  testWidgets('renders grid and toggles a marker', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const LosApp());
    expect(find.byType(GridScreen), findsOneWidget);
    final paint = find.byType(CustomPaint).last;
    await tester.tapAt(tester.getCenter(paint));
    await tester.pump();
    expect(tester.takeException(), isNull);
    await tester.tapAt(tester.getCenter(paint));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
