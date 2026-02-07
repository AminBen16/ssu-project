import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:test/providers/user_data_provider.dart';

/// A reusable card widget that displays the current user's profile information.
class ProfileHeaderCard extends StatelessWidget {
  final VoidCallback? onEdit;

  const ProfileHeaderCard({super.key, this.onEdit});

  @override
  Widget build(BuildContext context) {
    final userData = Provider.of<UserDataProvider>(context, listen: false);
    final userProfile = userData.userProfile;

    ImageProvider? backgroundImage;
    if (userProfile?.profilePictureUrl != null && userProfile!.profilePictureUrl!.isNotEmpty) {
      backgroundImage =
          CachedNetworkImageProvider(userProfile.profilePictureUrl!);
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundImage: backgroundImage,
                child: backgroundImage == null
                    ? Text(
                        userProfile?.firstName?.isNotEmpty == true
                            ? userProfile!.firstName![0]
                            : 'U', // 'U' for User
                        style: const TextStyle(fontSize: 28),
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userProfile?.fullName ?? 'User',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      userProfile?.role.displayName ?? 'Role',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
              if (onEdit != null)
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: onEdit,
                  tooltip: 'Edit Profile',
                  color: Theme.of(context).colorScheme.primary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
