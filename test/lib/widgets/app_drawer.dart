import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:test/services/auth_service.dart';
import 'package:test/screens/login_screen.dart';
import 'package:test/screens/my_profile_screen.dart';
import 'package:test/screens/syllabus_browser_screen.dart';
import 'package:test/screens/curriculum_management_screen.dart';
import 'package:test/screens/curriculum_integrity_audit_screen.dart';
import 'package:test/models/user_roles.dart';
import 'package:test/providers/user_data_provider.dart';
import 'package:test/screens/settings_screen.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final userData = Provider.of<UserDataProvider>(context);
    final userProfile = userData.userProfile;

    ImageProvider? backgroundImage;
    if (userData.userProfile?.profilePictureUrl != null && userData.userProfile!.profilePictureUrl!.isNotEmpty) {
      backgroundImage =
          CachedNetworkImageProvider(userData.userProfile!.profilePictureUrl!);
    }

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          UserAccountsDrawerHeader(
            accountName: Text(userProfile?.fullName ?? 'User Name'),
            accountEmail: Text((userProfile != null &&
                    userProfile.role != UserRole.unknown)
                ? '${userProfile.role.displayName}${userProfile.qualification != null && userProfile.qualification!.isNotEmpty ? " | ${userProfile.qualification!}" : ""}'
                : ''),
            currentAccountPicture: CircleAvatar(
              backgroundImage: backgroundImage,
              child: backgroundImage == null
                  ? Text(
                      userProfile?.firstName?.isNotEmpty == true
                          ? userProfile!.firstName![0].toUpperCase()
                          : 'U',
                      style: const TextStyle(fontSize: 40.0),
                    )
                  : null,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard_outlined),
            title: const Text('Dashboard'),
            onTap: () => Navigator.of(context).pop(),
          ),
          ListTile(
            leading: const Icon(Icons.menu_book_outlined),
            title: const Text('Syllabus Browser'),
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SyllabusBrowserScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.school_outlined),
            title: const Text('Curriculum Management'),
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CurriculumManagementScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.security_outlined),
            title: const Text('Curriculum Audit'),
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CurriculumIntegrityAuditScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('My Profile'),
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const MyProfileScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text('Settings'),
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SettingsScreen()));
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () async {
              Navigator.of(context).pop();
              await AuthService().signOut();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (Route<dynamic> route) => false,
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
