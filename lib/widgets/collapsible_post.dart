import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class CollapsiblePost extends StatefulWidget {
  final String content;
  final int maxLines;
  final TextStyle? textStyle;
  final TextStyle? actionStyle;
  final String expandText;
  final String collapseText;

  const CollapsiblePost({
    super.key,
    required this.content,
    this.maxLines = 4,
    this.textStyle,
    this.actionStyle,
    this.expandText = 'Read more...',
    this.collapseText = 'Show less',
  });

  @override
  CollapsiblePostState createState() => CollapsiblePostState();
}

class CollapsiblePostState extends State<CollapsiblePost> {
  bool _isExpanded = false;
  bool _needsExpand = false;
  final GlobalKey _textKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkIfTextOverflows();
    });
  }

  void _checkIfTextOverflows() {
    final RenderObject? renderObject = _textKey.currentContext
        ?.findRenderObject();
    if (renderObject is RenderParagraph) {
      final TextPainter textPainter = TextPainter(
        text: TextSpan(
          text: widget.content,
          style: widget.textStyle ?? const TextStyle(fontSize: 16),
        ),
        maxLines: widget.maxLines,
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: renderObject.paintBounds.width);

      setState(() {
        _needsExpand = textPainter.didExceedMaxLines;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            return Text(
              key: _textKey,
              widget.content,
              maxLines: _isExpanded ? null : widget.maxLines,
              overflow: _isExpanded
                  ? TextOverflow.visible
                  : TextOverflow.ellipsis,
              style: widget.textStyle ?? const TextStyle(fontSize: 16),
            );
          },
        ),
        if (_needsExpand || _isExpanded) ...[
          const SizedBox(height: 4),
          GestureDetector(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Text(
              _isExpanded ? widget.collapseText : widget.expandText,
              style:
                  widget.actionStyle ??
                  const TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
        ],
      ],
    );
  }
}
