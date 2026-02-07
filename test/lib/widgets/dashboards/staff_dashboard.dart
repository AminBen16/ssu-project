import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/dashboard_item_model.dart';
import '../../models/user_roles.dart';
import '../../providers/user_data_provider.dart';
import '../../screens/salary_management_screen.dart';
import '../../screens/salary_history_screen.dart';
import '../../screens/fee_collection_screen.dart';

/// A modular widget for Non-Teaching Staff dashboard with role-specific features
class StaffDashboard extends StatelessWidget {
  const StaffDashboard({super.key});

  // Role-specific dashboard features
  List<DashboardItem> _getRoleSpecificItems(
      BuildContext context, UserRole role) {
    switch (role) {
      case UserRole.bursar:
        return _getBursarItems(context);
      case UserRole.schoolSecretary:
        return _getSchoolSecretaryItems(context);
      case UserRole.librarian:
        return _getLibrarianItems(context);
      case UserRole.labTechnician:
        return _getLabTechnicianItems(context);
      case UserRole.computerLabAttendant:
        return _getComputerLabAttendantItems(context);
      case UserRole.schoolNurse:
        return _getSchoolNurseItems(context);
      case UserRole.counselor:
        return _getCounselorItems(context);
      case UserRole.securityGuard:
        return _getSecurityGuardItems(context);
      case UserRole.caretaker:
        return _getCaretakerItems(context);
      case UserRole.cook:
        return _getCookItems(context);
      case UserRole.driver:
        return _getDriverItems(context);
      case UserRole.storeKeeper:
        return _getStoreKeeperItems(context);
      case UserRole.boardingMaster:
        return _getBoardingMasterItems(context);
      default:
        return _getGeneralStaffItems(context);
    }
  }

  // Bursar Features - Financial Management
  List<DashboardItem> _getBursarItems(BuildContext context) {
    return [
      DashboardItem(
        icon: Icons.attach_money,
        label: 'Fee Collection',
        color: Colors.green,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const FeeCollectionScreen()),
        ),
      ),
      DashboardItem(
        icon: Icons.account_balance_wallet,
        label: 'School Budget',
        color: Colors.blue,
        onTap: () => _showComingSoon(context, 'School Budget'),
      ),
      DashboardItem(
        icon: Icons.receipt,
        label: 'Expense Reports',
        color: Colors.orange,
        onTap: () => _showComingSoon(context, 'Expense Reports'),
      ),
      DashboardItem(
        icon: Icons.people,
        label: 'Staff Salaries',
        color: Colors.purple,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const SalaryManagementScreen()),
        ),
      ),
      DashboardItem(
        icon: Icons.trending_up,
        label: 'Financial Reports',
        color: Colors.red,
        onTap: () => _showComingSoon(context, 'Financial Reports'),
      ),
    ];
  }

  // School Secretary Features - Administrative Tasks
  List<DashboardItem> _getSchoolSecretaryItems(BuildContext context) {
    return [
      DashboardItem(
        icon: Icons.mail,
        label: 'School Mail',
        color: Colors.blue,
        onTap: () => _showComingSoon(context, 'School Mail'),
      ),
      DashboardItem(
        icon: Icons.description,
        label: 'Student Records',
        color: Colors.green,
        onTap: () => _showComingSoon(context, 'Student Records'),
      ),
      DashboardItem(
        icon: Icons.phone,
        label: 'Parent Communications',
        color: Colors.orange,
        onTap: () => _showComingSoon(context, 'Parent Communications'),
      ),
      DashboardItem(
        icon: Icons.event,
        label: 'School Calendar',
        color: Colors.purple,
        onTap: () => _showComingSoon(context, 'School Calendar'),
      ),
      DashboardItem(
        icon: Icons.file_copy,
        label: 'Document Management',
        color: Colors.red,
        onTap: () => _showComingSoon(context, 'Document Management'),
      ),
    ];
  }

  // Librarian Features - Library Management
  List<DashboardItem> _getLibrarianItems(BuildContext context) {
    return [
      DashboardItem(
        icon: Icons.menu_book,
        label: 'Book Catalog',
        color: Colors.brown,
        onTap: () => _showComingSoon(context, 'Book Catalog'),
      ),
      DashboardItem(
        icon: Icons.person,
        label: 'Student Borrowing',
        color: Colors.blue,
        onTap: () => _showComingSoon(context, 'Student Borrowing'),
      ),
      DashboardItem(
        icon: Icons.history,
        label: 'Book Returns',
        color: Colors.green,
        onTap: () => _showComingSoon(context, 'Book Returns'),
      ),
      DashboardItem(
        icon: Icons.inventory,
        label: 'Inventory Management',
        color: Colors.orange,
        onTap: () => _showComingSoon(context, 'Inventory Management'),
      ),
      DashboardItem(
        icon: Icons.report,
        label: 'Library Reports',
        color: Colors.purple,
        onTap: () => _showComingSoon(context, 'Library Reports'),
      ),
    ];
  }

  // Lab Technician Features - Science Lab Management
  List<DashboardItem> _getLabTechnicianItems(BuildContext context) {
    return [
      DashboardItem(
        icon: Icons.science,
        label: 'Lab Equipment',
        color: Colors.green,
        onTap: () => _showComingSoon(context, 'Lab Equipment'),
      ),
      DashboardItem(
        icon: Icons.inventory_2,
        label: 'Chemical Inventory',
        color: Colors.red,
        onTap: () => _showComingSoon(context, 'Chemical Inventory'),
      ),
      DashboardItem(
        icon: Icons.schedule,
        label: 'Lab Scheduling',
        color: Colors.blue,
        onTap: () => _showComingSoon(context, 'Lab Scheduling'),
      ),
      DashboardItem(
        icon: Icons.warning,
        label: 'Safety Protocols',
        color: Colors.orange,
        onTap: () => _showComingSoon(context, 'Safety Protocols'),
      ),
    ];
  }

  // Computer Lab Attendant Features - IT Management
  List<DashboardItem> _getComputerLabAttendantItems(BuildContext context) {
    return [
      DashboardItem(
        icon: Icons.computer,
        label: 'Computer Lab',
        color: Colors.blue,
        onTap: () => _showComingSoon(context, 'Computer Lab'),
      ),
      DashboardItem(
        icon: Icons.wifi,
        label: 'Network Status',
        color: Colors.green,
        onTap: () => _showComingSoon(context, 'Network Status'),
      ),
      DashboardItem(
        icon: Icons.build,
        label: 'IT Support',
        color: Colors.orange,
        onTap: () => _showComingSoon(context, 'IT Support'),
      ),
      DashboardItem(
        icon: Icons.schedule,
        label: 'Lab Booking',
        color: Colors.purple,
        onTap: () => _showComingSoon(context, 'Lab Booking'),
      ),
    ];
  }

  // School Nurse Features - Medical Management
  List<DashboardItem> _getSchoolNurseItems(BuildContext context) {
    return [
      DashboardItem(
        icon: Icons.local_hospital,
        label: 'Student Health',
        color: Colors.red,
        onTap: () => _showComingSoon(context, 'Student Health'),
      ),
      DashboardItem(
        icon: Icons.medication,
        label: 'Medicine Inventory',
        color: Colors.green,
        onTap: () => _showComingSoon(context, 'Medicine Inventory'),
      ),
      DashboardItem(
        icon: Icons.healing,
        label: 'First Aid Log',
        color: Colors.blue,
        onTap: () => _showComingSoon(context, 'First Aid Log'),
      ),
      DashboardItem(
        icon: Icons.contact_phone,
        label: 'Emergency Contacts',
        color: Colors.orange,
        onTap: () => _showComingSoon(context, 'Emergency Contacts'),
      ),
    ];
  }

  // Counselor Features - Student Guidance
  List<DashboardItem> _getCounselorItems(BuildContext context) {
    return [
      DashboardItem(
        icon: Icons.psychology,
        label: 'Counseling Sessions',
        color: Colors.purple,
        onTap: () => _showComingSoon(context, 'Counseling Sessions'),
      ),
      DashboardItem(
        icon: Icons.person_search,
        label: 'Student Records',
        color: Colors.blue,
        onTap: () => _showComingSoon(context, 'Student Records'),
      ),
      DashboardItem(
        icon: Icons.calendar_month,
        label: 'Appointments',
        color: Colors.green,
        onTap: () => _showComingSoon(context, 'Appointments'),
      ),
      DashboardItem(
        icon: Icons.support,
        label: 'Support Groups',
        color: Colors.orange,
        onTap: () => _showComingSoon(context, 'Support Groups'),
      ),
    ];
  }

  // Security Guard Features - Security Management
  List<DashboardItem> _getSecurityGuardItems(BuildContext context) {
    return [
      DashboardItem(
        icon: Icons.security,
        label: 'Security Log',
        color: Colors.blue,
        onTap: () => _showComingSoon(context, 'Security Log'),
      ),
      DashboardItem(
        icon: Icons.visibility,
        label: 'Visitor Management',
        color: Colors.green,
        onTap: () => _showComingSoon(context, 'Visitor Management'),
      ),
      DashboardItem(
        icon: Icons.camera,
        label: 'CCTV Monitoring',
        color: Colors.red,
        onTap: () => _showComingSoon(context, 'CCTV Monitoring'),
      ),
      DashboardItem(
        icon: Icons.report_problem,
        label: 'Incident Reports',
        color: Colors.orange,
        onTap: () => _showComingSoon(context, 'Incident Reports'),
      ),
    ];
  }

  // Caretaker Features - Facilities Management
  List<DashboardItem> _getCaretakerItems(BuildContext context) {
    return [
      DashboardItem(
        icon: Icons.home_repair_service,
        label: 'Maintenance',
        color: Colors.brown,
        onTap: () => _showComingSoon(context, 'Maintenance'),
      ),
      DashboardItem(
        icon: Icons.grass,
        label: 'Grounds Keeping',
        color: Colors.green,
        onTap: () => _showComingSoon(context, 'Grounds Keeping'),
      ),
      DashboardItem(
        icon: Icons.lightbulb,
        label: 'Utilities',
        color: Colors.yellow,
        onTap: () => _showComingSoon(context, 'Utilities'),
      ),
      DashboardItem(
        icon: Icons.cleaning_services,
        label: 'Cleaning Schedule',
        color: Colors.blue,
        onTap: () => _showComingSoon(context, 'Cleaning Schedule'),
      ),
    ];
  }

  // Cook Features - Kitchen Management
  List<DashboardItem> _getCookItems(BuildContext context) {
    return [
      DashboardItem(
        icon: Icons.restaurant,
        label: 'Meal Planning',
        color: Colors.orange,
        onTap: () => _showComingSoon(context, 'Meal Planning'),
      ),
      DashboardItem(
        icon: Icons.inventory,
        label: 'Food Inventory',
        color: Colors.green,
        onTap: () => _showComingSoon(context, 'Food Inventory'),
      ),
      DashboardItem(
        icon: Icons.schedule,
        label: 'Meal Schedule',
        color: Colors.blue,
        onTap: () => _showComingSoon(context, 'Meal Schedule'),
      ),
      DashboardItem(
        icon: Icons.people,
        label: 'Student Meals',
        color: Colors.purple,
        onTap: () => _showComingSoon(context, 'Student Meals'),
      ),
    ];
  }

  // Driver Features - Transportation Management
  List<DashboardItem> _getDriverItems(BuildContext context) {
    return [
      DashboardItem(
        icon: Icons.directions_bus,
        label: 'Bus Routes',
        color: Colors.blue,
        onTap: () => _showComingSoon(context, 'Bus Routes'),
      ),
      DashboardItem(
        icon: Icons.schedule,
        label: 'Trip Schedule',
        color: Colors.green,
        onTap: () => _showComingSoon(context, 'Trip Schedule'),
      ),
      DashboardItem(
        icon: Icons.people,
        label: 'Student Pickup',
        color: Colors.orange,
        onTap: () => _showComingSoon(context, 'Student Pickup'),
      ),
      DashboardItem(
        icon: Icons.report,
        label: 'Vehicle Maintenance',
        color: Colors.red,
        onTap: () => _showComingSoon(context, 'Vehicle Maintenance'),
      ),
    ];
  }

  // Store Keeper Features - Inventory Management
  List<DashboardItem> _getStoreKeeperItems(BuildContext context) {
    return [
      DashboardItem(
        icon: Icons.inventory_2,
        label: 'Stock Management',
        color: Colors.brown,
        onTap: () => _showComingSoon(context, 'Stock Management'),
      ),
      DashboardItem(
        icon: Icons.add_shopping_cart,
        label: 'Supplies Request',
        color: Colors.green,
        onTap: () => _showComingSoon(context, 'Supplies Request'),
      ),
      DashboardItem(
        icon: Icons.receipt_long,
        label: 'Issue Records',
        color: Colors.blue,
        onTap: () => _showComingSoon(context, 'Issue Records'),
      ),
      DashboardItem(
        icon: Icons.bar_chart,
        label: 'Inventory Reports',
        color: Colors.purple,
        onTap: () => _showComingSoon(context, 'Inventory Reports'),
      ),
    ];
  }

  // Boarding Master Features - Dormitory Management
  List<DashboardItem> _getBoardingMasterItems(BuildContext context) {
    return [
      DashboardItem(
        icon: Icons.bed,
        label: 'Room Management',
        color: Colors.blue,
        onTap: () => _showComingSoon(context, 'Room Management'),
      ),
      DashboardItem(
        icon: Icons.people,
        label: 'Student Attendance',
        color: Colors.green,
        onTap: () => _showComingSoon(context, 'Student Attendance'),
      ),
      DashboardItem(
        icon: Icons.schedule,
        label: 'Duty Roster',
        color: Colors.orange,
        onTap: () => _showComingSoon(context, 'Duty Roster'),
      ),
      DashboardItem(
        icon: Icons.report,
        label: 'Discipline Records',
        color: Colors.red,
        onTap: () => _showComingSoon(context, 'Discipline Records'),
      ),
    ];
  }

  // General Staff Features (fallback)
  List<DashboardItem> _getGeneralStaffItems(BuildContext context) {
    return [
      DashboardItem(
        icon: Icons.person,
        label: 'My Profile',
        color: Colors.blue,
        onTap: () => _showComingSoon(context, 'My Profile'),
      ),
      DashboardItem(
        icon: Icons.schedule,
        label: 'My Schedule',
        color: Colors.green,
        onTap: () => _showComingSoon(context, 'My Schedule'),
      ),
      DashboardItem(
        icon: Icons.account_balance_wallet,
        label: 'My Salary History',
        color: Colors.purple,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const SalaryHistoryScreen()),
        ),
      ),
    ];
  }

  // Common features for all staff
  List<DashboardItem> _getCommonItems(BuildContext context) {
    return [
      DashboardItem(
        icon: Icons.person,
        label: 'My Profile',
        color: Colors.blue,
        onTap: () => _showComingSoon(context, 'My Profile'),
      ),
      DashboardItem(
        icon: Icons.notifications,
        label: 'Notifications',
        color: Colors.orange,
        onTap: () => _showComingSoon(context, 'Notifications'),
      ),
    ];
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature - Coming Soon!'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userData = Provider.of<UserDataProvider>(context);
    final userRole = userData.userProfile?.role ?? UserRole.unknown;

    final roleSpecificItems = _getRoleSpecificItems(context, userRole);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome header
            Text(
              'Welcome, ${userData.userProfile?.firstName ?? 'Staff'}!',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              userRole.displayName,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 24),

            // Role-specific features
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: roleSpecificItems.length,
                itemBuilder: (context, index) {
                  final item = roleSpecificItems[index];
                  return Card(
                    elevation: 4,
                    child: InkWell(
                      onTap: item.onTap,
                      borderRadius: BorderRadius.circular(8),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            item.icon,
                            size: 40,
                            color: item.color,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            item.label,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
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
