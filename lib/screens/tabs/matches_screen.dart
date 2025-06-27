import 'package:flutter/material.dart';

class MatchesScreen extends StatefulWidget {
  const MatchesScreen({super.key});

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
  final List<Map<String, dynamic>> _matchRequests = [
    {'name': 'John D.', 'course': 'Pebble Beach', 'status': 'pending'},
    {'name': 'Alex R.', 'course': 'Torrey Pines', 'status': 'pending'},
  ];

  final List<Map<String, dynamic>> _confirmedMatches = [
    {'name': 'Sara T.', 'lastMessage': 'See you Sunday!'},
    {'name': 'Ben M.', 'lastMessage': 'Let’s confirm time'},
  ];

  final List<String> _notifications = [
    'Match confirmed with Jack S.',
    'Your match with Mia was updated.',
    'You received a 5-star rating from James.'
  ];

  void _acceptRequest(int index) {
    setState(() {
      _confirmedMatches.add({
        'name': _matchRequests[index]['name'],
        'lastMessage': 'Match confirmed!'
      });
      _matchRequests.removeAt(index);
    });
  }

  void _declineRequest(int index) {
    setState(() => _matchRequests.removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Matches')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Match Requests', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ..._matchRequests.asMap().entries.map((entry) {
            int index = entry.key;
            var match = entry.value;
            return Card(
              child: ListTile(
                title: Text(match['name']),
                subtitle: Text('Course: ${match['course']}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check, color: Colors.green),
                      onPressed: () => _acceptRequest(index),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed: () => _declineRequest(index),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),

          const SizedBox(height: 16),
          const Text('Confirmed Matches', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ..._confirmedMatches.map((match) => ListTile(
                leading: const CircleAvatar(child: Icon(Icons.golf_course)),
                title: Text(match['name']),
                subtitle: Text(match['lastMessage']),
                onTap: () {
                  // TODO: Navigate to chat thread
                },
              )),

          const SizedBox(height: 16),
          const Text('Notifications', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ..._notifications.map((note) => ListTile(
                leading: const Icon(Icons.notifications, color: Colors.orange),
                title: Text(note),
              )),
        ],
      ),
    );
  }
}