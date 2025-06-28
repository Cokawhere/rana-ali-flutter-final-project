import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  const CustomTextField({
    super.key,
    this.hintText,
    this.hintColor,
    this.labelText,
    this.onChanged,
    this.validator,
    this.obscureText = false,
    this.inputType,
    this.borderWidth,
    this.enabledWidth,
    this.focusedWidth,
    this.controller,

  });

  final String? hintText;
  final String? labelText;
  final Color? hintColor;
  final Function(String)? onChanged;
  final String? Function(String?)? validator;
  final bool? obscureText;
  final TextInputType? inputType;
  final double? borderWidth;
  final double? enabledWidth;
  final double? focusedWidth;
  final TextEditingController? controller;


  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller:controller ,
      keyboardType: inputType ?? TextInputType.text,
      obscureText: obscureText ?? false,
      validator: validator,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: TextStyle(color: hintColor),
        hintText: hintText,
        hintStyle: TextStyle(color: hintColor),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: Colors.black,
            width: enabledWidth ?? 1.0,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        border: OutlineInputBorder(
          borderSide: BorderSide(
            color: Colors.black,
            width: borderWidth ?? 1.0,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: Colors.black,
            width: focusedWidth ?? 2.0,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
