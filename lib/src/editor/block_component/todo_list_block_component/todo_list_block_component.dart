import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor/src/editor/block_component/base_component/widget/nested_list_widget.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class TodoListBlockKeys {
  TodoListBlockKeys._();

  /// The checked data of a todo list block.
  ///
  /// The value is a boolean.
  static const String checked = 'checked';
}

Node todoListNode({
  required bool checked,
  String? text,
  Attributes? attributes,
  Iterable<Node>? children,
}) {
  attributes ??= {'delta': (Delta()..insert(text ?? '')).toJson()};
  return Node(
    type: 'todo_list',
    attributes: {
      TodoListBlockKeys.checked: checked,
      ...attributes,
    },
    children: children ?? [],
  );
}

class TodoListBlockComponentBuilder extends BlockComponentBuilder {
  TodoListBlockComponentBuilder({
    this.configuration = const BlockComponentConfiguration(),
    this.textStyleBuilder,
    this.icon,
  });

  final BlockComponentConfiguration configuration;

  /// The text style of the todo list block.
  final TextStyle Function(bool checked)? textStyleBuilder;

  /// The icon of the todo list block.
  final Widget? Function(bool checked)? icon;

  @override
  Widget build(BlockComponentContext blockComponentContext) {
    final node = blockComponentContext.node;
    return TodoListBlockComponentWidget(
      key: node.key,
      node: node,
      configuration: configuration,
      textStyleBuilder: textStyleBuilder,
      icon: icon,
    );
  }

  @override
  bool validate(Node node) {
    return node.delta != null &&
        node.attributes[TodoListBlockKeys.checked] is bool;
  }
}

class TodoListBlockComponentWidget extends StatefulWidget {
  const TodoListBlockComponentWidget({
    super.key,
    required this.node,
    this.configuration = const BlockComponentConfiguration(),
    this.textStyleBuilder,
    this.icon,
  });

  final Node node;
  final BlockComponentConfiguration configuration;
  final TextStyle Function(bool checked)? textStyleBuilder;
  final Widget? Function(bool checked)? icon;

  @override
  State<TodoListBlockComponentWidget> createState() =>
      _TodoListBlockComponentWidgetState();
}

class _TodoListBlockComponentWidgetState
    extends State<TodoListBlockComponentWidget>
    with SelectableMixin, DefaultSelectable, BlockComponentConfigurable {
  @override
  final forwardKey = GlobalKey(debugLabel: 'flowy_rich_text');

  @override
  GlobalKey<State<StatefulWidget>> get containerKey => widget.node.key;

  @override
  BlockComponentConfiguration get configuration => widget.configuration;

  @override
  Node get node => widget.node;

  late final editorState = Provider.of<EditorState>(context, listen: false);

  bool get checked => widget.node.attributes[TodoListBlockKeys.checked];

  @override
  Widget build(BuildContext context) {
    return widget.node.children.isEmpty
        ? buildTodoListBlockComponent(context)
        : buildTodoListBlockComponentWithChildren(context);
  }

  Widget buildTodoListBlockComponentWithChildren(BuildContext context) {
    return NestedListWidget(
      children: editorState.renderer.buildList(
        context,
        widget.node.children,
      ),
      child: buildTodoListBlockComponent(context),
    );
  }

  Widget buildTodoListBlockComponent(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _TodoListIcon(
            icon: widget.icon?.call(checked) ?? defaultCheckboxIcon(),
            onTap: checkOrUncheck,
          ),
          Flexible(
            child: FlowyRichText(
              key: forwardKey,
              node: widget.node,
              editorState: editorState,
              placeholderText: placeholderText,
              textSpanDecorator: (textSpan) =>
                  textSpan.updateTextStyle(textStyle).updateTextStyle(
                        widget.textStyleBuilder?.call(checked) ??
                            defaultTextStyle(),
                      ),
              placeholderTextSpanDecorator: (textSpan) =>
                  textSpan.updateTextStyle(
                placeholderTextStyle,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> checkOrUncheck() async {
    final transaction = editorState.transaction
      ..updateNode(widget.node, {
        TodoListBlockKeys.checked: !checked,
      });
    return editorState.apply(transaction);
  }

  FlowySvg defaultCheckboxIcon() {
    return FlowySvg(
      width: 22,
      height: 22,
      padding: const EdgeInsets.only(right: 5.0),
      name: checked ? 'check' : 'uncheck',
    );
  }

  TextStyle? defaultTextStyle() {
    if (!checked) {
      return null;
    }
    return TextStyle(
      decoration: TextDecoration.lineThrough,
      color: Colors.grey.shade400,
    );
  }
}

class _TodoListIcon extends StatelessWidget {
  const _TodoListIcon({
    required this.icon,
    required this.onTap,
  });

  final Widget icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: icon,
      ),
    );
  }
}
