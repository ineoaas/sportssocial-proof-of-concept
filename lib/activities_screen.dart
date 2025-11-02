import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'schedule_screen.dart';

class ActivitiesScreen extends StatefulWidget {
  const ActivitiesScreen({super.key});

  @override
  State<ActivitiesScreen> createState() => _ActivitiesScreenState();
}

class _ActivitiesScreenState extends State<ActivitiesScreen> {
  final Color primaryPurple = const Color(0xFF4B0082);
  List<Map<String, dynamic>> activities = [];
  List<Map<String, dynamic>> joinedActivities = [];
  // UI state for create tab and search
  final TextEditingController _searchCtrl = TextEditingController();
  final TextEditingController _customSportCtrl = TextEditingController();
  final TextEditingController _descCtrl = TextEditingController();
  DateTime? _selectedDate;
  DateTime? _selectedTime; // time portion stored here
  String _searchQuery = '';
  String? _chosenSport;
  // Predetermined sports with icons for a nicer dropdown
  final Map<String, IconData> _sportsMap = {
    'Soccer': Icons.sports_soccer,
    'Basketball': Icons.sports_basketball,
    'Tennis': Icons.sports_tennis,
    'Running': Icons.directions_run,
    'Volleyball': Icons.sports_volleyball,
    'Softball': Icons.sports_baseball,
    'Cycling': Icons.directions_bike,
    'Swimming': Icons.pool,
    'Gym': Icons.fitness_center,
    'Other': Icons.add,
  };

  // Fake users to invite (can be changed later)
  final List<String> _fakeUsers = ['Alex', 'Sam', 'Jordan', 'Taylor', 'Morgan', 'Casey'];
  final Set<String> _invited = {};

  // Selected location (map picker)
  Map<String, dynamic>? _selectedLocation;

  // Hardcoded sports halls in Eindhoven (static sample)
  final List<Map<String, dynamic>> _sportsHalls = [
    {'name': 'Philips Sportpark (Indoor)', 'lat': 51.4416, 'lng': 5.4710},
    {'name': 'Indoor Sports Center Tongelre', 'lat': 51.4578, 'lng': 5.4765},
    {'name': 'Sporthal Strijp', 'lat': 51.4372, 'lng': 5.4807},
    {'name': 'Sportpark Wichterheide', 'lat': 51.4360, 'lng': 5.4640},
    {'name': 'Topsportcentrum Eindhoven', 'lat': 51.4335, 'lng': 5.4780},
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchCtrl.addListener(() {
      setState(() => _searchQuery = _searchCtrl.text.trim());
    });
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();

    final all = prefs.getString('activities');
    final joined = prefs.getString('joined_activities');

    if (all != null) {
      try {
        final decoded = json.decode(all);
        if (decoded is List) {
          if (!mounted) return;
          setState(() => activities = List<Map<String, dynamic>>.from(decoded));
        }
      } catch (_) {
        // ignore malformed saved data
      }
    }
    if (joined != null) {
      try {
        final decoded = json.decode(joined);
        if (decoded is List) {
          if (!mounted) return;
          setState(() => joinedActivities = List<Map<String, dynamic>>.from(decoded));
        }
      } catch (_) {}
    }
  }

  Future<void> _saveActivities() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('activities', json.encode(activities));
  }

  Future<void> _saveJoinedActivities() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('joined_activities', json.encode(joinedActivities));
  }

  Future<void> _deleteActivityById(String id) async {
    setState(() {
      activities.removeWhere((a) => a['id'] == id);
      joinedActivities.removeWhere((a) => a['id'] == id);
    });
    await _saveActivities();
    await _saveJoinedActivities();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: const Text('Activity deleted'), backgroundColor: primaryPurple),
    );
  }

  bool _isJoined(Map<String, dynamic> activity) {
    return joinedActivities.any((a) => a['id'] == activity['id']);
  }

  void _toggleJoin(Map<String, dynamic> activity) async {
    final isJoined = _isJoined(activity);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isJoined ? 'Leave Activity?' : 'Join Activity?'),
        content: Text(isJoined
            ? 'Do you want to leave "${activity['sport']}"?'
            : 'Do you want to join "${activity['sport']}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: primaryPurple),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(isJoined ? 'Leave' : 'Join'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (!mounted) return;
      setState(() {
        if (isJoined) {
          joinedActivities.removeWhere((a) => a['id'] == activity['id']);
        } else {
          joinedActivities.add(activity);
        }
      });
      _saveJoinedActivities();
    }
  }

  // _createActivity was removed; creation now happens in the Create tab UI.

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) {
      if (!mounted) return;
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime() async {
    DateTime initial = _selectedTime ?? DateTime.now();
    DateTime temp = initial;
    await showCupertinoModalPopup(
      context: context,
      builder: (ctx) => Container(
        height: 260,
        color: Colors.white,
        child: Column(
          children: [
            SizedBox(
              height: 200,
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.time,
                initialDateTime: initial,
                use24hFormat: false,
                onDateTimeChanged: (dt) => temp = dt,
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('Cancel'),
                  ),
                ),
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      setState(() => _selectedTime = temp);
                      Navigator.of(ctx).pop();
                    },
                    child: const Text('Done'),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  String _formatTime(DateTime d) => '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  String _formatTimeOfDay(String time) {
    try {
      final parts = time.split(':');
      if (parts.length != 2) return time;
      
      final hour = int.parse(parts[0]);
      final minute = parts[1];
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      
      return '$displayHour:$minute $period';
    } catch (_) {
      return time;
    }
  }

  void _handleCreateSubmit() {
    final sport = (_chosenSport == 'Other') ? _customSportCtrl.text.trim() : (_chosenSport ?? '').trim();
    final desc = _descCtrl.text.trim();
    final date = _selectedDate != null ? _formatDate(_selectedDate!) : '';
    final time = _selectedTime != null ? _formatTime(_selectedTime!) : '';

    if (sport.isEmpty || date.isEmpty) {
      // require at least sport and date
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a sport and date')));
      return;
    }

    final newActivity = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'sport': sport,
      'description': desc,
      'date': date,
      'time': time,
      'invited': _invited.toList(),
      'location': _selectedLocation,
    };

    setState(() {
      activities.insert(0, newActivity);
      // reset fields
      _chosenSport = null;
      _customSportCtrl.clear();
      _descCtrl.clear();
      _selectedDate = null;
      _selectedTime = null;
      _invited.clear();
      _selectedLocation = null;
    });
    _saveActivities();

  // switch back to join tab
  DefaultTabController.of(context).animateTo(0);
  }

  Future<void> _openMapPicker() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final center = LatLng(51.4416, 5.4697); // Eindhoven center
        return SizedBox(
          height: MediaQuery.of(ctx).size.height * 0.75,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Pick a location', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryPurple)),
                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))
                  ],
                ),
              ),
              Expanded(
                child: FlutterMap(
                  options: MapOptions(center: center, zoom: 13),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                      subdomains: const ['a', 'b', 'c'],
                    ),
                    MarkerLayer(
                      markers: _sportsHalls.map((h) {
                        final lat = h['lat'] as double;
                        final lng = h['lng'] as double;
                        return Marker(
                          point: LatLng(lat, lng),
                          width: 40,
                          height: 40,
                          builder: (ctx) => GestureDetector(
                            onTap: () => Navigator.pop(ctx, h),
                            // Only show a simple point/icon to keep the map clean
                            child: Icon(Icons.location_on, color: primaryPurple, size: 28),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );

    if (result != null) {
      if (!mounted) return;
      setState(() => _selectedLocation = result);
    }
  }

  Future<void> _openInvitePicker() async {
    final result = await showModalBottomSheet<Set<String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final temp = Set<String>.from(_invited);
        return StatefulBuilder(builder: (ctx2, setState2) {
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
                    TextButton(onPressed: () => Navigator.pop(ctx, null), child: const Text('Close')),
                  ],
                ),
                const SizedBox(height: 8),
                ..._fakeUsers.map((u) {
                  final selected = temp.contains(u);
                  return CheckboxListTile(
                    value: selected,
                    onChanged: (v) => setState2(() => v == true ? temp.add(u) : temp.remove(u)),
                    title: Text(u),
                    controlAffinity: ListTileControlAffinity.leading,
                  );
                }),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx, null),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: primaryPurple),
                        onPressed: () => Navigator.pop(ctx, temp),
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
      if (!mounted) return;
      setState(() {
        _invited
          ..clear()
          ..addAll(result);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _searchQuery.isEmpty
        ? activities
        : activities.where((a) => (a['sport'] ?? '').toString().toLowerCase().contains(_searchQuery.toLowerCase())).toList();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Activities'),
          backgroundColor: Colors.white,
          foregroundColor: primaryPurple,
          elevation: 0.5,
          actions: [
            IconButton(
              icon: const Icon(Icons.schedule),
              tooltip: 'My Schedule',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ScheduleScreen()),
              ),
            ),
          ],
          bottom: TabBar(
            labelColor: primaryPurple,
            indicatorColor: primaryPurple,
            tabs: const [Tab(text: 'Find'), Tab(text: 'Create')],
          ),
        ),
        body: TabBarView(
          children: [
            // Find / Join Tab
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      hintText: 'Search activities by sport',
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () => _searchCtrl.clear(),
                            )
                          : null,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                Expanded(
                  child: filtered.isEmpty
                      ? Center(child: Text('No activities', style: TextStyle(color: primaryPurple)))
                      : ListView.builder(
                          itemCount: filtered.length,
                          itemBuilder: (_, i) {
                            final a = filtered[i];
                            final joined = _isJoined(a);
                            return Dismissible(
                              key: ValueKey(a['id'] ?? i.toString()),
                              direction: DismissDirection.endToStart,
                              confirmDismiss: (direction) async {
                                return await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Delete activity?'),
                                    content: Text('Delete "${a['sport']}" activity? This cannot be undone.'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(backgroundColor: primaryPurple),
                                        onPressed: () => Navigator.pop(ctx, true),
                                        child: const Text('Delete'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              onDismissed: (_) {
                                final id = a['id']?.toString() ?? i.toString();
                                _deleteActivityById(id);
                              },
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20),
                                color: Colors.red,
                                child: const Icon(Icons.delete, color: Colors.white),
                              ),
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
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    // Header with sport icon and join button
                                    Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Row(
                                        children: [
                                          CircleAvatar(
                                            backgroundColor: primaryPurple,
                                            child: Icon(_sportsMap[a['sport']] ?? Icons.sports,
                                                color: Colors.white, size: 20),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  a['sport'] ?? '',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    color: primaryPurple,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                                const SizedBox(height: 6),
                                                Row(
                                                  children: [
                                                    Icon(Icons.calendar_today,
                                                        size: 12, color: Colors.grey.shade600),
                                                    const SizedBox(width: 6),
                                                          Expanded(
                                                            child: Text(
                                                              '${a['date']} • ${_formatTimeOfDay(a['time'] ?? '')}',
                                                              style: TextStyle(
                                                                  color: Colors.grey.shade600,
                                                                  fontSize: 12),
                                                              overflow: TextOverflow.ellipsis,
                                                            ),
                                                          ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          TextButton(
                                            onPressed: () => _toggleJoin(a),
                                            style: TextButton.styleFrom(
                                              backgroundColor:
                                                  joined ? Colors.red.withAlpha((0.08 * 255).round()) : primaryPurple.withAlpha((0.08 * 255).round()),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(20),
                                              ),
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 16, vertical: 8),
                                            ),
                                            child: Text(
                                              joined ? 'Leave' : 'Join',
                                              style: TextStyle(
                                                color: joined ? Colors.red : primaryPurple,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Description if any
                                    if ((a['description'] ?? '').isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                                        child: Text(
                                          a['description'] ?? '',
                                          style: TextStyle(fontSize: 14, color: Colors.grey.shade800),
                                        ),
                                      ),
                                    // location (defensively handle non-Map types)
                                    Builder(builder: (context) {
                                      final loc = a['location'];
                                      final hasName = loc is Map && loc['name'] != null;
                                      if (!hasName) return const SizedBox.shrink();
                                      return Padding(
                                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                                        child: Row(
                                          children: [
                                            Icon(Icons.place, size: 14, color: Colors.grey.shade600),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                (loc['name'] ?? '').toString(),
                                                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),

            // Create Tab
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Create Activity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryPurple)),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Sport',
                      prefixIcon: Icon(_chosenSport != null ? _sportsMap[_chosenSport] : Icons.sports),
                    ),
                    items: _sportsMap.entries
                        .map((e) => DropdownMenuItem(
                              value: e.key,
                              child: Row(
                                children: [Icon(e.value, size: 18), const SizedBox(width: 8), Text(e.key)],
                              ),
                            ))
                        .toList(),
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
                  const SizedBox(height: 8),
                  TextField(
                    controller: _descCtrl,
                    decoration: const InputDecoration(labelText: 'Description'),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                  // Invite people (dropdown-style picker)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Invite people', style: TextStyle(color: Colors.grey.shade700)),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _openInvitePicker,
                    child: InputDecorator(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _invited.isEmpty ? 'Select people to invite' : _invited.join(', '),
                              style: TextStyle(color: _invited.isEmpty ? Colors.grey.shade500 : Colors.black),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Icon(Icons.arrow_drop_down),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Location picker
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Location', style: TextStyle(color: Colors.grey.shade700)),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _openMapPicker,
                          child: Text(_selectedLocation == null ? 'Pick location (optional)' : (_selectedLocation!['name'] ?? 'Selected')),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _pickDate,
                          child: Text(_selectedDate == null ? 'Pick date' : _formatDate(_selectedDate!)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _pickTime,
                          child: Text(_selectedTime == null ? 'Pick time' : _formatTime(_selectedTime!)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const SizedBox(height: 8),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            // reset create form
                            setState(() {
                              _chosenSport = null;
                              _customSportCtrl.clear();
                              _descCtrl.clear();
                              _selectedDate = null;
                              _selectedTime = null;
                            });
                          },
                          style: OutlinedButton.styleFrom(foregroundColor: primaryPurple),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: primaryPurple),
                          onPressed: _handleCreateSubmit,
                          child: const Text('Create', style: TextStyle(color: Colors.white)),
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
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _customSportCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }
}