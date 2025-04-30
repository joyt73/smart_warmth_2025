import 'package:flutter/material.dart';

class AppTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hintText;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final bool obscureText;
  final Widget? suffixIcon;
  final FocusNode? focusNode;
  final Function(String)? onSubmitted;
  final String? Function(String?)? validator;
  final bool enabled;
  final int? maxLines;
  final int? minLines;
  final Function(String)? onChanged;

  const AppTextField({
    Key? key,
    this.controller,
    this.label,
    this.hintText,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.obscureText = false,
    this.suffixIcon,
    this.focusNode,
    this.onSubmitted,
    this.validator,
    this.enabled = true,
    this.maxLines = 1,
    this.minLines,
    this.onChanged,
  }) : super(key: key);

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late TextEditingController _controller;
  String? _errorMessage;
  final _formFieldKey = GlobalKey<FormFieldState>();

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
  }

  @override
  void didUpdateWidget(AppTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller && widget.controller != null) {
      _controller = widget.controller!;
    }
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
        ],

        // Utilizziamo FormField per gestire correttamente lo stato e la validazione
        FormField<String>(
          key: _formFieldKey,
          validator: widget.validator,
          initialValue: _controller.text,
          autovalidateMode: AutovalidateMode.disabled, // Importante: non validare automaticamente
          builder: (FormFieldState<String> field) {
            // Aggiorniamo _errorMessage quando lo stato del campo cambia
            _errorMessage = field.errorText;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: field.hasError
                          ? Colors.red
                          : const Color(0xFF95A3A4),
                      width: 1.0,
                    ),
                    borderRadius: BorderRadius.circular(8.0),
                    color: Colors.white,
                  ),
                  child: TextField(
                    controller: _controller,
                    focusNode: widget.focusNode,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                    ),
                    keyboardType: widget.keyboardType,
                    textInputAction: widget.textInputAction,
                    obscureText: widget.obscureText,
                    enabled: widget.enabled,
                    maxLines: widget.maxLines,
                    minLines: widget.minLines,
                    onChanged: (value) {
                      field.didChange(value);

                      // Se il campo era già stato validato, aggiorna la validazione
                      if (field.errorText != null || field.hasError) {
                        field.validate();
                      }

                      if (widget.onChanged != null) {
                        widget.onChanged!(value);
                      }
                    },
                    onSubmitted: (value) {
                      field.validate();
                      if (widget.onSubmitted != null) {
                        widget.onSubmitted!(value);
                      }
                    },
                    decoration: InputDecoration(
                      hintText: widget.hintText,
                      hintStyle: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 12.0,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      suffixIcon: widget.suffixIcon,
                      fillColor: Colors.white,
                      filled: true,
                    ),
                  ),
                ),

                if (field.hasError && field.errorText != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    field.errorText!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.red,
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}