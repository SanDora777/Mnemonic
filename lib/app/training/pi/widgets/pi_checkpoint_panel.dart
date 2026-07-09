import 'package:flutter/material.dart';

import 'package:flutter_application_1/trainer/pi/pi_checkpoint.dart';

typedef PiCheckpointAction = void Function(PiCheckpoint checkpoint);
typedef PiCheckpointCreate = void Function(int digitIndex, String label);

/// Checkpoint list + quick-save for the π setup screen.
class PiCheckpointPanel extends StatelessWidget {
  const PiCheckpointPanel({
    super.key,
    required this.checkpoints,
    required this.currentDigitIndex,
    required this.onJumpTo,
    required this.onDelete,
    required this.onSaveCurrent,
    required this.surfaceColor,
    required this.borderColor,
    required this.accentColor,
    required this.onSurface,
    required this.title,
    required this.saveLabel,
    required this.emptyLabel,
    required this.digitLabelBuilder,
  });

  final List<PiCheckpoint> checkpoints;
  final int currentDigitIndex;
  final PiCheckpointAction onJumpTo;
  final PiCheckpointAction onDelete;
  final VoidCallback onSaveCurrent;
  final Color surfaceColor;
  final Color borderColor;
  final Color accentColor;
  final Color onSurface;
  final String title;
  final String saveLabel;
  final String emptyLabel;
  final String Function(int displayDigit) digitLabelBuilder;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.flag_outlined, size: 14, color: accentColor.withOpacity(0.9)),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: onSurface.withOpacity(0.45),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: onSaveCurrent,
                style: TextButton.styleFrom(
                  foregroundColor: accentColor,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(saveLabel, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (checkpoints.isEmpty)
            Text(
              emptyLabel,
              style: TextStyle(color: onSurface.withOpacity(0.42), fontSize: 12, height: 1.35),
            )
          else
            SizedBox(
              height: 72,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: checkpoints.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final cp = checkpoints[index];
                  final isActive = cp.digitIndex == currentDigitIndex;
                  return _CheckpointChip(
                    checkpoint: cp,
                    isActive: isActive,
                    accentColor: accentColor,
                    surfaceColor: surfaceColor,
                    borderColor: borderColor,
                    onSurface: onSurface,
                    digitLabel: digitLabelBuilder(cp.displayDigitNumber),
                    onTap: () => onJumpTo(cp),
                    onDelete: () => onDelete(cp),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _CheckpointChip extends StatelessWidget {
  const _CheckpointChip({
    required this.checkpoint,
    required this.isActive,
    required this.accentColor,
    required this.surfaceColor,
    required this.borderColor,
    required this.onSurface,
    required this.digitLabel,
    required this.onTap,
    required this.onDelete,
  });

  final PiCheckpoint checkpoint;
  final bool isActive;
  final Color accentColor;
  final Color surfaceColor;
  final Color borderColor;
  final Color onSurface;
  final String digitLabel;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isActive ? accentColor.withOpacity(0.12) : surfaceColor,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        onLongPress: onDelete,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 132,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isActive ? accentColor.withOpacity(0.55) : borderColor.withOpacity(0.35),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                checkpoint.label.isEmpty ? digitLabel : checkpoint.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: onSurface.withOpacity(0.88),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                digitLabel,
                style: TextStyle(
                  color: accentColor.withOpacity(0.85),
                  fontSize: 10,
                  letterSpacing: 0.6,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
