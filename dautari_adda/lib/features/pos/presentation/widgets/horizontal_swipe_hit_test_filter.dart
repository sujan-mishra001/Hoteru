import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class HorizontalSwipeHitTestFilter extends SingleChildRenderObjectWidget {
  final double startPercentage;
  final double endPercentage;

  const HorizontalSwipeHitTestFilter({
    super.key,
    required Widget child,
    this.startPercentage = 0.15,
    this.endPercentage = 0.85,
  }) : super(child: child);

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderHorizontalSwipeHitTestFilter(
      startPercentage: startPercentage,
      endPercentage: endPercentage,
    );
  }

  @override
  void updateRenderObject(BuildContext context, _RenderHorizontalSwipeHitTestFilter renderObject) {
    renderObject
      ..startPercentage = startPercentage
      ..endPercentage = endPercentage;
  }
}

class _RenderHorizontalSwipeHitTestFilter extends RenderProxyBox {
  double startPercentage;
  double endPercentage;

  _RenderHorizontalSwipeHitTestFilter({
    required this.startPercentage,
    required this.endPercentage,
    RenderBox? child,
  }) : super(child);

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    final double width = size.width;
    final double x = position.dx;
    
    // If within edge zones, ignore hits so parent takes over
    if (x < width * startPercentage || x > width * endPercentage) {
      return false;
    }

    return super.hitTest(result, position: position);
  }
}
