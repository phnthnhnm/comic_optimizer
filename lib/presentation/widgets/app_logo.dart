import 'package:material_ui/material_ui.dart';

/// The Comic Optimizer mark, shared by the sidebar and About screen.
class AppLogo extends StatelessWidget {
  final double size;

  const AppLogo({super.key, this.size = 32});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/icon/app_icon.png',
      width: size,
      height: size,
      filterQuality: FilterQuality.high,
      semanticLabel: 'Comic Optimizer',
    );
  }
}
