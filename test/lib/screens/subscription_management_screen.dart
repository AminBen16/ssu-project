import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:test/providers/user_data_provider.dart';

// Mirroring the backend SUBSCRIPTION_PLANS for display purposes.
const Map<String, Map<String, dynamic>> subscriptionPlansData = {
  'trial': {
    'name': 'Trial',
    'price': 'Free for 30 days',
    'features': ['SMS Reminders'],
    'icon': Icons.hourglass_top_outlined,
    'color': Colors.blueGrey,
  },
  'basic': {
    'name': 'Basic',
    'price': 'Contact for Price',
    'features': ['SMS Reminders'],
    'icon': Icons.school_outlined,
    'color': Colors.blue,
  },
  'premium': {
    'name': 'Premium',
    'price': 'Contact for Price',
    'features': ['SMS Reminders', 'AI Fee Collection Bot', 'AI Content Studio'],
    'icon': Icons.workspace_premium_outlined,
    'color': Colors.purple,
  },
};

class SubscriptionManagementScreen extends StatelessWidget {
  const SubscriptionManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final school =
        Provider.of<UserDataProvider>(context, listen: false).school!;
    final currentPlanKey = school.subscription?.plan ?? 'trial';
    final currentPlanData = subscriptionPlansData[currentPlanKey]!;
    final trialEndDate = school.subscription?.trialEnds;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscription Management'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildCurrentPlanCard(
            context,
            planName: currentPlanData['name'],
            icon: currentPlanData['icon'],
            color: currentPlanData['color'],
            trialEndDate: trialEndDate,
          ),
          const SizedBox(height: 24),
          Text(
            'Available Plans',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          ...subscriptionPlansData.entries
              .where((entry) => entry.key != currentPlanKey)
              .map((entry) {
            final planData = entry.value;
            return _buildPlanOptionCard(
              context,
              planName: planData['name'],
              price: planData['price'],
              features: planData['features'],
              icon: planData['icon'],
              color: planData['color'],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCurrentPlanCard(BuildContext context,
      {required String planName,
      required IconData icon,
      required Color color,
      DateTime? trialEndDate}) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: color, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your Current Plan',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(icon, size: 40, color: color),
                const SizedBox(width: 16),
                Text(planName,
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(color: color)),
              ],
            ),
            if (trialEndDate != null) ...[
              const Divider(height: 24),
              Text(
                'Your trial ends on ${DateFormat.yMMMd().format(trialEndDate)}.',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildPlanOptionCard(BuildContext context,
      {required String planName,
      required String price,
      required List<String> features,
      required IconData icon,
      required Color color}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(icon, color: color, size: 40),
              title:
                  Text(planName, style: Theme.of(context).textTheme.titleLarge),
              subtitle: Text(price),
            ),
            const Divider(),
            const SizedBox(height: 8),
            Text('Includes:', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 8),
            ...features.map((feature) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.check, size: 16),
                  title: Text(feature),
                )),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // In a real app, this would lead to a payment flow.
                // For now, it shows a dialog to contact support.
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 40),
              ),
              child: const Text('Contact Us to Upgrade'),
            )
          ],
        ),
      ),
    );
  }
}
