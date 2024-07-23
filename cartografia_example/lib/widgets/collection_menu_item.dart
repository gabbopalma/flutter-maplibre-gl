import 'package:flutter/material.dart';

class CollectionMenuItem extends PopupMenuEntry<String> {
  final MapEntry<String, bool> entry;
  final void Function(bool?)? onChanged;
  const CollectionMenuItem({super.key, required this.entry, this.onChanged});

  @override
  State<CollectionMenuItem> createState() => _CollectionMenuItemState();

  @override
  double get height => 16.0;

  @override
  bool represents(String? value) {
    throw UnimplementedError();
  }
}

class _CollectionMenuItemState extends State<CollectionMenuItem> {
  MapEntry<String, bool> get e => widget.entry;
  late bool value;

  @override
  void initState() {
    super.initState();
    value = e.value;
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuItem<String>(
      padding: EdgeInsets.zero,
      value: e.key,
      child: Row(
        children: [
          Checkbox(
            value: e.value,
            onChanged: (bool? value) {
              setState(() => this.value = value!);
              widget.onChanged?.call(value);
            },
          ),
          Expanded(child: Text(e.key, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}
