import 'package:flutter/material.dart';

import 'package:flutter_application_1/trainer/pi/pi_loci_binding_service.dart';

/// Side overlay: route steps ↔ π digit groups for the active session.
class PiLociRouteOverlay extends StatelessWidget {
  const PiLociRouteOverlay({
    super.key,
    required this.rows,
    required this.routeName,
    required this.highlightElementIndex,
    required this.surfaceColor,
    required this.borderColor,
    required this.accentColor,
    required this.onSurface,
    required this.title,
    required this.emptyLabel,
    required this.onClose,
    required this.onRowTap,
  });

  final List<PiLociMapRow> rows;
  final String routeName;
  final int? highlightElementIndex;
  final Color surfaceColor;
  final Color borderColor;
  final Color accentColor;
  final Color onSurface;
  final String title;
  final String emptyLabel;
  final VoidCallback onClose;
  final void Function(PiLociMapRow row) onRowTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: surfaceColor.withOpacity(0.97),
      elevation: 8,
      shadowColor: Colors.black54,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 8, 6),
              child: Row(
                children: [
                  Icon(Icons.alt_route_rounded, size: 16, color: accentColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            color: onSurface.withOpacity(0.9),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (routeName.isNotEmpty)
                          Text(
                            routeName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: onSurface.withOpacity(0.45),
                              fontSize: 10,
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: onClose,
                    icon: Icon(Icons.close_rounded, size: 20, color: onSurface.withOpacity(0.55)),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: borderColor.withOpacity(0.25)),
            Expanded(
              child: rows.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          emptyLabel,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: onSurface.withOpacity(0.45), fontSize: 12),
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                      itemCount: rows.length,
                      itemBuilder: (context, index) {
                        final row = rows[index];
                        final highlighted = highlightElementIndex == row.elementIndex;
                        return _RouteRowTile(
                          row: row,
                          highlighted: highlighted,
                          accentColor: accentColor,
                          borderColor: borderColor,
                          onSurface: onSurface,
                          onTap: () => onRowTap(row),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RouteRowTile extends StatelessWidget {
  const _RouteRowTile({
    required this.row,
    required this.highlighted,
    required this.accentColor,
    required this.borderColor,
    required this.onSurface,
    required this.onTap,
  });

  final PiLociMapRow row;
  final bool highlighted;
  final Color accentColor;
  final Color borderColor;
  final Color onSurface;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: highlighted ? accentColor.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: highlighted
                    ? accentColor.withOpacity(0.5)
                    : borderColor.withOpacity(0.22),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 26,
                  alignment: Alignment.center,
                  child: Text(
                    '${row.stepNumber}',
                    style: TextStyle(
                      color: accentColor.withOpacity(0.9),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        row.locusName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: onSurface.withOpacity(0.82),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'π #${row.displayDigitNumber} · ${row.digits}',
                        style: TextStyle(
                          color: onSurface.withOpacity(0.38),
                          fontSize: 9.5,
                          fontFamily: 'monospace',
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                if (row.isRouteWrap)
                  Icon(Icons.loop_rounded, size: 14, color: onSurface.withOpacity(0.28)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact toggle chip for showing/hiding the loci route overlay.
class PiLociOverlayToggle extends StatelessWidget {
  const PiLociOverlayToggle({
    super.key,
    required this.active,
    required this.onTap,
    required this.surfaceColor,
    required this.borderColor,
    required this.accentColor,
    required this.onSurface,
    required this.label,
  });

  final bool active;
  final VoidCallback onTap;
  final Color surfaceColor;
  final Color borderColor;
  final Color accentColor;
  final Color onSurface;
  final String label;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: active ? accentColor.withOpacity(0.14) : surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: active ? accentColor.withOpacity(0.5) : borderColor.withOpacity(0.35),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              active ? Icons.map_rounded : Icons.map_outlined,
              size: 13,
              color: accentColor.withOpacity(0.92),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: onSurface.withOpacity(0.62),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
