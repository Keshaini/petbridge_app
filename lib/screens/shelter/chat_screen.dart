
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../models/report_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';

/// ============================================================================
/// SCREEN: DIRECT MESSAGE CHAT THREAD
/// File: lib/screens/shelter/chat_screen.dart
///
/// PetBridge - Report-specific Firestore Chat
/// ============================================================================

class DirectMessageChatScreen extends StatefulWidget {
  final String reportId;

  const DirectMessageChatScreen({
    super.key,
    required this.reportId,
  });

  @override
  State<DirectMessageChatScreen> createState() =>
      _DirectMessageChatScreenState();
}

class _DirectMessageChatScreenState
    extends State<DirectMessageChatScreen> {
  // ---------------------------------------------------------------------------
  // COLORS
  // ---------------------------------------------------------------------------

  static const Color _cream = Color(0xFFFFF9F6);
  static const Color _brown = Color(0xFF6F3F24);
  static const Color _darkBrown = Color(0xFF2C2420);
  static const Color _muted = Color(0xFF8D7F77);
  static const Color _lightBorder = Color(0xFFF3ECE6);
  static const Color _lightBubble = Color(0xFFFFF1E9);

  // ---------------------------------------------------------------------------
  // CONTROLLERS AND STATE
  // ---------------------------------------------------------------------------

  final TextEditingController _messageController =
      TextEditingController();

  final ScrollController _scrollController = ScrollController();

  ReportModel? _report;

  String _currentUid = '';
  String _otherUserUid = '';
  String _otherUserName = 'PetBridge User';

  bool _loading = true;
  bool _sending = false;

  String? _errorMessage;

  // ---------------------------------------------------------------------------
  // INITIALIZATION
  // ---------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    _loadChat();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // LOAD REPORT AND CHAT PARTICIPANT
  // ---------------------------------------------------------------------------

  Future<void> _loadChat() async {
    try {
      final uid = AuthService.currentUid;

      if (uid.isEmpty || uid == 'guest') {
        if (!mounted) return;

        setState(() {
          _loading = false;
          _errorMessage = 'Please log in to use chat.';
        });

        return;
      }

      // Get the report associated with this conversation.
      final report = await FirestoreService.getReport(
        widget.reportId,
      );

      if (report == null) {
        if (!mounted) return;

        setState(() {
          _loading = false;
          _errorMessage = 'This report could not be found.';
        });

        return;
      }

      // Determine the other participant.
      //
      // The report owner chats with the shelter that claimed the report.
      // The claiming shelter chats with the report owner.

      String otherUid;

      if (uid == report.ownerUid) {
        otherUid = report.claimedBy;
      } else if (uid == report.claimedBy) {
        otherUid = report.ownerUid;
      } else {
        if (!mounted) return;

        setState(() {
          _loading = false;
          _errorMessage =
              'You are not a participant in this conversation.';
        });

        return;
      }

      if (otherUid.isEmpty) {
        if (!mounted) return;

        setState(() {
          _report = report;
          _currentUid = uid;
          _loading = false;
          _errorMessage =
              'This report has not been claimed yet. Chat is not available.';
        });

        return;
      }

      // Load the other participant's profile.
      final userData = await FirestoreService.getUserProfile(
        otherUid,
      );

      final name = (userData?['name'] as String?)?.trim();

      if (!mounted) return;

      setState(() {
        _report = report;
        _currentUid = uid;
        _otherUserUid = otherUid;

        _otherUserName =
            name != null && name.isNotEmpty
                ? name
                : 'PetBridge User';

        _loading = false;
      });
    } catch (error) {
      debugPrint('Chat loading error: $error');

      if (!mounted) return;

      setState(() {
        _loading = false;
        _errorMessage =
            'Unable to load this conversation. Please try again.';
      });
    }
  }

  // ---------------------------------------------------------------------------
  // SEND MESSAGE
  // ---------------------------------------------------------------------------

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();

    if (message.isEmpty ||
        _sending ||
        _report == null ||
        _currentUid.isEmpty ||
        _otherUserUid.isEmpty) {
      return;
    }

    setState(() {
      _sending = true;
    });

    try {
      await FirestoreService.sendChatMessage(
        reportId: widget.reportId,
        senderId: _currentUid,
        text: message,
      );

      _messageController.clear();

      if (!mounted) return;

      // Scroll to the latest message.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (error) {
      debugPrint('Send message error: $error');

      if (!mounted) return;

      _showMessage(
        'Message could not be sent. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _sending = false;
        });
      }
    }
  }

  // ---------------------------------------------------------------------------
  // HELPERS
  // ---------------------------------------------------------------------------

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 2),
        ),
      );
  }

  String _formatMessageTime(DateTime dateTime) {
    final hour = dateTime.hour % 12 == 0
        ? 12
        : dateTime.hour % 12;

    final minute = dateTime.minute.toString().padLeft(2, '0');

    final period = dateTime.hour >= 12 ? 'PM' : 'AM';

    return '$hour:$minute $period';
  }

  String _shortReportId() {
    if (widget.reportId.length <= 6) {
      return widget.reportId;
    }

    return widget.reportId.substring(0, 6);
  }

  // ---------------------------------------------------------------------------
  // MORE OPTIONS
  // ---------------------------------------------------------------------------

  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5DCD5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 18),

                ListTile(
                  leading: const Icon(
                    Icons.person_outline_rounded,
                    color: _brown,
                  ),
                  title: const Text('View Contact'),
                  subtitle: Text(_otherUserName),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _showContactDetails();
                  },
                ),

                ListTile(
                  leading: const Icon(
                    Icons.info_outline_rounded,
                    color: _brown,
                  ),
                  title: const Text('View Report Details'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _showCaseDetails();
                  },
                ),

                ListTile(
                  leading: const Icon(
                    Icons.report_outlined,
                    color: Color(0xFFC73E1D),
                  ),
                  title: const Text('Report Conversation'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _showMessage(
                      'Please contact PetBridge support to report a conversation.',
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // CONTACT DETAILS
  // ---------------------------------------------------------------------------

  void _showContactDetails() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _cream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircleAvatar(
                  radius: 34,
                  backgroundColor: Color(0xFFF7DEB8),
                  child: Icon(
                    Icons.person_rounded,
                    size: 38,
                    color: Color(0xFF9E643E),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _otherUserName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: _darkBrown,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'PetBridge conversation participant',
                  style: TextStyle(
                    fontSize: 12,
                    color: _muted,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Report ID: ${widget.reportId}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 11,
                    color: _muted,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // REPORT DETAILS
  // ---------------------------------------------------------------------------

  void _showCaseDetails() {
    final report = _report;

    if (report == null) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: _cream,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFDE1CC),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.pets_rounded,
                        color: Color(0xFF8D5330),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${report.petName} · Case #${_shortReportId()}',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: _darkBrown,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                _buildInfoRow(
                  Icons.location_on_outlined,
                  'Location',
                  report.locationLabel.isNotEmpty
                      ? report.locationLabel
                      : 'Location not provided',
                ),

                _buildInfoRow(
                  Icons.pets_outlined,
                  'Animal',
                  '${report.animalType} · ${report.petName}',
                ),

                _buildInfoRow(
                  Icons.category_outlined,
                  'Category',
                  report.category,
                ),

                _buildInfoRow(
                  Icons.info_outline_rounded,
                  'Status',
                  report.status,
                ),

                _buildInfoRow(
                  Icons.person_outline_rounded,
                  'Contact',
                  _otherUserName,
                ),

                if (report.description.isNotEmpty)
                  _buildInfoRow(
                    Icons.description_outlined,
                    'Description',
                    report.description,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String title,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: const Color(0xFF8A5435),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: Color(0xFF9A8B82),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _darkBrown,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // LOADING / ERROR SCREEN
  // ---------------------------------------------------------------------------

  Widget _buildLoadingOrError() {
    final hasError = _errorMessage != null;

    return Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: _darkBrown,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Chat',
          style: TextStyle(
            color: _darkBrown,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!hasError)
                const CircularProgressIndicator(
                  color: _brown,
                )
              else
                const Icon(
                  Icons.chat_bubble_outline_rounded,
                  size: 48,
                  color: Color(0xFFB59A87),
                ),
              const SizedBox(height: 18),
              Text(
                hasError
                    ? _errorMessage!
                    : 'Loading conversation...',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: _muted,
                  height: 1.5,
                ),
              ),
              if (hasError) ...[
                const SizedBox(height: 18),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _loading = true;
                      _errorMessage = null;
                    });
                    _loadChat();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _brown,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Try Again'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // CHAT HEADER
  // ---------------------------------------------------------------------------

  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(68),
      child: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 8,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(
                color: _lightBorder,
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 20,
                  color: _darkBrown,
                ),
                onPressed: () => Navigator.pop(context),
              ),

              Stack(
                children: [
                  const CircleAvatar(
                    radius: 20,
                    backgroundColor: Color(0xFFF7DEB8),
                    child: Icon(
                      Icons.person_rounded,
                      size: 22,
                      color: Color(0xFF9E643E),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 11,
                      height: 11,
                      decoration: BoxDecoration(
                        color: const Color(0xFF388E3C),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(width: 10),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _otherUserName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _darkBrown,
                      ),
                    ),
                    Row(
                      children: const [
                        Icon(
                          Icons.verified,
                          size: 13,
                          color: Color(0xFF5A9372),
                        ),
                        SizedBox(width: 4),
                        Text(
                          'PetBridge participant',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF8A7D75),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              IconButton(
                icon: const Icon(
                  Icons.more_vert_rounded,
                  color: _darkBrown,
                  size: 22,
                ),
                onPressed: _showMoreOptions,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // REPORT CONTEXT CARD
  // ---------------------------------------------------------------------------

  Widget _buildReportCard() {
    final report = _report!;

    return GestureDetector(
      onTap: _showCaseDetails,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFFEEDDE),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFDE1CC),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.pets,
                size: 18,
                color: Color(0xFF8D5330),
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Regarding: ',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          color: _darkBrown,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          report.petName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            color: _darkBrown,
                          ),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFAD1B6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          report.animalType,
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '📍 ${report.locationLabel} · Case #${_shortReportId()}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: Color(0xFF7E6F67),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 6),

            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: Color(0xFF8D5330),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // OTHER PARTICIPANT CARD
  // ---------------------------------------------------------------------------

  Widget _buildParticipantCard() {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 4,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0E7),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 18,
            backgroundColor: Color(0xFFF7DEB8),
            child: Icon(
              Icons.person_rounded,
              size: 20,
              color: Color(0xFF9E643E),
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _otherUserName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: _darkBrown,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Conversation participant',
                  style: TextStyle(
                    fontSize: 10.5,
                    color: Color(0xFF8D7F77),
                  ),
                ),
              ],
            ),
          ),

          GestureDetector(
            onTap: _showContactDetails,
            child: const Icon(
              Icons.info_outline_rounded,
              color: Color(0xFF8D7F77),
              size: 19,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // FIRESTORE MESSAGES
  // ---------------------------------------------------------------------------

  Widget _buildMessagesFromFirestore() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirestoreService.getChatMessages(widget.reportId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(30),
              child: CircularProgressIndicator(
                color: _brown,
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(30),
              child: Text(
                'Unable to load messages.',
                style: TextStyle(
                  color: _muted,
                  fontSize: 13,
                ),
              ),
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return _buildEmptyMessages();
        }

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data();

            final senderId =
                data['senderId'] as String? ?? '';

            final messageText =
                data['text'] as String? ?? '';

            final timestamp =
                data['timestamp'] as Timestamp?;

            final isIncoming = senderId != _currentUid;

            final time = timestamp == null
                ? 'Sending...'
                : _formatMessageTime(timestamp.toDate());

            if (isIncoming) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _buildIncomingMessageWithAvatar(
                  messageText,
                  time,
                ),
              );
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _buildOutgoingMessage(
                messageText,
                time,
              ),
            );
          },
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // EMPTY CHAT
  // ---------------------------------------------------------------------------

  Widget _buildEmptyMessages() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 25,
          vertical: 35,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: const BoxDecoration(
                color: Color(0xFFFCEFE7),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chat_bubble_outline_rounded,
                color: Color(0xFF8A5435),
                size: 26,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'No messages yet',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF4C3E36),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'Start a conversation with $_otherUserName.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11.5,
                color: Color(0xFF9E8E84),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // INCOMING MESSAGE BUBBLE
  // ---------------------------------------------------------------------------

  Widget _buildIncomingMessageWithAvatar(
    String text,
    String time,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const CircleAvatar(
          radius: 14,
          backgroundColor: Color(0xFFF7DEB8),
          child: Icon(
            Icons.person_rounded,
            size: 16,
            color: Color(0xFF9E643E),
          ),
        ),

        const SizedBox(width: 8),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: _lightBubble,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  text,
                  style: const TextStyle(
                    fontSize: 13,
                    color: _darkBrown,
                    height: 1.4,
                  ),
                ),
              ),

              const SizedBox(height: 3),

              Text(
                time,
                style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFF9E8E84),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // OUTGOING MESSAGE BUBBLE
  // ---------------------------------------------------------------------------

  Widget _buildOutgoingMessage(
    String text,
    String time,
  ) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(left: 48),
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: _brown,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.white,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              time,
              style: const TextStyle(
                fontSize: 9.5,
                color: Color(0xFFEADDD5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // MESSAGE INPUT
  // ---------------------------------------------------------------------------

  Widget _buildMessageInput() {
    final canSend =
        !_sending && _otherUserUid.isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 10,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: _lightBorder,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            GestureDetector(
              onTap: () {
                _showMessage(
                  'Photo attachments are not available yet.',
                );
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFFCEFE7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.camera_alt_outlined,
                  color: Color(0xFF8A5435),
                  size: 20,
                ),
              ),
            ),

            const SizedBox(width: 8),

            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                ),
                constraints: const BoxConstraints(
                  minHeight: 44,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF9F5),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: const Color(0xFFEFE4DC),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        enabled: canSend,
                        textInputAction: TextInputAction.send,
                        minLines: 1,
                        maxLines: 4,
                        onSubmitted: (_) => _sendMessage(),
                        decoration: const InputDecoration(
                          hintText: 'Type a message...',
                          hintStyle: TextStyle(
                            fontSize: 13,
                            color: Color(0xFFB0A299),
                          ),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),

                    GestureDetector(
                      onTap: () {
                        _showMessage(
                          'Location sharing is not available yet.',
                        );
                      },
                      child: const Icon(
                        Icons.location_on_outlined,
                        color: Color(0xFF8A7D75),
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(width: 8),

            GestureDetector(
              onTap: canSend ? _sendMessage : null,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: canSend
                      ? _brown
                      : const Color(0xFFB8A69A),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: _sending
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    if (_loading || _errorMessage != null) {
      return _buildLoadingOrError();
    }

    return Scaffold(
      backgroundColor: _cream,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // Report information.
          _buildReportCard(),

          // Other participant.
          _buildParticipantCard(),

          // Messages from Firestore.
          Expanded(
            child: _buildMessagesFromFirestore(),
          ),

          // Message input.
          _buildMessageInput(),
        ],
      ),
    );
  }
}
