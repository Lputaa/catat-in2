import 'package:flutter/material.dart';
import '../../core/theme/neo_brutal_colors.dart';
import '../../core/theme/neo_brutal_theme.dart';
import '../../core/constants/app_constants.dart';

/// Generic tab selector — Row of Expanded segments with 3px border divider
/// Selected: yellow bg, w900 weight. Labels always uppercase.
/// Style Guide §7.1
class NeoSegmentedControl<T> extends StatelessWidget {
  const NeoSegmentedControl({
    super.key,
    required this.segments,
    required this.selected,
    required this.onChanged,
  });

  final List<SegmentItem<T>> segments;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final borderColor = NeoBrutalTheme.borderColor(brightness);

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: borderColor, width: AppConstants.borderPrimary),
        boxShadow: NeoBrutalTheme.hardShadow(
          offset: AppConstants.shadowSmall,
          brightness: brightness,
        ),
      ),
      child: Row(
        children: [
          for (int i = 0; i < segments.length; i++) ...[
            if (i > 0)
              Container(width: AppConstants.borderPrimary, color: borderColor),
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(segments[i].value),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppConstants.spacing10,
                  ),
                  color: segments[i].value == selected
                      ? NeoBrutalColors.yellow
                      : NeoBrutalColors.surface,
                  child: Center(
                    child: Text(
                      segments[i].label.toUpperCase(),
                      style: TextStyle(
                        fontFamily: 'Space Grotesk',
                        fontSize: 12,
                        fontWeight: segments[i].value == selected
                            ? FontWeight.w900
                            : FontWeight.w600,
                        letterSpacing: 0.8,
                        color: NeoBrutalColors.ink,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class SegmentItem<T> {
  final T value;
  final String label;
  const SegmentItem({required this.value, required this.label});
}

/// Helper to create segments easily
List<SegmentItem<T>> neoSegments<T>(List<(T, String)> items) =>
    items.map((e) => SegmentItem(value: e.$1, label: e.$2)).toList();
