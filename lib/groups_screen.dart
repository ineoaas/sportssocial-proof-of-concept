import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'group_chat_screen.dart';

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  final Color primaryPurple = const Color(0xFF4B0082);
  List<Map<String, dynamic>> groups = [];
  final List<String> fakeUsers = ['Alex', 'Sam', 'Jordan', 'Taylor', 'Morgan'];

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  Future<void> _loadGroups() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString('groups');
    if (stored != null) {
      try {
        setState(() {
          groups = List<Map<String, dynamic>>.from(json.decode(stored));
        });
      } catch (_) {
        setState(() => groups = []);
      }
    }
  }

  Future<void> _saveGroups() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('groups', json.encode(groups));
  }

  // ---------------- Create Group Overlay ----------------
  void _openCreateGroupOverlay() {
    final TextEditingController nameController = TextEditingController();
    int selectedAvatar = 0;
    final Set<String> invited = {};

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(builder: (context, setModalState) {
          // ignore: unused_element
          void toggleInvite(String user) {
            setModalState(() {
              if (invited.contains(user)) {
                invited.remove(user);
              } else {
                invited.add(user);
              }
            });
          }

          // helper to open the multi-select sheet
          Future<void> openInvitePicker() async {
            final result = await showModalBottomSheet<Set<String>>(
              context: ctx,
              isScrollControlled: true,
              backgroundColor: Colors.white,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              builder: (ctx2) {
                final temp = Set<String>.from(invited);
                return StatefulBuilder(builder: (ctx3, setState3) {
                  return Padding(
                    padding: EdgeInsets.only(
                      left: 16,
                      right: 16,
                      top: 12,
                      bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Expanded(child: Text('Invite people', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryPurple))),
                            TextButton(onPressed: () => Navigator.pop(ctx2, null), child: const Text('Close')),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ...fakeUsers.map((u) {
                          final sel = temp.contains(u);
                          return CheckboxListTile(
                            value: sel,
                            onChanged: (v) => setState3(() => v == true ? temp.add(u) : temp.remove(u)),
                            title: Text(u),
                            controlAffinity: ListTileControlAffinity.leading,
                          );
                        }),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(ctx2, null),
                                child: const Text('Cancel'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: primaryPurple),
                                onPressed: () => Navigator.pop(ctx2, temp),
                                child: const Text('Save'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  );
                });
              },
            );

            if (result != null) {
              setModalState(() {
                invited
                  ..clear()
                  ..addAll(result);
              });
            }
          }

          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Create Group',
                    style: TextStyle(
                        color: primaryPurple,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Group name'),
                ),
                const SizedBox(height: 12),
                Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Choose avatar',
                        style: TextStyle(color: Colors.grey.shade700))),
                const SizedBox(height: 8),
                SizedBox(
                  height: 72,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: 6,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, i) {
                      final isSelected = i == selectedAvatar;
                      final bg = [
                        Colors.purple.shade200,
                        Colors.green.shade200,
                        Colors.orange.shade200,
                        Colors.blue.shade200,
                        Colors.pink.shade200,
                        Colors.teal.shade200
                      ][i % 6];
                      return GestureDetector(
                        onTap: () => setModalState(() => selectedAvatar = i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: isSelected
                                ? Border.all(color: primaryPurple, width: 2)
                                : null,
                          ),
                          child: CircleAvatar(
                            radius: 24,
                            backgroundColor: bg,
                            child:
                                const Icon(Icons.group, color: Colors.white),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Invite people',
                        style: TextStyle(color: Colors.grey.shade700))),
                const SizedBox(height: 8),
                // Dropdown-style invite field
                GestureDetector(
                  onTap: openInvitePicker,
                  child: InputDecorator(
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            invited.isEmpty ? 'Select people to invite' : invited.join(', '),
                            style: TextStyle(color: invited.isEmpty ? Colors.grey.shade500 : Colors.black),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Icon(Icons.arrow_drop_down),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                            foregroundColor: primaryPurple),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          final name = nameController.text.trim();
                          if (name.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text('Please enter a group name')),
                            );
                            return;
                          }

                          final group = {
                            'id': DateTime.now()
                                .millisecondsSinceEpoch
                                .toString(),
                            'name': name,
                            'avatar': selectedAvatar,
                            'creator': 'me',
                            'members': ['me', ...invited],
                            'created': DateTime.now().toIso8601String(),
                          };

                          setState(() => groups.insert(0, group));
                          _saveGroups();
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text('Group "$name" created'),
                              backgroundColor: primaryPurple));
                        },
                        style: ElevatedButton.styleFrom(
                            backgroundColor: primaryPurple),
                        child: const Text('Create', style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        });
      },
    );
  }

  Future<void> _deleteGroup(int index) async {
    final g = groups[index];
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete group?'),
        content:
            Text('Delete the group "${g['name']}"? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: primaryPurple),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      if (!mounted) return;
      setState(() => groups.removeAt(index));
      _saveGroups();
    }
  }

  Widget _buildGroupCard(Map<String, dynamic> g, int index) {
    final members = List<String>.from(g['members'] ?? []);
    final isCreator = g['creator'] == 'me';
    final avatarIndex = g['avatar'] ?? 0;
    final bg = [
      Colors.purple.shade200,
      Colors.green.shade200,
      Colors.orange.shade200,
      Colors.blue.shade200,
      Colors.pink.shade200,
      Colors.teal.shade200
    ][avatarIndex % 6];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.05 * 255).round()),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => GroupChatScreen(group: g)),
          ),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Hero(
                  tag: 'group-${g['id']}',
                  child: CircleAvatar(
                    radius: 28,
                    backgroundColor: bg,
                    child: const Icon(Icons.group, color: Colors.white, size: 24),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        g['name'] ?? '',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: primaryPurple.withAlpha((0.1 * 255).round()),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${members.length} member${members.length == 1 ? '' : 's'}',
                          style: TextStyle(
                            color: primaryPurple,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (isCreator)
                  IconButton(
                    onPressed: () => _deleteGroup(index),
                    icon: const Icon(Icons.delete_outline),
                    color: Colors.red,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Groups')),
      body: groups.isEmpty
          ? Center(
              child:
                  Text('No groups yet', style: TextStyle(color: primaryPurple)))
          : ListView.builder(
              itemCount: groups.length,
              itemBuilder: (_, i) => _buildGroupCard(groups[i], i)),
      floatingActionButton: FloatingActionButton(
        backgroundColor: primaryPurple,
        onPressed: _openCreateGroupOverlay,
        child: const Icon(Icons.add, color: Colors.white),
        
      ),
    );
  }
}