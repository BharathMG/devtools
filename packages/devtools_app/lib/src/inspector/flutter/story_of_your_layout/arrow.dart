// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

const defaultArrowColor = Colors.white;
const defaultArrowHeadSize = 16.0;
const defaultArrowStrokeWidth = 2.0;
const defaultDistanceToArrow = 8.0;

enum ArrowType {
  up,
  left,
  right,
  down,
}

Axis axis(ArrowType type) => (type == ArrowType.up || type == ArrowType.down)
    ? Axis.vertical
    : Axis.horizontal;

/// Widget that draws a bidirectional arrow around another widget.
///
/// This widget is typically used to help draw diagrams.
@immutable
class ArrowWrapper extends StatelessWidget {
  ArrowWrapper.unidirectional({
    Key key,
    @required this.child,
    @required ArrowType type,
    this.arrowColor = defaultArrowColor,
    this.arrowHeadSize = defaultArrowHeadSize,
    this.arrowStrokeWidth = defaultArrowStrokeWidth,
    double distanceToArrow = defaultDistanceToArrow,
  })  : assert(child != null),
        assert(type != null),
        assert(arrowColor != null),
        assert(arrowHeadSize != null && arrowHeadSize > 0.0),
        assert(arrowStrokeWidth != null && arrowHeadSize > 0.0),
        assert(distanceToArrow != null && distanceToArrow > 0.0),
        direction = axis(type),
        distanceToArrow = axis(type) == Axis.horizontal
            ? EdgeInsets.symmetric(horizontal: distanceToArrow)
            : EdgeInsets.symmetric(vertical: distanceToArrow),
        isBidirectional = false,
        startArrowType = type,
        endArrowType = type,
        super(key: key);

  ArrowWrapper.bidirectional({
    Key key,
    @required this.child,
    @required this.direction,
    this.arrowColor = defaultArrowColor,
    this.arrowHeadSize = defaultArrowHeadSize,
    this.arrowStrokeWidth = defaultArrowStrokeWidth,
    double distanceToArrow = defaultDistanceToArrow,
  })  : assert(child != null),
        assert(direction != null),
        assert(arrowColor != null),
        assert(arrowHeadSize != null && arrowHeadSize > 0.0),
        assert(arrowStrokeWidth != null && arrowHeadSize > 0.0),
        assert(distanceToArrow != null && distanceToArrow > 0.0),
        distanceToArrow = direction == Axis.horizontal
            ? EdgeInsets.symmetric(horizontal: distanceToArrow)
            : EdgeInsets.symmetric(vertical: distanceToArrow),
        isBidirectional = true,
        startArrowType =
            direction == Axis.horizontal ? ArrowType.left : ArrowType.up,
        endArrowType =
            direction == Axis.horizontal ? ArrowType.right : ArrowType.down,
        super(key: key);

  final Color arrowColor;
  final double arrowHeadSize;
  final double arrowStrokeWidth;
  final Widget child;

  final Axis direction;
  final EdgeInsets distanceToArrow;

  final bool isBidirectional;
  final ArrowType startArrowType;
  final ArrowType endArrowType;

  @override
  Widget build(BuildContext context) {
    return Flex(
      direction: direction,
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: ArrowWidget(
            color: arrowColor,
            headSize: arrowHeadSize,
            strokeWidth: arrowStrokeWidth,
            type: startArrowType,
            shouldDrawHead: isBidirectional
                ? true
                : (startArrowType == ArrowType.left ||
                    startArrowType == ArrowType.up),
          ),
        ),
        Container(
          child: child,
          margin: distanceToArrow,
        ),
        Expanded(
          child: ArrowWidget(
            color: arrowColor,
            headSize: arrowHeadSize,
            strokeWidth: arrowStrokeWidth,
            type: endArrowType,
            shouldDrawHead: isBidirectional
                ? true
                : (endArrowType == ArrowType.right ||
                    endArrowType == ArrowType.down),
          ),
        ),
      ],
    );
  }
}

/// Widget that draws a fully sized, centered, unidirectional arrow according to its constraints
@immutable
class ArrowWidget extends StatelessWidget {
  ArrowWidget({
    this.color = defaultArrowColor,
    this.headSize = defaultArrowHeadSize,
    Key key,
    this.shouldDrawHead = true,
    this.strokeWidth = defaultArrowStrokeWidth,
    @required this.type,
  })  : assert(color != null),
        assert(headSize != null && headSize > 0.0),
        assert(strokeWidth != null && strokeWidth > 0.0),
        assert(shouldDrawHead != null),
        assert(type != null),
        _painter = _ArrowPainter(
          headSize: headSize,
          color: color,
          strokeWidth: strokeWidth,
          type: type,
          shouldDrawHead: shouldDrawHead,
        ),
        super(key: key);

  final Color color;

  /// The arrow head is a Equilateral triangle
  final double headSize;

  final double strokeWidth;

  final ArrowType type;

  final CustomPainter _painter;

  final bool shouldDrawHead;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _painter,
      child: Container(),
    );
  }
}

class _ArrowPainter extends CustomPainter {
  _ArrowPainter({
    this.headSize = defaultArrowHeadSize,
    this.strokeWidth = defaultArrowStrokeWidth,
    this.color = defaultArrowColor,
    this.shouldDrawHead = true,
    @required this.type,
  })  : assert(headSize != null),
        assert(color != null),
        assert(strokeWidth != null),
        assert(type != null),
        assert(shouldDrawHead != null),
        // the height of an equilateral triangle
        headHeight = 0.5 * sqrt(3) * headSize;

  final Color color;
  final double headSize;
  final bool shouldDrawHead;
  final double strokeWidth;
  final ArrowType type;

  final double headHeight;

  bool headIsGreaterThanConstraint(Size size) {
    if (type == ArrowType.left || type == ArrowType.right)
      return headHeight >= (size.width);
    return headHeight >= (size.height);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) =>
      !(oldDelegate is _ArrowPainter &&
          headSize == oldDelegate.headSize &&
          strokeWidth == oldDelegate.strokeWidth &&
          color == oldDelegate.color &&
          type == oldDelegate.type);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth;

    final originX = size.width / 2, originY = size.height / 2;
    Offset lineStartingPoint = Offset.zero;
    Offset lineEndingPoint = Offset.zero;

    if (!headIsGreaterThanConstraint(size) && shouldDrawHead) {
      Offset p1, p2, p3;
      final headSizeDividedBy2 = headSize / 2;
      switch (type) {
        case ArrowType.up:
          p1 = Offset(originX, 0);
          p2 = Offset(originX - headSizeDividedBy2, headHeight);
          p3 = Offset(originX + headSizeDividedBy2, headHeight);
          break;
        case ArrowType.left:
          p1 = Offset(0, originY);
          p2 = Offset(headHeight, originY - headSizeDividedBy2);
          p3 = Offset(headHeight, originY + headSizeDividedBy2);
          break;
        case ArrowType.right:
          final startingX = size.width - headHeight;
          p1 = Offset(size.width, originY);
          p2 = Offset(startingX, originY - headSizeDividedBy2);
          p3 = Offset(startingX, originY + headSizeDividedBy2);
          break;
        case ArrowType.down:
          final startingY = size.height - headHeight;
          p1 = Offset(originX, size.height);
          p2 = Offset(originX - headSizeDividedBy2, startingY);
          p3 = Offset(originX + headSizeDividedBy2, startingY);
          break;
      }
      final path = Path()
        ..moveTo(p1.dx, p1.dy)
        ..lineTo(p2.dx, p2.dy)
        ..lineTo(p3.dx, p3.dy)
        ..close();
      canvas.drawPath(path, paint);

      switch (type) {
        case ArrowType.up:
          lineStartingPoint = Offset(originX, headHeight);
          lineEndingPoint = Offset(originX, size.height);
          break;
        case ArrowType.left:
          lineStartingPoint = Offset(headHeight, originY);
          lineEndingPoint = Offset(size.width, originY);
          break;
        case ArrowType.right:
          final arrowHeadStartingX = size.width - headHeight;
          lineStartingPoint = Offset(0, originY);
          lineEndingPoint = Offset(arrowHeadStartingX, originY);
          break;
        case ArrowType.down:
          final headStartingY = size.height - headHeight;
          lineStartingPoint = Offset(originX, 0);
          lineEndingPoint = Offset(originX, headStartingY);
          break;
      }
    } else {
      // draw full line
      switch (type) {
        case ArrowType.up:
        case ArrowType.down:
          lineStartingPoint = Offset(originX, 0);
          lineEndingPoint = Offset(originX, size.height);
          break;
        case ArrowType.left:
        case ArrowType.right:
          lineStartingPoint = Offset(0, originY);
          lineEndingPoint = Offset(size.width, originY);
          break;
      }
    }
    canvas.drawLine(
      lineStartingPoint,
      lineEndingPoint,
      paint,
    );
  }
}
