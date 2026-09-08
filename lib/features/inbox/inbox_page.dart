import 'package:flutter/material.dart';
import 'package:karmin/app/widgets/karmin_icons.dart';

import 'package:karmin/app/theme.dart';
import 'package:karmin/app/widgets/karmin_card.dart';
import 'package:karmin/app/widgets/karmin_scaffold.dart' show KarminPageHeader;
import 'package:karmin/l10n/app_localizations.dart';

class InboxPage extends StatelessWidget {
  const InboxPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return ListView(
      padding: const EdgeInsets.only(bottom: KarminSpacing.xxl),
      children: [
        KarminPageHeader(
          title: l10n.tabInbox,
          trailing: Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: KarminColors.carmine.withValues(alpha: 0.18),
              border: Border.all(
                color: KarminColors.carmine.withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  KarminIcons.mail,
                  size: 12,
                  color: KarminColors.carmineBright,
                ),
                const SizedBox(width: 5),
                Text(
                  l10n.inboxNewCount(3),
                  style: KarminTypography.label(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: KarminColors.carmineBright,
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
              _MessageRow(
                initials: 'R',
                sender: l10n.demoInboxRegistrar,
                subject: l10n.demoInboxRegistrarSubject,
                time: '14:02',
                unread: true,
              ),
              const SizedBox(height: KarminSpacing.sm),
              _MessageRow(
                initials: 'N',
                sender: l10n.demoInboxNeptun,
                subject: l10n.demoInboxNeptunSubject,
                time: 'Yesterday',
                unread: true,
              ),
              const SizedBox(height: KarminSpacing.sm),
              _MessageRow(
                initials: 'K',
                sender: l10n.demoInboxInstructor,
                subject: l10n.demoInboxInstructorSubject,
                time: 'Monday',
                unread: false,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MessageRow extends StatelessWidget {
  const _MessageRow({
    required this.initials,
    required this.sender,
    required this.subject,
    required this.time,
    required this.unread,
  });

  final String initials;
  final String sender;
  final String subject;
  final String time;
  final bool unread;

  @override
  Widget build(BuildContext context) {
    return KarminCard(
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
                            KarminColors.carmine.withValues(alpha: 0.35),
                            KarminColors.navy,
                          ]
                        : [const Color(0xFF1A2438), KarminColors.navy],
                  ),
                  border: Border.all(
                    color: unread
                        ? KarminColors.carmine.withValues(alpha: 0.45)
                        : KarminColors.hairline,
                  ),
                ),
                child: Text(
                  initials,
                  style: KarminTypography.body(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
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
                      color: KarminColors.carmineBright,
                      shape: BoxShape.circle,
                      border: Border.all(color: KarminColors.ink, width: 2),
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
                        sender,
                        style: KarminTypography.body(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      time,
                      style: KarminTypography.label(fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subject,
                  style: KarminTypography.body(
                    fontSize: 12,
                    color: KarminColors.muted,
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
              color: KarminColors.muted.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}
