import 'package:flutter/material.dart';

class SlideLeftRoute extends PageRouteBuilder {
  final Widget page;
  SlideLeftRoute({required this.page})
      : super(
          pageBuilder: (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
          ) =>
              page,
          transitionsBuilder: (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
            Widget child,
          ) =>
              SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
}

class ZoomPageTransition extends PageRouteBuilder {
  final Widget page;
  ZoomPageTransition({required this.page})
      // : super(
      //     pageBuilder: (
      //       BuildContext context,
      //       Animation<double> animation,
      //       Animation<double> secondaryAnimation,
      //     ) =>
      //         page,
      //     transitionsBuilder: (
      //       BuildContext context,
      //       Animation<double> animation,
      //       Animation<double> secondaryAnimation,
      //       Widget child,
      //     ) =>
      //         ScaleTransition(
      //       scale: animation,
      //       child: child,
      //     ),
      //   );
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: const Duration(milliseconds: 500),
        );

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // animation = CurvedAnimation(parent: animation, curve: Curves.easeInCubic);
    ///
    return SlideTransition(
      position: animation.drive(Tween(
        begin: const Offset(-1, 0),
        end: const Offset(0, 0),
      ).chain(CurveTween(curve: Curves.easeOutCubic))),
      child: ScaleTransition(
        scale: animation,
        child: child,
      ),
    );
  }
}
