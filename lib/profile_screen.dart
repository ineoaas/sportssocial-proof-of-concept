import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final Color primaryPurple = const Color(0xFF4B0082);
  final nameCtrl = TextEditingController();
  int iconIndex = 0;
  final icons = const [
    Icons.person,
    Icons.sports_soccer,
    Icons.sports_basketball,
    Icons.star,
    Icons.sports_tennis,
    Icons.sports_handball
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      nameCtrl.text = prefs.getString('profile_name') ?? 'User';
      iconIndex = prefs.getInt('profile_icon') ?? 0;
    });
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('profile_name', nameCtrl.text);
    prefs.setInt('profile_icon', iconIndex);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Profile saved'), backgroundColor: primaryPurple));
  }

  Future<void> _reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    setState(() {
      nameCtrl.text = 'User';
      iconIndex = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final icon = icons[iconIndex];
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: primaryPurple,
            child: Icon(icon, color: Colors.white, size: 50),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: nameCtrl,
            decoration: InputDecoration(
                labelText: 'Display name',
                prefixIcon: Icon(Icons.edit, color: primaryPurple)),
          ),
          const SizedBox(height: 20),
          Text('Choose profile icon',
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: primaryPurple)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            children: List.generate(
              icons.length,
              (i) => GestureDetector(
                onTap: () => setState(() => iconIndex = i),
                child: CircleAvatar(
                  backgroundColor: i == iconIndex
                      ? primaryPurple.withAlpha((0.2 * 255).round())
                      : Colors.grey.shade200,
                  child: Icon(icons[i],
                      color: i == iconIndex
                          ? primaryPurple
                          : Colors.grey.shade700),
                ),
              ),
            ),
          ),
          const SizedBox(height: 30),
          Row(children: [
            Expanded(
                child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                        foregroundColor: primaryPurple),
                    onPressed: _reset,
                    child: const Text('Reset'))),
            const SizedBox(width: 10),
            Expanded(
                child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: primaryPurple),
                    onPressed: _save,
                    child: const Text('Save', style: TextStyle(color: Colors.white))))
          ]),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
            },
            icon: const Icon(Icons.logout),
            label: const Text('Logout'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
            ),
          )
        ]),
      ),
    );
  }
}