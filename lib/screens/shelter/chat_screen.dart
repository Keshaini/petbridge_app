import 'package:flutter/material.dart';

/// ============================================================================
/// SCREEN: DIRECT MESSAGE CHAT THREAD
/// File: lib/screens/shelter/chat_screen.dart
///
/// PetBridge - Shelter Chat
/// ============================================================================

class DirectMessageChatScreen extends StatefulWidget {
  const DirectMessageChatScreen({super.key});

  @override
  State<DirectMessageChatScreen> createState() =>
      _DirectMessageChatScreenState();
}

class _DirectMessageChatScreenState
    extends State<DirectMessageChatScreen> {
  final TextEditingController _messageController =
      TextEditingController();

  final ScrollController _scrollController = ScrollController();

  final List<Map<String, String>> _messages = [
    {
      'type': 'incoming',
      'text':
          'Hi Safa! I just spotted the tabby cat near the Pinecrest Community Garden fountain. He looks calm and has the white paws mentioned in your alert.',
      'time': '10:24 AM',
    },
    {
      'type': 'incoming',
      'text':
          'I took a quick photo and kept some distance so he wouldn\'t bolt. Is there a rescue volunteer nearby?',
      'time': '10:26 AM · Read',
    },
    {
      'type': 'outgoing',
      'text':
          'Thank you so much Anjali! Yes, Milo belongs to the Henderson family on 4th Ave. Our volunteer team is just 5 minutes away.',
      'time': '10:28 AM',
    },
    {
      'type': 'outgoing',
      'text':
          'Could you stay within sight of him if it\'s safe to do so?',
      'time': '10:28 AM',
    },
    {
      'type': 'incoming',
      'text':
          'Absolutely, I\'m watching him from the bench. He\'s resting near the hydrangeas. Take your time!',
      'time': '10:29 AM',
    },
  ];

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final message = _messageController.text.trim();

    if (message.isEmpty) {
      return;
    }

    setState(() {
      _messages.add({
        'type': 'outgoing',
        'text': message,
        'time': 'Now · Sent ✓',
      });
    });

    _messageController.clear();

    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

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

  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (context) {
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
                    color: Color(0xFF6F3F24),
                  ),
                  title: const Text('View Contact'),
                  onTap: () {
                    Navigator.pop(context);
                    _showMessage('Opening Anjali\'s profile...');
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.notifications_off_outlined,
                    color: Color(0xFF6F3F24),
                  ),
                  title: const Text('Mute Conversation'),
                  onTap: () {
                    Navigator.pop(context);
                    _showMessage('Conversation muted');
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.report_outlined,
                    color: Color(0xFFC73E1D),
                  ),
                  title: const Text('Report Conversation'),
                  onTap: () {
                    Navigator.pop(context);
                    _showMessage('Report option selected');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showCaseDetails() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFFFF9F6),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (context) {
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
                    const Expanded(
                      child: Text(
                        'Milo — Case #4028',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF2C2420),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _buildInfoRow(
                  Icons.location_on_outlined,
                  'Location',
                  'Pinecrest Gardens',
                ),
                _buildInfoRow(
                  Icons.pets_outlined,
                  'Animal',
                  'Tabby Cat · Milo',
                ),
                _buildInfoRow(
                  Icons.person_outline_rounded,
                  'Coordinator',
                  'Anjali P.',
                ),
                _buildInfoRow(
                  Icons.groups_outlined,
                  'Status',
                  'Rescue Team En Route',
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
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
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
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2C2420),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF9F6),

      // =====================================================================
      // TOP APP BAR
      // =====================================================================
      appBar: PreferredSize(
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
                  color: Color(0xFFF3ECE6),
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
                    color: Color(0xFF2C2420),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),

                Stack(
                  children: [
                    const CircleAvatar(
                      radius: 20,
                      backgroundColor: Color(0xFFF7DEB8),
                      child: Icon(
                        Icons.pets_rounded,
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
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Direct Message Thread',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2C2420),
                        ),
                        overflow: TextOverflow.ellipsis,
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
                            'Active Shelter Rep',
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
                    Icons.phone_outlined,
                    color: Color(0xFF2C2420),
                    size: 22,
                  ),
                  onPressed: () {
                    _showMessage('Calling shelter representative...');
                  },
                ),

                IconButton(
                  icon: const Icon(
                    Icons.more_vert_rounded,
                    color: Color(0xFF2C2420),
                    size: 22,
                  ),
                  onPressed: _showMoreOptions,
                ),

                const CircleAvatar(
                  radius: 17,
                  backgroundColor: Color(0xFFF7DEB8),
                  child: Icon(
                    Icons.person_rounded,
                    size: 19,
                    color: Color(0xFF9E643E),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),

      // =====================================================================
      // BODY
      // =====================================================================
      body: Column(
        children: [
          // -----------------------------------------------------------------
          // CASE CONTEXT
          // -----------------------------------------------------------------
          GestureDetector(
            onTap: _showCaseDetails,
            child: Container(
              margin: const EdgeInsets.fromLTRB(
                16,
                12,
                16,
                8,
              ),
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
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Regarding: ',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: Color(0xFF2C2420),
                              ),
                            ),
                            const Text(
                              'Milo ',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                                color: Color(0xFF2C2420),
                              ),
                            ),
                            Container(
                              padding:
                                  const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFAD1B6),
                                borderRadius:
                                    BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Tabby Cat',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          '📍 Pinecrest Gardens · Case #4028',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF7E6F67),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: Color(0xFF8D5330),
                  ),
                ],
              ),
            ),
          ),

          // -----------------------------------------------------------------
          // VOLUNTEER INFO
          // -----------------------------------------------------------------
          Container(
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
                Stack(
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
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2E7D32),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Anjali P.',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding:
                                const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD6F0E0),
                              borderRadius:
                                  BorderRadius.circular(6),
                            ),
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.check,
                                  size: 10,
                                  color: Color(0xFF2E7D32),
                                ),
                                SizedBox(width: 2),
                                Text(
                                  'Verified',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2E7D32),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        '• Active Rescuer · Sighting Coordinator',
                        style: TextStyle(
                          fontSize: 10.5,
                          color: Color(0xFF8D7F77),
                        ),
                      ),
                    ],
                  ),
                ),

                GestureDetector(
                  onTap: () {
                    _showMessage(
                      'Anjali P. · Verified Rescuer',
                    );
                  },
                  child: const Icon(
                    Icons.info_outline_rounded,
                    color: Color(0xFF8D7F77),
                    size: 18,
                  ),
                ),
              ],
            ),
          ),

          // -----------------------------------------------------------------
          // CHAT MESSAGES
          // -----------------------------------------------------------------
          Expanded(
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              children: [
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFBECE2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Text(
                      'Today, 10:24 AM',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF82736B),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                ..._buildMessages(),

                const SizedBox(height: 14),

                // Rescue status
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD6F0E0),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF2E7D32),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Rescue Team En Route · ETA 3 mins',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E5D2A),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),

          // -----------------------------------------------------------------
          // MESSAGE INPUT
          // -----------------------------------------------------------------
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 10,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(
                  color: Color(0xFFF3ECE6),
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
                        'Camera attachment selected',
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
                              textInputAction:
                                  TextInputAction.send,
                              onSubmitted: (_) =>
                                  _sendMessage(),
                              decoration:
                                  const InputDecoration(
                                hintText:
                                    'Type a message...',
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
                                'Location sharing selected',
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
                    onTap: _sendMessage,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFF6F3F24),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildMessages() {
    final List<Widget> widgets = [];

    for (int i = 0; i < _messages.length; i++) {
      final message = _messages[i];
      final isIncoming = message['type'] == 'incoming';
      final text = message['text'] ?? '';
      final time = message['time'] ?? '';

      if (isIncoming) {
        widgets.add(
          _buildIncomingMessageWithAvatar(
            text,
            time,
          ),
        );
      } else {
        widgets.add(
          _buildOutgoingMessage(
            text,
            time,
          ),
        );
      }

      widgets.add(const SizedBox(height: 10));

      // Add sighting photo after Anjali's second message
      if (i == 1) {
        widgets.add(
          _buildSightingPhoto(),
        );
        widgets.add(const SizedBox(height: 4));
      }
    }

    return widgets;
  }

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
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1E9),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  text,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF2C2420),
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
          color: const Color(0xFF6F3F24),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.end,
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

  Widget _buildSightingPhoto() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(left: 36),
        width: 240,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(
                top: Radius.circular(18),
              ),
              child: Container(
                height: 140,
                width: double.infinity,
                color: const Color(0xFFF1E8DF),
                child: Stack(
                  children: [
                    const Center(
                      child: Icon(
                        Icons.pets_rounded,
                        size: 52,
                        color: Color(0xFFB59A87),
                      ),
                    ),
                    Positioned(
                      bottom: 8,
                      left: 8,
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black
                              .withOpacity(0.6),
                          borderRadius:
                              BorderRadius.circular(8),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.photo_camera,
                              size: 11,
                              color: Colors.white,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Sighting Photo',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight:
                                    FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const Padding(
              padding: EdgeInsets.all(10),
              child: Text(
                'Hydrangea hedge, west garden gate',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF4C3E36),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}