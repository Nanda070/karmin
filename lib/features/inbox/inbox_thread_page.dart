import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:karmin/api/dtos/inbox_message.dart';
import 'package:karmin/app/theme.dart';
import 'package:karmin/app/widgets/karmin_card.dart';
import 'package:karmin/app/widgets/karmin_icons.dart';
import 'package:karmin/app/widgets/karmin_scaffold.dart'
    show KarminCircleButton, KarminPageHeader;
import 'package:karmin/data/providers.dart';
import 'package:karmin/data/student_repository.dart';
import 'package:karmin/l10n/app_localizations.dart';

class InboxThreadPage extends ConsumerStatefulWidget {
  const InboxThreadPage({super.key, required this.messageId});

  final String messageId;

  @override
  ConsumerState<InboxThreadPage> createState() => _InboxThreadPageState();
}

class _InboxThreadPageState extends ConsumerState<InboxThreadPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(studentSnapshotProvider.notifier).markMessageRead(widget.messageId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final snapshot =
        ref.watch(studentSnapshotProvider).valueOrNull ?? StudentSnapshot.empty();
    final header = snapshot.messageById(widget.messageId);
    final posts = ref.watch(_threadProvider(widget.messageId));

    return ListView(
      padding: const EdgeInsets.only(bottom: KarminSpacing.xxl),
      children: [
        KarminPageHeader(
          leading: KarminCircleButton(
            onPressed: () => context.pop(),
            icon: KarminIcons.chevronLeft,
            size: 36,
            tooltip: l10n.tabInbox,
          ),
          title: header?.sender ?? l10n.tabInbox,
          subtitle: header?.subject,
          titleStyle: KarminTypography.display(
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: KarminSpacing.pageX),
          child: posts.when(
            loading: () => const Padding(
              padding: EdgeInsets.only(top: 24),
              child: Center(
                child: CircularProgressIndicator(
                  color: KarminColors.carmineBright,
                ),
              ),
            ),
            error: (error, _) => Text(
              l10n.dataError,
              style: KarminTypography.body(color: KarminColors.muted),
            ),
            data: (items) {
              if (items.isEmpty) {
                return Text(
                  header?.preview ?? l10n.inboxThreadEmpty,
                  style: KarminTypography.body(
                    fontSize: 13,
                    color: KarminColors.muted,
                  ),
                );
              }
              return Column(
                children: [
                  for (var i = 0; i < items.length; i++) ...[
                    if (i > 0) const SizedBox(height: KarminSpacing.sm),
                    KarminCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  items[i].sender ?? header?.sender ?? '',
                                  style: KarminTypography.body(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              if (items[i].sentAt != null)
                                Text(
                                  DateFormat('MMM d · HH:mm')
                                      .format(items[i].sentAt!),
                                  style: KarminTypography.label(fontSize: 11),
                                ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            items[i].body,
                            style: KarminTypography.body(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

final _threadProvider =
    FutureProvider.autoDispose.family<List<InboxPost>, String>((ref, id) {
  return ref.read(studentSnapshotProvider.notifier).loadThread(id);
});
