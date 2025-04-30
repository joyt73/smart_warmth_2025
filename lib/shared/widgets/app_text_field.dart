// lib/shared/widgets/app_text_field.dart
import 'package:flutter/material.dart';

// lib/shared/widgets/app_text_field.dart
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
  final bool enabled;
  final int? maxLines;
  final int? minLines;
  final Function(String)? onChanged;
  final String? Function(String?)? validator;

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
    this.enabled = true,
    this.maxLines = 1,
    this.minLines,
    this.onChanged,
    this.validator,
  }) : super(key: key);

  @override
  _AppTextFieldState createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late TextEditingController _controller;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _controller.addListener(_validate);
  }

  @override
  void didUpdateWidget(AppTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      if (oldWidget.controller != null) {
        oldWidget.controller!.removeListener(_validate);
      }
      _controller = widget.controller ?? TextEditingController();
      _controller.addListener(_validate);
      _validate();
    }
    if (widget.validator != oldWidget.validator) {
      _validate();
    }
  }

  void _validate() {
    if (widget.validator != null) {
      setState(() {
        _errorMessage = widget.validator!(_controller.text);
      });
    } else {
      setState(() {
        _errorMessage = null;
      });
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_validate);
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
        Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: _errorMessage != null
                  ? Colors.red
                  : const Color(0xFF95A3A4),
              width: 1.0,
            ),
            borderRadius: BorderRadius.circular(8.0),
            color: const Color(0xFF333232),
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
            // onChanged: (value) {
            //   widget.onChanged?.call(value);
            //   _validate();
            // },
            decoration: InputDecoration(
              hintText: widget.hintText,
              hintStyle: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 16,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
              border: InputBorder.none,
              suffixIcon: widget.suffixIcon,
            ),
            // onSubmitted: (value) {
            //   widget.onSubmitted?.call(value);
            //   _validate();
            // },
          ),
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 8),
          Text(
            _errorMessage!,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.red,
            ),
          ),
        ],
      ],
    );
  }
}

class AppTextField_old extends StatelessWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hintText;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final bool obscureText;
  final Widget? suffixIcon;
  final FocusNode? focusNode;
  final Function(String)? onSubmitted;
  final String? errorText;
  final bool enabled;
  final int? maxLines;
  final int? minLines;
  final Function(String)? onChanged;

  const AppTextField_old({
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
    this.errorText,
    this.enabled = true,
    this.maxLines = 1,
    this.minLines,
    this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
        ],

        Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: errorText != null ? Colors.red : const Color(0xFF95A3A4),
              width: 1.0,
            ),
            borderRadius: BorderRadius.circular(8.0),
            color: const Color(0xFF333232),
          ),
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 16,
            ),
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            obscureText: obscureText,
            enabled: enabled,
            maxLines: maxLines,
            minLines: minLines,
            onChanged: onChanged,
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 16,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
              border: InputBorder.none,
              suffixIcon: suffixIcon,
            ),
            onSubmitted: onSubmitted,
          ),
        ),

        if (errorText != null) ...[
          const SizedBox(height: 8),
          Text(
            errorText!,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.red,
            ),
          ),
        ],
      ],
    );
  }
}