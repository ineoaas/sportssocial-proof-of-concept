import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AnnouncementsScreen extends StatefulWidget {
  const AnnouncementsScreen({super.key});

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen> {
  final Color primaryPurple = const Color(0xFF4B0082);
  final TextEditingController titleCtrl = TextEditingController();
  final TextEditingController textCtrl = TextEditingController();

  // Simple list of sports for the dropdown
  final List<String> _sports = [
    'Soccer',
    'Basketball',
    'Tennis',
    'Running',
    'Volleyball',
    'Softball',
    'Cycling',
    'Swimming',
    'Gym',
    'Other'
  ];
  String? _chosenSport;
  final TextEditingController _customSportCtrl = TextEditingController();

  List<Map<String, String>> posts = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('posts');
    if (data != null) {
      try {
        final decoded = json.decode(data);
        if (decoded is List) {
          if (!mounted) return;
          setState(() {
            posts = decoded
                .map((e) => {
                      't': (e['t'] ?? '').toString(),
                      'c': (e['c'] ?? '').toString(),
                    })
                .toList();
          });
        }
      } catch (e) {
        debugPrint('Error loading posts: $e');
        if (!mounted) return;
        setState(() => posts = []);
      }
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('posts', json.encode(posts));
  }

  void _add() {
    final content = textCtrl.text.trim();
    final sport = _chosenSport == 'Other' ? _customSportCtrl.text.trim() : (_chosenSport ?? '').trim();
    
    if (sport.isEmpty || content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a sport and add content'))
      );
      return;
    }

    setState(() {
      posts.insert(0, {'t': sport, 'c': content});
    });
    _save();

    textCtrl.clear();
    _chosenSport = null;
    _customSportCtrl.clear();
    Navigator.pop(context);
  }

  void _delete(int index) {
    setState(() => posts.removeAt(index));
    _save();
  }

  void _newPost() {
    showModalBottomSheet(
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      context: context,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Create Announcement',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: primaryPurple,
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Sport',
                border: OutlineInputBorder(),
              ),
              items: _sports.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              initialValue: _chosenSport,
              onChanged: (v) => setState(() => _chosenSport = v),
            ),
            if (_chosenSport == 'Other')
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: TextField(
                  controller: _customSportCtrl,
                  decoration: const InputDecoration(labelText: 'Custom sport'),
                ),
              ),

            TextField(
              controller: textCtrl,
              decoration: InputDecoration(
                labelText: 'Content',
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: primaryPurple),
                ),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primaryPurple,
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _add,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryPurple,
                    ),
                    child: const Text('Post', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Announcements'),
        backgroundColor: Colors.white,
        foregroundColor: primaryPurple,
        elevation: 0.5,
      ),
      body: posts.isEmpty
          ? Center(
              child: Text(
                'No announcements yet',
                style: TextStyle(color: primaryPurple),
              ),
            )
          : ListView.builder(
              itemCount: posts.length,
              itemBuilder: (_, i) {
                final post = posts[i];
                return Dismissible(
                  key: ValueKey((post['t'] ?? '') + (post['c'] ?? '') + i.toString()),
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  direction: DismissDirection.endToStart,
                  confirmDismiss: (direction) async {
                    return await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Delete announcement?'),
                        content: const Text('This announcement will be deleted.'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: primaryPurple),
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Delete', style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    );
                  },
                  onDismissed: (_) => _delete(i),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        top: BorderSide(color: Colors.grey.shade200),
                        bottom: BorderSide(color: Colors.grey.shade200),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: primaryPurple,
                                radius: 20,
                                child: const Icon(Icons.sports, color: Colors.white, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      post['t'] ?? '',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                    Text(
                                      'Just now', // You can add actual timestamp later
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        if ((post['c'] ?? '').isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                            child: Text(
                              post['c'] ?? '',
                              style: const TextStyle(fontSize: 15),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: primaryPurple,
        onPressed: _newPost,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  @override
  void dispose() {
    titleCtrl.dispose();
    textCtrl.dispose();
    _customSportCtrl.dispose();
    super.dispose();
  }
}
