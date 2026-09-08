import 'package:karmin/api/dtos/calendar_event.dart';
import 'package:karmin/api/dtos/json_util.dart';

/// Inbox list row. Sender avatars of others are never fetched (PLAN.md §6.2).
class InboxMessage {
  const InboxMessage({
    required this.id,
    required this.sender,
    required this.subject,
    this.sentAt,
    this.unread = false,
    this.preview,
    this.postIds = const [],
  });

  final String id;
  final String sender;
  final String subject;
  final DateTime? sentAt;
  final bool unread;
  final String? preview;
  final List<String> postIds;

  String get initials => initialsFor(sender);

  InboxMessage copyWith({bool? unread, List<String>? postIds}) {
    return InboxMessage(
      id: id,
      sender: sender,
      subject: subject,
      sentAt: sentAt,
      unread: unread ?? this.unread,
      preview: preview,
      postIds: postIds ?? this.postIds,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender': sender,
      'subject': subject,
      'sentAt': sentAt?.toIso8601String(),
      'unread': unread,
      'preview': preview,
      'postIds': postIds,
    };
  }

  factory InboxMessage.fromCacheJson(Map<String, dynamic> json) {
    return InboxMessage(
      id: json['id'] as String? ?? '',
      sender: json['sender'] as String? ?? '',
      subject: json['subject'] as String? ?? '',
      sentAt: DateTime.tryParse(json['sentAt'] as String? ?? ''),
      unread: json['unread'] == true,
      preview: json['preview'] as String?,
      postIds: (json['postIds'] as List?)
              ?.map((id) => id.toString())
              .toList() ??
          const [],
    );
  }
}

class InboxPost {
  const InboxPost({
    required this.id,
    required this.body,
    this.sender,
    this.sentAt,
  });

  final String id;
  final String body;
  final String? sender;
  final DateTime? sentAt;
}

List<InboxMessage> parseInboxMessages(dynamic raw) {
  final messages = <InboxMessage>[];
  for (final item in asItemList(raw)) {
    if (item is! Map) {
      continue;
    }
    final map = stringKeyed(item);
    final id = asNonEmptyString(
      firstValue(map, const [
        'messageId',
        'id',
        'conversationId',
        'threadId',
      ]),
    );
    if (id == null) {
      continue;
    }
    final subject = asNonEmptyString(
          firstValue(map, const [
            'subject',
            'title',
            'topic',
            'messageSubject',
          ]),
        ) ??
        '';
    final sender = asNonEmptyString(
          firstValue(map, const [
            'senderName',
            'fromName',
            'sender',
            'creatorName',
            'from',
            'senderUserName',
            'authorName',
          ]),
        ) ??
        'Neptun';
    final unread = asBool(
      firstValue(map, const [
        'isNew',
        'unread',
        'isUnread',
        'notReaded',
        'isUnReaded',
      ]),
    );
    final preview = asNonEmptyString(
      firstValue(map, const [
        'preview',
        'snippet',
        'shortText',
        'text',
        'body',
      ]),
    );
    final postIds = <String>[];
    final rawPosts = map['postIds'] ?? map['posts'];
    if (rawPosts is List) {
      for (final post in rawPosts) {
        if (post is Map) {
          final postId = asNonEmptyString(
            firstValue(stringKeyed(post), const ['postId', 'id']),
          );
          if (postId != null) {
            postIds.add(postId);
          }
        } else {
          final text = post.toString().trim();
          if (text.isNotEmpty) {
            postIds.add(text);
          }
        }
      }
    }
    messages.add(
      InboxMessage(
        id: id,
        sender: sender,
        subject: subject.isEmpty ? sender : subject,
        sentAt: parseFlexibleDate(
          firstValue(map, const [
            'sendDate',
            'sentDate',
            'date',
            'created',
            'insertDate',
          ]),
        ),
        unread: unread,
        preview: preview == null ? null : stripHtml(preview),
        postIds: postIds,
      ),
    );
  }
  messages.sort((a, b) {
    final aDate = a.sentAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    final bDate = b.sentAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    return bDate.compareTo(aDate);
  });
  return messages;
}

List<InboxPost> parseInboxPosts(dynamic raw) {
  final posts = <InboxPost>[];
  for (final item in asItemList(raw)) {
    if (item is! Map) {
      continue;
    }
    final map = stringKeyed(item);
    final body = asNonEmptyString(
      firstValue(map, const [
        'text',
        'body',
        'content',
        'html',
        'message',
        'postText',
        'description',
      ]),
    );
    if (body == null) {
      continue;
    }
    posts.add(
      InboxPost(
        id: asNonEmptyString(
              firstValue(map, const ['postId', 'id', 'messagePostId']),
            ) ??
            '${posts.length}',
        body: stripHtml(body),
        sender: asNonEmptyString(
          firstValue(map, const [
            'senderName',
            'fromName',
            'sender',
            'creatorName',
            'authorName',
          ]),
        ),
        sentAt: parseFlexibleDate(
          firstValue(map, const [
            'sendDate',
            'sentDate',
            'date',
            'created',
            'insertDate',
          ]),
        ),
      ),
    );
  }
  return posts;
}

List<InboxMessage> parseCachedMessages(dynamic raw) {
  if (raw is! List) {
    return const [];
  }
  return raw
      .whereType<Map>()
      .map(
        (item) => InboxMessage.fromCacheJson(
          item.map((key, value) => MapEntry(key.toString(), value)),
        ),
      )
      .toList();
}
