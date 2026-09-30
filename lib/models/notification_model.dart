class NotificationModel {
  final dynamic id;
  final dynamic orderId;
  final String title;
  final String content;
  final String type;
  final DateTime? createdAt;
  final bool isRead;

  NotificationModel({
    this.id,
    this.orderId,
    required this.title,
    required this.content,
    required this.type,
    this.createdAt,
    this.isRead = false,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    DateTime? parsedDate;
    final rawDate = json['createdAt'] ??
        json['created_at'] ??
        json['timestamp'] ??
        json['date'];
    if (rawDate != null) {
      if (rawDate is DateTime) {
        parsedDate = rawDate;
      } else if (rawDate is String) {
        parsedDate = DateTime.tryParse(rawDate);
      } else if (rawDate is int) {
        parsedDate = DateTime.fromMillisecondsSinceEpoch(rawDate);
      }
    }

    bool readStatus = false;
    if (json.containsKey('isRead')) {
      readStatus = json['isRead'] == true;
    } else if (json.containsKey('is_read')) {
      readStatus = json['is_read'] == true;
    } else if (json.containsKey('read')) {
      readStatus = json['read'] == true;
    } else if (json.containsKey('unread')) {
      readStatus = json['unread'] != true;
    }

    return NotificationModel(
      id: json['id'] ?? json['_id'],
      orderId: json['orderId'] ?? json['order_id'] ?? json['order_number'],
      title: (json['title'] ?? '').toString(),
      content: (json['content'] ??
              json['description'] ??
              json['message'] ??
              '')
          .toString(),
      type: (json['type'] ?? '').toString(),
      createdAt: parsedDate,
      isRead: readStatus,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'orderId': orderId,
      'title': title,
      'content': content,
      'type': type,
      'createdAt': createdAt?.toIso8601String(),
      'isRead': isRead,
    };
  }

  NotificationModel copyWith({
    dynamic id,
    dynamic orderId,
    String? title,
    String? content,
    String? type,
    DateTime? createdAt,
    bool? isRead,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      title: title ?? this.title,
      content: content ?? this.content,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
    );
  }
}
