import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

/// AppBar azul que cubre el notch del iPhone (viewPadding.top).
class SfAppBar extends StatelessWidget implements PreferredSizeWidget {
  const SfAppBar({
    super.key,
    this.title,
    this.leading,
    this.actions,
    this.bottom,
    this.automaticallyImplyLeading = true,
  });

  final Widget? title;
  final Widget? leading;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;
  final bool automaticallyImplyLeading;

  static const _toolbar = 56.0;

  @override
  Size get preferredSize {
    final bottomHeight = bottom?.preferredSize.height ?? 0;
    // preferredSize sin context: el inset se aplica en build; Scaffold
    // usa el tamaño real del hijo. Devolvemos toolbar+bottom; el padding
    // superior lo aporta el Material envolvente vía height intrínseca.
    return Size.fromHeight(_toolbar + bottomHeight);
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.viewPaddingOf(context).top;
    final bottomHeight = bottom?.preferredSize.height ?? 0;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: AppTheme.colorNavBar,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Material(
        color: AppTheme.colorNavBar,
        elevation: 2,
        shadowColor: Colors.black26,
        child: SizedBox(
          height: top + _toolbar + bottomHeight,
          width: double.infinity,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: top),
              SizedBox(
                height: _toolbar,
                child: AppBar(
                  primary: false,
                  toolbarHeight: _toolbar,
                  backgroundColor: AppTheme.colorNavBar,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  scrolledUnderElevation: 0,
                  surfaceTintColor: Colors.transparent,
                  automaticallyImplyLeading: automaticallyImplyLeading,
                  leading: leading,
                  title: title,
                  actions: actions,
                ),
              ),
              if (bottom != null) bottom!,
            ],
          ),
        ),
      ),
    );
  }
}
