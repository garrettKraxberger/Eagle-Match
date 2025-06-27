import 'package:flutter/material.dart';

class DuosScreen extends StatelessWidget {
  const DuosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Duos')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ElevatedButton.icon(
              onPressed: () {
                // TODO: implement player linking by email or user code
              },
              icon: const Icon(Icons.link),
              label: const Text('Link a Player'),
            ),
            const SizedBox(height: 20),
            const Text(
              'Starred Duos',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: 3, // Placeholder count
                itemBuilder: (context, index) {
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.person)),
                      title: Text('Player ${index + 1}'),
                      subtitle: const Text('Nickname • 5 Matches • 3 Wins'),
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) {
                          // TODO: handle unlink/report
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(value: 'unlink', child: Text('Unlink')),
                          const PopupMenuItem(value: 'report', child: Text('Report')),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}