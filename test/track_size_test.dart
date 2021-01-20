import 'package:flutter/material.dart';
import 'package:flutter_layout_grid/flutter_layout_grid.dart';
import 'package:flutter_layout_grid/src/rendering/layout_grid.dart';
import 'package:flutter_layout_grid/src/foundation/box.dart';
import 'package:flutter_test/flutter_test.dart';

final gridKey = GlobalKey();
final testConstraints = BoxConstraints.loose(Size(800, 600));

void main() {
  group('fixed track sizes', () {
    test('are correctly sized', () {
      final gridSize = _sizeEmptyGrid(
        columnSizes: [fixed(40), fixed(80)],
        rowSizes: [fixed(20), fixed(30)],
      );

      expect(
        gridSize.baseSizesForType(TrackType.column),
        [40, 80],
      );
      expect(
        gridSize.baseSizesForType(TrackType.row),
        [20, 30],
      );
    });

    test('do not expand to fill remaining space', () {
      final gridSize = _sizeEmptyGrid(
        gridFit: GridFit.expand,
        columnSizes: [fixed(40), fixed(80)],
        rowSizes: [fixed(20), fixed(30)],
      );

      expect(
        gridSize.baseSizesForType(TrackType.column),
        [40, 80],
      );
      expect(
        gridSize.baseSizesForType(TrackType.row),
        [20, 30],
      );
    });
  });

  group('flexible track sizes', () {
    test('fill remaining space', () {
      final gridSize = _sizeEmptyGrid(
        columnSizes: [fixed(100), flex(1)],
        rowSizes: [fixed(100), flex(1)],
      );

      expect(
        gridSize.baseSizesForType(TrackType.column),
        [100, 700],
      );
      expect(
        gridSize.baseSizesForType(TrackType.row),
        [100, 500],
      );
    });

    test('share space according to their factor (same factor)', () {
      final gridSize = _sizeEmptyGrid(
        columnSizes: [fixed(100), flex(1), flex(1)],
        rowSizes: [fixed(100), flex(1), flex(1)],
      );

      expect(
        gridSize.baseSizesForType(TrackType.column),
        [100, 350, 350],
      );
      expect(
        gridSize.baseSizesForType(TrackType.row),
        [100, 250, 250],
      );
    });

    test('share space according to their factor (varying factors)', () {
      final gridSize = _sizeEmptyGrid(
        columnSizes: [fixed(100), flex(1), flex(3)],
        rowSizes: [fixed(100), flex(7), flex(1)],
      );

      expect(
        gridSize.baseSizesForType(TrackType.column),
        [100, 700 / 4, 3 * 700 / 4],
      );
      expect(
        gridSize.baseSizesForType(TrackType.row),
        [100, 7 * 500 / 8, 500 / 8],
      );
    });

    test('occupy no space if none available', () {
      final gridSize = _sizeEmptyGrid(
        columnSizes: [fixed(800), flex(1)],
        rowSizes: [fixed(100)],
        constraints: testConstraints,
      );

      expect(
        gridSize.baseSizesForType(TrackType.column),
        [800, 0],
      );
      expect(
        gridSize.baseSizesForType(TrackType.row),
        [100],
      );
    });
  });

  group('intrinsic track sizes', () {
    test('stretch to fill the constraint\'s remaining space', () {
      final gridSize = _sizeEmptyGrid(
        gridFit: GridFit.expand,
        columnSizes: [fixed(100), intrinsic(), fixed(100)],
        rowSizes: [fixed(100), intrinsic(), fixed(100)],
      );

      expect(
        gridSize.baseSizesForType(TrackType.column),
        [100, 600, 100],
      );
      expect(
        gridSize.baseSizesForType(TrackType.row),
        [100, 400, 100],
      );
    });

    test('share while stretching to fill remaining space', () {
      final gridSize = _sizeEmptyGrid(
        gridFit: GridFit.expand,
        columnSizes: [intrinsic(), intrinsic(), intrinsic(), intrinsic()],
        rowSizes: [intrinsic(), intrinsic(), intrinsic(), intrinsic()],
      );

      expect(
        gridSize.baseSizesForType(TrackType.column),
        [200, 200, 200, 200],
      );
      expect(
        gridSize.baseSizesForType(TrackType.row),
        [150, 150, 150, 150],
      );
    });

    test('do not stretch if a flexible track is involved', () {
      final gridSize = _sizeEmptyGrid(
        columnSizes: [flex(1), intrinsic()],
        rowSizes: [flex(1), intrinsic()],
      );

      expect(
        gridSize.baseSizesForType(TrackType.column),
        [800, 0],
      );
      expect(
        gridSize.baseSizesForType(TrackType.row),
        [600, 0],
      );
    });

    testWidgets('sizes to content minimums, then shares what\'s left',
        (tester) async {
      final gridSize = await _sizeGridWithChildren(
        tester,
        gridFit: GridFit.expand,
        columnSizes: [intrinsic(), intrinsic()],
        rowSizes: [intrinsic(), intrinsic()],
        children: [
          constrainedBox(100, 400)
              .withGridPlacement(columnStart: 0, rowStart: 0),
          constrainedBox(200, 100)
              .withGridPlacement(columnStart: 1, rowStart: 1),
        ],
      );

      expect(
        gridSize.baseSizesForType(TrackType.column),
        [100 + 250, 200 + 250],
      );
      expect(
        gridSize.baseSizesForType(TrackType.row),
        [400 + 50, 100 + 50],
      );
    });
  });
}

/// Sizes a grid that does not require the Flutter framework (ie, no children)
/// or widget pumping.
GridSizingInfo _sizeEmptyGrid({
  GridFit gridFit = GridFit.passthrough,
  List<TrackSize> columnSizes,
  List<TrackSize> rowSizes,
  BoxConstraints constraints,
}) {
  final renderGrid = RenderLayoutGrid(
    gridFit: gridFit,
    templateColumnSizes: columnSizes,
    templateRowSizes: rowSizes,
    textDirection: TextDirection.ltr,
  );
  return renderGrid.computeGridSize(
      (constraints ?? testConstraints).constraintsForGridFit(gridFit));
}

Future<GridSizingInfo> _sizeGridWithChildren(
  WidgetTester tester, {
  GridFit gridFit = GridFit.passthrough,
  List<TrackSize> columnSizes,
  List<TrackSize> rowSizes,
  List<Widget> children,
  BoxConstraints constraints,
}) async {
  await tester.pumpWidget(
    WidgetsApp(
      color: Colors.white,
      builder: (context, child) {
        return ConstrainedBox(
          constraints: constraints ?? testConstraints,
          child: LayoutGrid(
            gridFit: gridFit,
            templateColumnSizes: columnSizes,
            templateRowSizes: rowSizes,
            children: children,
          ),
        );
      },
    ),
  );

  final renderGrid =
      tester.renderObject<RenderLayoutGrid>(find.byType(LayoutGrid));
  return renderGrid.lastGridSizing;
}

FixedTrackSize fixed(double size) => FixedTrackSize(size);
FlexibleTrackSize flex(double factor) => FlexibleTrackSize(factor);
IntrinsicContentTrackSize intrinsic() => IntrinsicContentTrackSize();

ConstrainedBox constrainedBox(
  double minW,
  double minH, [
  double maxW,
  double maxH,
]) {
  maxW ??= minW;
  maxH ??= minH;
  return ConstrainedBox(
    constraints: BoxConstraints(
      minWidth: minW,
      maxWidth: maxW,
      minHeight: minH,
      maxHeight: maxH,
    ),
  );
}
