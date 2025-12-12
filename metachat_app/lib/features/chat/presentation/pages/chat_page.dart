import 'package:flutter/material.dart';

import 'package:metachat_app/shared/widgets/glass_app_bar.dart';
import 'package:metachat_app/shared/widgets/glass_card.dart';
import 'package:metachat_app/shared/widgets/glass_text_field.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final messages = <String>[];
  final controller = TextEditingController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void send() {
    if (!mounted) return;
    final text = controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      messages.add(text);
      controller.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GlassAppBar(
        title: 'Чат',
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              reverse: true,
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final text = messages[messages.length - 1 - index];
                return Align(
                  alignment: Alignment.centerRight,
                  child: GlassCard(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    child: Text(
                      text,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: GlassTextField(
                    controller: controller,
                    hint: 'Сообщение',
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: send,
                  icon: const Icon(
                    Icons.send,
                    color: Color(0xFF7DD3FC),
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


