import 'package:material_ui/material_ui.dart';

import '../../../utils/app_theme.dart';

class AppButton extends StatelessWidget {
  final double? height;
  final double? width;
  final String text;
  final Color? color;
  final Color? textColor;
  final Color? borderColor;
  final Function() onTap;

  const AppButton({
    super.key,
    this.height,
    this.borderColor,
    this.textColor,
    this.width,
    this.color,
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onTap(),
      child: Container(
        alignment: Alignment.center,
        margin: EdgeInsets.all(4),
        width: width ?? MediaQuery.of(context).size.width,
        height: height ?? 45,
        decoration: BoxDecoration(
          border: borderColor == null
              ? null
              : Border.all(color: borderColor!, width: 2),
          color: color ?? Theme.of(context).primaryColor,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).dividerColor,
              blurRadius: 2,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: boldTextStyle.copyWith(
            color: textColor ?? Theme.of(context).cardColor,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
