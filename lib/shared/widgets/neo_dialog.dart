import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';

/// Shows a centered dialog with a Neo-Brutal *scale* entrance (no opacity fade).
///
/// Why not [showDialog]?
/// The default Material dialog transition fades the content in through an
/// [Opacity] layer. Our sheets/buttons rely on hard [BoxShadow]s, and
/// compositing those shadows through an alpha layer makes them render as a
/// dark/black block on the first (raster-cached) frame — the artifact only
/// clears once a repaint is triggered (e.g. the user taps something).
///
/// Using [showGeneralDialog] with a [ScaleTransition] avoids the opacity layer
/// entirely, so the shadows paint correctly from the very first frame while
/// keeping the barrier fade for a clean backdrop.
Future<T?> showNeoDialog<T>({
  required BuildContext context,
  required Widget child,
  bool barrierDismissible = true,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black54,
    transitionDuration: AppConstants.animDialog,
    pageBuilder: (context, animation, secondaryAnimation) {
      return Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: child,
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, dialogChild) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutBack,
        reverseCurve: Curves.easeIn,
      );
      return ScaleTransition(
        scale: Tween<double>(begin: 0.92, end: 1.0).animate(curved),
        child: dialogChild,
      );
    },
  );
}
