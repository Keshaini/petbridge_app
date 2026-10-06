class MessageModel {
  final String messageId;
  final String threadId;
  final String senderUid;
  final String text;
  final DateTime timestamp;

  MessageModel({
    required this.messageId,
    required this.threadId,
    required this.senderUid,
    required this.text,
    required this.timestamp,
  });

  factory MessageModel.fromMap(Map<String, dynamic> map, String id) {
    return MessageModel(
      messageId: id,
      threadId: map['threadId'] ?? '',
      senderUid: map['senderUid'] ?? '',
      text: map['text'] ?? '',
      timestamp: map['timestamp']?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'threadId': threadId,
      'senderUid': senderUid,
      'text': text,
      'timestamp': timestamp,
    };
  }
}