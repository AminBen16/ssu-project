import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:test/models/scheme_of_work_model.dart';
import 'package:test/providers/user_data_provider.dart';
import 'package:test/screens/edit_scheme_of_work_screen.dart';
import 'package:test/services/scheme_of_work_service.dart';
import 'package:test/screens/scheme_of_work_generator_screen.dart';

class SchemeOfWorkListScreen extends StatefulWidget {
  const SchemeOfWorkListScreen({super.key});

  @override
  State<SchemeOfWorkListScreen> createState() => _SchemeOfWorkListScreenState();
}

class _SchemeOfWorkListScreenState extends State<SchemeOfWorkListScreen> {
  late final SchemeOfWorkService _schemeService;
  late final String _teacherId;

  @override
  void initState() {
    super.initState();
    final user = Provider.of<UserDataProvider>(context, listen: false).userProfile!;
    _teacherId = user.uid;
    _schemeService = SchemeOfWorkService();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Schemes of Work')),
      body: FutureBuilder<List<SchemeOfWork>>(
        future: _schemeService.getSchemesOfWork(_teacherId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final schemes = snapshot.data ?? [];

          if (schemes.isEmpty) {
            return const Center(child: Text('No schemes found. Tap + to create one.'));
          }

          return ListView.builder(
            itemCount: schemes.length,
            itemBuilder: (context, index) {
              final scheme = schemes[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  title: Text('${scheme.subject} - ${scheme.className}'),
                  subtitle: Text(
                    '${scheme.term}, ${scheme.year}\nUpdated: ${DateFormat.yMMMd().format(scheme.updatedAt)}',
                  ),
                  isThreeLine: true,
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) =>
                            EditSchemeOfWorkScreen(scheme: scheme),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Show a dialog to choose between manual creation and AI generation
          showDialog(
            context: context,
            builder: (dialogContext) => AlertDialog(
              title: const Text('Create Scheme of Work'),
              content: const Text('How would you like to start?'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop(); // Close dialog
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => EditSchemeOfWorkScreen(),
                      ),
                    );
                  },
                  child: const Text('Create Manually'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop(); // Close dialog
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const SchemeOfWorkGeneratorScreen(),
                      ),
                    );
                  },
                  child: const Text('Generate with AI'),
                ),
              ],
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
