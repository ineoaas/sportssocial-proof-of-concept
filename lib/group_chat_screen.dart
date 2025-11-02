import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class GroupChatScreen extends StatefulWidget {
  final Map<String, dynamic> group;
  const GroupChatScreen({super.key, required this.group});

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final Color primaryPurple = const Color(0xFF4B0082);
  List<Map<String, String>> messages = [];

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'chat_${widget.group['id']}';
    final stored = prefs.getString(key);
    if (stored != null) {
      final decoded = json.decode(stored);
      if (!mounted) return;
      setState(() => messages = List<Map<String, String>>.from(decoded));
    }
  }

  Future<void> _saveMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'chat_${widget.group['id']}';
    prefs.setString(key, json.encode(messages));
  }

  void _send(String text) {
    if (text.trim().isEmpty) return;
    final msg = {
      'sender': 'me',
      'text': text.trim(),
      'time': DateTime.now().toIso8601String()
    };
    setState(() => messages.add(msg));
    _controller.clear();
    _saveMessages();

    Future.delayed(const Duration(milliseconds: 100), () {
      _scroll.jumpTo(_scroll.position.maxScrollExtent);
    });
  }

  Widget _bubble(Map<String, String> m) {
    final isMe = m['sender'] == 'me';
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isMe ? primaryPurple : Colors.grey.shade200,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(14),
            topRight: const Radius.circular(14),
            bottomLeft:
                isMe ? const Radius.circular(14) : const Radius.circular(0),
            bottomRight:
                isMe ? const Radius.circular(0) : const Radius.circular(14),
          ),
        ),
        child: Text(m['text'] ?? '',
            style: TextStyle(
                color: isMe ? Colors.white : Colors.black87, fontSize: 15)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final g = widget.group;
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.purple.shade200,
              child: const Icon(Icons.group, color: Colors.white),
            ),
            const SizedBox(width: 8),
            Text(g['name'] ?? 'Group Chat'),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              itemCount: messages.length,
              itemBuilder: (_, i) => _bubble(messages[i]),
            ),
          ),
          Container(
            color: Colors.grey.shade100,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        hintText: 'Type a message...',
                        border: InputBorder.none,
                      ),
                      onSubmitted: _send,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.send, color: primaryPurple),
                    onPressed: () => _send(_controller.text),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}