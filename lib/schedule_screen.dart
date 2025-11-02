import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  List<Map<String, dynamic>> joinedActivities = [];
  final Color primaryPurple = const Color(0xFF4B0082);

  @override
  void initState() {
    super.initState();
    _loadJoinedActivities();
  }

  Future<void> _loadJoinedActivities() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString('joined_activities');
    if (stored != null) {
      final decoded = json.decode(stored);
      if (decoded is List) {
        if (!mounted) return;
        setState(() {
          joinedActivities = List<Map<String, dynamic>>.from(decoded);
        });
      }
    }
  }

  Future<void> _saveJoinedActivities() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('joined_activities', json.encode(joinedActivities));
  }

  bool _isPastActivity(Map<String, dynamic> activity) {
    try {
      final dateStr = activity['date'] ?? '';
      if (dateStr.isEmpty) return false;
      final date = DateTime.parse(dateStr);
      return date.isBefore(DateTime.now());
    } catch (_) {
      return false;
    }
  }

  void _leaveActivity(int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Are you sure?'),
        content: const Text('Do you want to leave this activity?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: primaryPurple),
            child: const Text('Leave'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (!mounted) return;
      setState(() => joinedActivities.removeAt(index));
      _saveJoinedActivities();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('You left the activity'), backgroundColor: primaryPurple),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Schedule'),
        backgroundColor: Colors.white,
        foregroundColor: primaryPurple,
        elevation: 0.5,
      ),
      body: joinedActivities.isEmpty
          ? Center(
              child: Text(
                'You haven’t joined any activities yet.',
                style: TextStyle(color: primaryPurple),
              ),
            )
          : ListView.builder(
              itemCount: joinedActivities.length,
              itemBuilder: (context, index) {
                final activity = joinedActivities[index];
                final sport = activity['sport'] ?? '';
                final desc = activity['description'] ?? '';
                final date = activity['date'] ?? '';
                final time = activity['time'] ?? '';
                final isPast = _isPastActivity(activity);

                return Opacity(
                  opacity: isPast ? 0.5 : 1,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onLongPress: () => _leaveActivity(index),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: primaryPurple.withAlpha((0.1 * 255).round()),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.sports,
                                  color: primaryPurple,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      sport.isEmpty ? 'Untitled' : sport,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (desc.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        desc,
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(Icons.calendar_today,
                                            size: 14, color: Colors.grey.shade600),
                                        const SizedBox(width: 4),
                                        Text(
                                          date,
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Icon(Icons.access_time,
                                            size: 14, color: Colors.grey.shade600),
                                        const SizedBox(width: 4),
                                        Text(
                                          time,
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}