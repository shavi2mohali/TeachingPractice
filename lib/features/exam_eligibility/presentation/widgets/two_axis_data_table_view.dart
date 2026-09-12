import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class TwoAxisDataTableView extends StatefulWidget {
  const TwoAxisDataTableView({required this.child, super.key});

  final Widget child;

  @override
  State<TwoAxisDataTableView> createState() => _TwoAxisDataTableViewState();
}

class _TwoAxisDataTableViewState extends State<TwoAxisDataTableView> {
  final ScrollController _horizontalController = ScrollController();
  final ScrollController _verticalController = ScrollController();

  @override
  void dispose() {
    _horizontalController.dispose();
    _verticalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(
            scrollbars: false,
            dragDevices: {
              PointerDeviceKind.touch,
              PointerDeviceKind.mouse,
              PointerDeviceKind.trackpad,
              PointerDeviceKind.stylus,
            },
          ),
          child: Scrollbar(
            controller: _horizontalController,
            thumbVisibility: true,
            interactive: true,
            scrollbarOrientation: ScrollbarOrientation.bottom,
            notificationPredicate: (notification) =>
                notification.metrics.axis == Axis.horizontal,
            child: SingleChildScrollView(
              controller: _horizontalController,
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                child: SizedBox(
                  height: constraints.maxHeight,
                  child: Scrollbar(
                    controller: _verticalController,
                    thumbVisibility: true,
                    interactive: true,
                    scrollbarOrientation: ScrollbarOrientation.right,
                    notificationPredicate: (notification) =>
                        notification.metrics.axis == Axis.vertical,
                    child: SingleChildScrollView(
                      controller: _verticalController,
                      child: widget.child,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
