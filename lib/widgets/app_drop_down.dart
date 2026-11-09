import 'package:flutter/material.dart';
import 'package:influx_app/utils/app_theme.dart';

class AppDropDown extends StatelessWidget {
  final List<String> items;
  final String? lableText;
  final String? initialValue;
  final String? Function(String? val)? validator;
  final bool isFilled;
  final Color? fillColor;
  final Widget? suffix;
  final Widget? prefix;
  final String? hintText;
  final ValueChanged onChanged;

  const AppDropDown({
    super.key,
    required this.items,
    this.validator,
    required this.onChanged,
    this.lableText,
    this.hintText,
    this.initialValue,
    this.fillColor,
    this.isFilled = false,
    this.suffix,
    this.prefix,
  });

  InputBorder border(BuildContext context) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(8),
    borderSide: BorderSide(color: AppColors.white, width: 2),
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        if ((lableText ?? "").isNotEmpty) ...{
          Text(
            lableText!,
            maxLines: 1,
          ),
          SizedBox(height: 2),
        },
        DropdownButtonHideUnderline(
          child: DropdownButtonFormField(
            iconEnabledColor: Theme.of(context).highlightColor,
            initialValue: initialValue,
            // style: normalTextStyle.copyWith(
            //   fontSize: 14.sp,
            //   color: Theme.of(context).canvasColor,
            // ),
            validator: validator,
            dropdownColor: Theme.of(context).scaffoldBackgroundColor,
            menuMaxHeight: 500,
            decoration: InputDecoration(
              contentPadding: EdgeInsets.symmetric(horizontal: 8),
              fillColor: isFilled ? fillColor! : null,
              filled: isFilled,
              border: border(context),
              errorBorder: border(context),
              disabledBorder: border(context),
              enabledBorder: border(context),
              focusedBorder: border(context),
              focusedErrorBorder: border(context),
              hintText: hintText,
              hintMaxLines: 1,
              // hintStyle: normalTextStyle.copyWith(
              //   color: Theme.of(context).disabledColor,
              // ),
              prefixIcon: prefix,
              suffixIcon: suffix,
            ),
            isDense: false,
            isExpanded: true,
            padding: EdgeInsets.symmetric(horizontal: 8),
            items: items
                .map(
                  (e) => DropdownMenuItem<String>(
                    value: e,
                    child: Text(
                      e.toString(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
            onChanged: onChanged,
            autovalidateMode: AutovalidateMode.onUserInteraction,
          ),
        ),
      ],
    );
  }
}
