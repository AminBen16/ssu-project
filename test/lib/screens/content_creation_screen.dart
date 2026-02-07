import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:test/providers/user_data_provider.dart';
import 'package:test/services/social_media_service.dart';
import 'package:test/services/ai_suggestion_service.dart';
import 'package:test/models/social_post_model.dart';

class ContentCreationScreen extends StatefulWidget {
  const ContentCreationScreen({super.key});

  @override
  State<ContentCreationScreen> createState() => _ContentCreationScreenState();
}

class _ContentCreationScreenState extends State<ContentCreationScreen> {
  final _socialMediaService = SocialMediaService();
  final _aiService = AISuggestionService();
  bool _isSuggesting = false;

  void _showCreatePostDialog() {
    final formKey = GlobalKey<FormState>();
    final contentController = TextEditingController();
    DateTime? scheduleDate;
    TimeOfDay? scheduleTime;
    final List<bool> selectedPlatforms = [
      true,
      false,
      false,
    ]; // FB, Twitter, IG

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Schedule New Post'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: contentController,
                        decoration: const InputDecoration(
                          labelText: 'Post Content',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 5,
                        validator: (v) =>
                            v!.isEmpty ? 'Content is required' : null,
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: _isSuggesting
                            ? null
                            : () async {
                                setDialogState(() => _isSuggesting = true);
                                final suggestion = await _aiService
                                    .getPostSuggestion('general school event');
                                if (suggestion != null) {
                                  contentController.text = suggestion;
                                }
                                setDialogState(() => _isSuggesting = false);
                              },
                        icon: _isSuggesting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.auto_awesome),
                        label: const Text('Suggest with AI'),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              scheduleDate == null
                                  ? 'Select Date'
                                  : DateFormat.yMMMd().format(scheduleDate!),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.calendar_today),
                            onPressed: () async {
                              final pickedDate = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(
                                  const Duration(days: 365),
                                ),
                              );
                              if (pickedDate != null) {
                                setDialogState(() => scheduleDate = pickedDate);
                              }
                            },
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              scheduleTime == null
                                  ? 'Select Time'
                                  : scheduleTime!.format(context),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.access_time),
                            onPressed: () async {
                              final pickedTime = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay.now(),
                              );
                              if (pickedTime != null) {
                                setDialogState(() => scheduleTime = pickedTime);
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ToggleButtons(
                        isSelected: selectedPlatforms,
                        onPressed: (index) {
                          setDialogState(
                            () => selectedPlatforms[index] =
                                !selectedPlatforms[index],
                          );
                        },
                        children: const [
                          Icon(Icons.facebook),
                          Text('X'),
                          Icon(Icons.photo_camera),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed:
                      _isSuggesting ? null : () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: _isSuggesting
                      ? null
                      : () async {
                          if (formKey.currentState!.validate() &&
                              scheduleDate != null &&
                              scheduleTime != null) {
                            final userData = Provider.of<UserDataProvider>(
                              context,
                              listen: false,
                            );
                            final scheduleDateTime = DateTime(
                              scheduleDate!.year,
                              scheduleDate!.month,
                              scheduleDate!.day,
                              scheduleTime!.hour,
                              scheduleTime!.minute,
                            );
                            final platforms = <String>[];
                            if (selectedPlatforms[0]) platforms.add('Facebook');
                            if (selectedPlatforms[1]) platforms.add('Twitter');
                            if (selectedPlatforms[2]) {
                              platforms.add('Instagram');
                            }

                            final newPost = {
                              'content': contentController.text,
                              'scheduledTime':
                                  scheduleDateTime.toIso8601String(),
                              'platforms': platforms,
                              'status': 'scheduled',
                              'authorId': userData.userProfile!.uid,
                              'createdAt': DateTime.now().toIso8601String(),
                            };

                            await _socialMediaService.createPost(
                              userData.school!.id.toString(),
                              newPost,
                            );
                            if (context.mounted) Navigator.of(context).pop();
                          }
                        },
                  child: const Text('Schedule'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final schoolId = Provider.of<UserDataProvider>(
      context,
      listen: false,
    ).school!.id;

    return Scaffold(
      appBar: AppBar(title: const Text('Content Creation')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _socialMediaService.getPosts(schoolId.toString()),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          final postsData = snapshot.data ?? [];
          if (postsData.isEmpty) {
            return const Center(
              child: Text('No posts scheduled. Tap + to create one.'),
            );
          }

          final posts =
              postsData.map((data) => SocialPost.fromMap(data)).toList();

          return ListView.builder(
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              final scheduleDate = post.scheduledTime;
              final isPast = scheduleDate.isBefore(DateTime.now());

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  leading: Icon(
                    isPast ? Icons.check_circle : Icons.timer_outlined,
                    color: isPast ? Colors.green : Colors.orange,
                  ),
                  title: Text(
                    post.content,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    'Scheduled for: ${DateFormat.yMMMd().add_jm().format(scheduleDate)}\nPlatforms: ${post.platforms.join(', ')}',
                  ),
                  isThreeLine: true,
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () async {
                      // Add confirmation dialog before deleting
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Delete Post?'),
                          content: const Text(
                            'Are you sure you want to delete this scheduled post?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: const Text(
                                'Delete',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await _socialMediaService.deletePost(
                          schoolId.toString(),
                          post.id!,
                        );
                        // Refresh the list after deletion
                        setState(() {});
                      }
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreatePostDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
