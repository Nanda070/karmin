import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:karmin/api/dtos/inbox_message.dart';
import 'package:karmin/app/theme.dart';
import 'package:karmin/app/widgets/karmin_card.dart';
import 'package:karmin/app/widgets/karmin_icons.dart';
import 'package:karmin/app/widgets/karmin_scaffold.dart' show KarminPageHeader;
import 'package:karmin/app/widgets/karmin_status.dart';
import 'package:karmin/data/providers.dart';
import 'package:karmin/data/student_repository.dart';
import 'package:karmin/l10n/app_localizations.dart';

class InboxPage extends ConsumerWidget {
  const InboxPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final palette = KarminPalette.of(context);
    final async = ref.watch(studentSnapshotProvider);
    final snapshot = async.valueOrNull ?? StudentSnapshot.empty();
    final unread = snapshot.unreadCount;
    Future<void> refresh() =>
        ref.read(studentSnapshotProvider.notifier).refresh();

    return RefreshIndicator(
      color: palette.carmineBright,
      backgroundColor: palette.field,
      onRefresh: refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: KarminSpacing.xxl),
        children: [
          KarminPageHeader(
            title: l10n.tabInbox,
            trailing: Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: palette.carmine.withValues(alpha: 0.18),
                border: Border.all(
                  color: palette.carmine.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    KarminIcons.mail,
                    size: 12,
                    color: palette.accentText,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    unread > 0 ? l10n.inboxNewCount(unread) : '—',
                    style: KarminTypography.label(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: palette.accentText,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: KarminSpacing.pageX),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (snapshot.errorMessage != null) ...[
                  KarminStatusBanner.fromSnapshot(
                    snapshot: snapshot,
                    l10n: l10n,
                    onRetry: refresh,
                  ),
                  const SizedBox(height: KarminSpacing.sm),
                ],
                if (snapshot.messages.isEmpty)
                  KarminEmptyState(
                    message: l10n.inboxEmpty,
                    icon: KarminIcons.mail,
                  )
                else
                  for (var i = 0; i < snapshot.messages.length; i++) ...[
                    if (i > 0) const SizedBox(height: KarminSpacing.sm),
                    _MessageRow(
                      message: snapshot.messages[i],
                      timeLabel: _timeLabel(
                        l10n,
                        snapshot.messages[i].sentAt,
                        DateTime.now(),
                      ),
                      onTap: () => context.push(
                        '/inbox/${Uri.encodeComponent(snapshot.messages[i].id)}',
                      ),
                    ),
                  ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _timeLabel(AppLocalizations l10n, DateTime? sentAt, DateTime now) {
    if (sentAt == null) {
      return '';
    }
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(sentAt.year, sentAt.month, sentAt.day);
    if (day == today) {
      return DateFormat('HH:mm').format(sentAt);
    }
    if (day == today.subtract(const Duration(days: 1))) {
      return l10n.inboxYesterday;
    }
    if (now.difference(sentAt).inDays < 7) {
      return DateFormat('EEEE').format(sentAt);
    }
    return DateFormat('MMM d').format(sentAt);
  }
}

class _MessageRow extends StatelessWidget {
  const _MessageRow({
    required this.message,
    required this.timeLabel,
    required this.onTap,
  });

  final InboxMessage message;
  final String timeLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = KarminPalette.of(context);
    final unread = message.unread;
    return KarminCard(
      onTap: onTap,
      radius: KarminRadii.md,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: unread
                        ? [
                            palette.carmine.withValues(alpha: 0.35),
                            palette.field,
                          ]
                        : [palette.fieldHi, palette.field],
                  ),
                  border: Border.all(
                    color: unread
                        ? palette.carmine.withValues(alpha: 0.45)
                        : palette.hairline,
                  ),
                ),
                child: Text(
                  message.initials,
                  style: KarminTypography.body(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: palette.text,
                  ),
                ),
              ),
              if (unread)
                Positioned(
                  right: -1,
                  top: -1,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: palette.carmineBright,
                      shape: BoxShape.circle,
                      border: Border.all(color: palette.page, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        message.sender,
                        style: KarminTypography.body(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: palette.text,
                        ),
                      ),
                    ),
                    Text(
                      timeLabel,
                      style: KarminTypography.label(
                        fontSize: 11,
                        color: palette.muted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  message.subject,
                  style: KarminTypography.body(
                    fontSize: 12,
                    color: palette.muted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Icon(
              KarminIcons.chevronRight,
              size: 14,
              color: palette.muted.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}
