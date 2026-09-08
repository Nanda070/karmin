import 'package:flutter/material.dart';

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
            trailing: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                l10n.inboxNewCount(3),
                style: KarminTypography.body(
                  fontSize: 13,
                  color: KarminColors.muted,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: KarminSpacing.pageX),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _MessageRow(
                  sender: l10n.demoInboxRegistrar,
                  subject: l10n.demoInboxRegistrarSubject,
                  time: '14:02',
                  unread: true,
                ),
                const SizedBox(height: KarminSpacing.sm),
                _MessageRow(
                  sender: l10n.demoInboxNeptun,
                  subject: l10n.demoInboxNeptunSubject,
                  time: 'Yesterday',
                  unread: true,
                ),
                const SizedBox(height: KarminSpacing.sm),
                _MessageRow(
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
    required this.sender,
    required this.subject,
    required this.time,
    required this.unread,
  });

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
          Padding(
            padding: const EdgeInsets.only(top: 15),
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: unread ? KarminColors.carmine : Colors.transparent,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 10),
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
                          fontWeight: FontWeight.w500,
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
        ],
      ),
    );
  }
}
