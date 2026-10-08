import 'package:flutter/material.dart';
import 'screens/shelter/chat_screen.dart';

void main() {
  runApp(const PetBridgeApp());
}

class PetBridgeApp extends StatelessWidget {
  const PetBridgeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PetBridge',
      home: const DirectMessageChatScreen(),
    );
  }
}