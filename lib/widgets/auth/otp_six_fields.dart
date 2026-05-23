import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/tokens/tokens.dart';

/// Six single-digit fields with auto-advance, backspace retreat, and clipboard paste.
class OtpSixFields extends StatefulWidget {
  const OtpSixFields({
    super.key,
    required this.onChanged,
    required this.onCompleted,
    this.enabled = true,
  });

  final ValueChanged<String> onChanged;
  final ValueChanged<String> onCompleted;
  final bool enabled;

  @override
  OtpSixFieldsState createState() => OtpSixFieldsState();
}

class OtpSixFieldsState extends State<OtpSixFields> {
  late final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  late final List<FocusNode> _nodes = List.generate(6, (_) => FocusNode());

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.enabled) {
        _nodes.first.requestFocus();
      }
    });
  }

  void _emit() {
    final code = _controllers.map((c) => c.text).join();
    widget.onChanged(code);
    if (code.length == 6) {
      widget.onCompleted(code);
    }
  }

  /// Clears all digits and focuses the first cell.
  void clear() {
    for (final c in _controllers) {
      c.clear();
    }
    widget.onChanged('');
    if (mounted && widget.enabled) {
      _nodes.first.requestFocus();
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final n in _nodes) {
      n.dispose();
    }
    super.dispose();
  }

  void _onDigitChanged(int index, String raw) {
    if (!widget.enabled) {
      return;
    }
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 1) {
      _pasteDigits(index, digits);
      return;
    }
    final char = digits.isEmpty ? '' : digits[0];
    if (_controllers[index].text != char) {
      _controllers[index].text = char;
    }
    _emit();
    if (char.isNotEmpty && index < 5) {
      _nodes[index + 1].requestFocus();
    }
  }

  void _pasteDigits(int startIndex, String digits) {
    for (var i = 0; i < 6; i++) {
      _controllers[i].clear();
    }
    var di = 0;
    for (var fi = startIndex; fi < 6 && di < digits.length; fi++, di++) {
      _controllers[fi].text = digits[di];
    }
    _emit();
    final last = (startIndex + digits.length - 1).clamp(0, 5);
    _nodes[last].requestFocus();
  }

  KeyEventResult _onKey(int index, KeyEvent event) {
    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }
    if (event.logicalKey == LogicalKeyboardKey.backspace) {
      if (_controllers[index].text.isEmpty && index > 0) {
        _nodes[index - 1].requestFocus();
        _controllers[index - 1].clear();
        _emit();
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  Future<void> pasteFromClipboard() async {
    if (!widget.enabled) {
      return;
    }
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim() ?? '';
    final digits = text.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 6) {
      _pasteDigits(0, digits);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Copy a 6-digit code to paste.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FocusTraversalGroup(
          policy: WidgetOrderTraversalPolicy(),
          child: Row(
            children: List.generate(6, (i) {
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: i < 5 ? 8 : 0),
                  child: Focus(
                    onKeyEvent: (node, event) => _onKey(i, event),
                    child: TextField(
                      controller: _controllers[i],
                      focusNode: _nodes[i],
                      enabled: widget.enabled,
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          ),
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(1),
                      ],
                      decoration: const InputDecoration(
                        counterText: '',
                        contentPadding:
                            EdgeInsets.symmetric(vertical: 14, horizontal: 4),
                      ),
                      onChanged: (v) => _onDigitChanged(i, v),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: widget.enabled ? pasteFromClipboard : null,
            icon: const Icon(Icons.content_paste_go_rounded, size: 20),
            label: const Text('Paste code'),
          ),
        ),
      ],
    );
  }
}
