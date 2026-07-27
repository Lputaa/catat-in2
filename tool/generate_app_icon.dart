// Generates the Catat-In launcher icon assets programmatically so the
// artwork always matches the Neo-Brutal brand palette exactly.
//
// Usage:
//   dart run tool/generate_app_icon.dart
//   dart run flutter_launcher_icons
//
// Outputs:
//   assets/icon/app_icon.png            (full icon, orange background)
//   assets/icon/app_icon_foreground.png (adaptive foreground, transparent)
import 'dart:io';

import 'package:image/image.dart' as img;

const _size = 1024;

final _orange = img.ColorRgba8(255, 107, 53, 255); // NeoBrutalColors.primary
final _ink = img.ColorRgba8(26, 26, 26, 255); // NeoBrutalColors.ink
final _white = img.ColorRgba8(255, 255, 255, 255);

void main() {
  final outDir = Directory('assets/icon');
  outDir.createSync(recursive: true);

  // Full icon: solid orange background + mark at full size.
  final icon = img.Image(width: _size, height: _size, numChannels: 4);
  img.fill(icon, color: _orange);
  _drawMark(icon, s: 1.0);
  File('assets/icon/app_icon.png').writeAsBytesSync(img.encodePng(icon));

  // Adaptive foreground: transparent canvas, mark scaled into the
  // central safe zone (Android masks the outer ~25%).
  final fg = img.Image(width: _size, height: _size, numChannels: 4);
  _drawMark(fg, s: 0.58);
  File(
    'assets/icon/app_icon_foreground.png',
  ).writeAsBytesSync(img.encodePng(fg));

  stdout.writeln('Icon assets written to assets/icon/');
}

/// Draws the Neo-Brutal "ledger card with C + coin" mark centered on [dst],
/// scaled by [s].
void _drawMark(img.Image dst, {required double s}) {
  const cx = _size ~/ 2;
  const cy = _size ~/ 2;

  int sc(num v) => (v * s).round();

  // Card geometry
  final halfW = sc(280);
  final halfH = sc(300);
  final border = sc(26);
  final shadow = sc(40);

  // Hard offset shadow (no blur — Neo-Brutal signature)
  img.fillRect(
    dst,
    x1: cx - halfW + shadow,
    y1: cy - halfH + shadow,
    x2: cx + halfW + shadow,
    y2: cy + halfH + shadow,
    color: _ink,
  );

  // Card: ink border, white face
  img.fillRect(
    dst,
    x1: cx - halfW,
    y1: cy - halfH,
    x2: cx + halfW,
    y2: cy + halfH,
    color: _ink,
  );
  img.fillRect(
    dst,
    x1: cx - halfW + border,
    y1: cy - halfH + border,
    x2: cx + halfW - border,
    y2: cy + halfH - border,
    color: _white,
  );

  // Chunky letter "C": ink ring with a right-side opening
  final ringCy = cy - sc(40);
  final outerR = sc(180);
  final innerR = sc(104);
  img.fillCircle(dst, x: cx, y: ringCy, radius: outerR, color: _ink);
  img.fillCircle(dst, x: cx, y: ringCy, radius: innerR, color: _white);
  img.fillRect(
    dst,
    x1: cx + sc(56),
    y1: ringCy - sc(72),
    x2: cx + outerR + sc(8),
    y2: ringCy + sc(72),
    color: _white,
  );

  // Coin docked at the card's bottom-right corner
  final coinX = cx + sc(160);
  final coinY = cy + sc(200);
  img.fillCircle(dst, x: coinX, y: coinY, radius: sc(96), color: _ink);
  img.fillCircle(dst, x: coinX, y: coinY, radius: sc(64), color: _orange);
  // Inner dot to read as a coin, not a "minus" badge
  img.fillCircle(dst, x: coinX, y: coinY, radius: sc(24), color: _ink);
}
