import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cypcar/core/theme/app_theme.dart';

class AuthTextField extends StatefulWidget {
  final String label;
  final String? hint;
  final TextEditingController controller;
  final bool obscure;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final String? Function(String?)? validator;
  final List<TextInputFormatter>? inputFormatters;
  final Widget? prefix;
  final String? prefixText;
  final VoidCallback? onEditingComplete;
  final FocusNode? focusNode;

  const AuthTextField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.obscure = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.validator,
    this.inputFormatters,
    this.prefix,
    this.prefixText,
    this.onEditingComplete,
    this.focusNode,
  });

  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField> {
  bool _obscure = true;
  bool _focused = false;
  late final FocusNode _focus;

  @override
  void initState() {
    super.initState();
    _obscure = widget.obscure;
    _focus = widget.focusNode ?? FocusNode();
    _focus.addListener(() => setState(() => _focused = _focus.hasFocus));
  }

  @override
  void dispose() {
    if (widget.focusNode == null) _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FormField<String>(
      validator: widget.validator,
      initialValue: widget.controller.text,
      builder: (FormFieldState<String> state) {
        // Kontrolcüdeki değişiklikleri FormField state'ine yansıt
        widget.controller.addListener(() {
          if (state.value != widget.controller.text) {
            state.didChange(widget.controller.text);
          }
        });

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: state.hasError
                    ? Colors.redAccent
                    : (_focused
                        ? AppTheme.primary
                        : (isDark ? Colors.white54 : Colors.black45)),
              ),
            ),
            const SizedBox(height: 8),
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.cardDark : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: state.hasError
                      ? Colors.redAccent.withValues(alpha: 0.5)
                      : (_focused
                          ? AppTheme.primary
                          : (isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.black.withValues(alpha: 0.08))),
                  width: _focused ? 1.5 : 1,
                ),
              ),
              child: TextFormField(
                controller: widget.controller,
                focusNode: _focus,
                obscureText: widget.obscure ? _obscure : false,
                keyboardType: widget.keyboardType,
                textInputAction: widget.textInputAction,
                onChanged: (v) => state.didChange(v),
                inputFormatters: widget.inputFormatters,
                onEditingComplete: widget.onEditingComplete,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                decoration: InputDecoration(
                  isDense: true,
                  filled: true,
                  fillColor: Colors.transparent,
                  hintText: widget.hint,
                  hintStyle: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white24 : Colors.black26,
                    fontWeight: FontWeight.w400,
                  ),
                  prefixText: widget.prefixText,
                  prefixStyle: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                  prefix: widget.prefix,
                  suffixIcon: widget.obscure
                      ? IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: Icon(
                            _obscure
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded,
                            size: 20,
                            color: isDark ? Colors.white38 : Colors.black38,
                          ),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  errorStyle: const TextStyle(fontSize: 0, height: 0),
                ),
              ),
            ),
            if (state.hasError)
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 4),
                child: Text(
                  state.errorText ?? '',
                  style: const TextStyle(
                    color: Colors.redAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
