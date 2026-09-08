import 'package:flutter/material.dart';

import 'package:karmin/app/theme.dart';
import 'package:karmin/app/widgets/karmin_icons.dart';
import 'package:karmin/data/student_repository.dart';
import 'package:karmin/l10n/app_localizations.dart';

enum KarminStatusKind { error, cached, empty }

/// Shared error / last-cached / retry banner. Used on Today, Calendar, Study,
/// Inbox, and Auth instead of ad-hoc muted [Text].
class KarminStatusBanner extends StatelessWidget {
  const KarminStatusBanner({
    super.key,
    required this.message,
    this.kind = KarminStatusKind.error,
    this.onRetry,
    this.retryLabel,
  });

  factory KarminStatusBanner.fromSnapshot({
    required StudentSnapshot snapshot,
    required AppLocalizations l10n,
    VoidCallback? onRetry,
  }) {
    return KarminStatusBanner(
      message: snapshot.fromCache ? l10n.dataCached : l10n.dataError,
      kind: snapshot.fromCache
          ? KarminStatusKind.cached
          : KarminStatusKind.error,
      onRetry: onRetry,
      retryLabel: l10n.dataRetry,
    );
  }

  final String message;
  final KarminStatusKind kind;
  final VoidCallback? onRetry;
  final String? retryLabel;

  @override
  Widget build(BuildContext context) {
    final palette = KarminPalette.of(context);
    final icon = switch (kind) {
      KarminStatusKind.cached => KarminIcons.history,
      KarminStatusKind.empty => KarminIcons.inbox,
      KarminStatusKind.error => KarminIcons.warning,
    };
    final accent = kind == KarminStatusKind.error
        ? palette.accentText
        : palette.muted;

    return Semantics(
      liveRegion: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: palette.field.withValues(alpha: palette.isDark ? 0.7 : 1),
          borderRadius: KarminRadii.mdBorder,
          border: Border.all(color: palette.hairline),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
          child: Row(
            children: [
              Icon(icon, size: 16, color: accent),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: KarminTypography.body(
                    fontSize: 13,
                    color: kind == KarminStatusKind.error
                        ? palette.accentText
                        : palette.muted,
                  ),
                ),
              ),
              if (onRetry != null)
                TextButton(
                  onPressed: onRetry,
                  child: Text(retryLabel ?? 'Retry'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Quiet empty copy with an icon, used when a list has nothing to show.
class KarminEmptyState extends StatelessWidget {
  const KarminEmptyState({
    super.key,
    required this.message,
    this.icon = KarminIcons.inbox,
  });

  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final palette = KarminPalette.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: KarminSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: palette.muted),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: KarminTypography.body(
                fontSize: 13,
                color: palette.muted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact auth / form error line (no retry).
class KarminInlineError extends StatelessWidget {
  const KarminInlineError(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    final palette = KarminPalette.of(context);
    return Semantics(
      liveRegion: true,
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: KarminTypography.body(
          fontSize: 13,
          color: palette.accentText,
        ),
      ),
    );
  }
}
