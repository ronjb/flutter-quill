import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import '../editor/editor.dart';

class ScribbleFocusable extends StatefulWidget {
  const ScribbleFocusable({
    required this.child,
    required this.focusNode,
    required this.editableKey,
    required this.updateSelectionRects,
    required this.enabled,
    super.key,
  });

  final Widget child;
  final FocusNode focusNode;
  final GlobalKey editableKey;
  final VoidCallback updateSelectionRects;
  final bool enabled;

  @override
  // ignore: library_private_types_in_public_api
  _ScribbleFocusableState createState() => _ScribbleFocusableState();
}

class _ScribbleFocusableState extends State<ScribbleFocusable>
    implements ScribbleClient {
  _ScribbleFocusableState()
      : _elementIdentifier = 'quill-scribble-${_nextElementIdentifier++}';

  @override
  void initState() {
    super.initState();
    if (widget.enabled) {
      TextInput.registerScribbleElement(elementIdentifier, this);
    }
  }

  @override
  void didUpdateWidget(ScribbleFocusable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.enabled && widget.enabled) {
      TextInput.registerScribbleElement(elementIdentifier, this);
    }

    if (oldWidget.enabled && !widget.enabled) {
      TextInput.unregisterScribbleElement(elementIdentifier);
    }
  }

  @override
  void dispose() {
    TextInput.unregisterScribbleElement(elementIdentifier);
    super.dispose();
  }

  RenderBox? get renderEditable =>
      widget.editableKey.currentContext?.findRenderObject() as RenderBox?;

  RenderBox? get quillEditorRenderBox {
    final quillEditorState =
        context.findAncestorStateOfType<QuillEditorState>();
    return quillEditorState?.context.findRenderObject() as RenderBox?;
  }

  static int _nextElementIdentifier = 1;
  final String _elementIdentifier;

  @override
  String get elementIdentifier => _elementIdentifier;

  @override
  void onScribbleFocus(Offset offset) {
    widget.focusNode.requestFocus();
    // TODO(ron): Is this needed?
    // renderEditable?.selectPositionAt(
    //     from: offset, cause: SelectionChangedCause.scribble);
    widget.updateSelectionRects();
  }

  @override
  bool isInScribbleRect(Rect rect) {
    final calculatedBounds = bounds;
    if (calculatedBounds == Rect.zero) {
      return false;
    }
    if (!calculatedBounds.overlaps(rect)) {
      return false;
    }
    final intersection = calculatedBounds.intersect(rect);
    final result = HitTestResult();
    WidgetsBinding.instance
        .hitTestInView(result, intersection.center, View.of(context).viewId);
    return result.path.any((entry) =>
        entry.target == renderEditable || entry.target == quillEditorRenderBox);
  }

  @override
  Rect get bounds {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !mounted || !box.attached) {
      return Rect.zero;
    }
    final transform = box.getTransformTo(null);

    final size = quillEditorRenderBox?.size ?? box.size;
    return MatrixUtils.transformRect(
        transform, Rect.fromLTWH(0, 0, size.width, size.height));
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
