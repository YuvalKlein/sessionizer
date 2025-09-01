import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ManageSessionsScreen extends StatelessWidget {
  const ManageSessionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Sessions'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _DashboardCard(
            theme: theme,
            icon: Icons.category,
            title: 'Manage Session Types',
            subtitle: 'Create and edit session types',
            onTap: () => context.go('/instructor/session-types'),
          ),
          const SizedBox(height: 16),
          _DashboardCard(
            theme: theme,
            icon: Icons.location_on,
            title: 'Manage Locations',
            subtitle: 'Create and edit locations',
            onTap: () => context.go('/instructor/locations'),
          ),
          const SizedBox(height: 16),
          _DashboardCard(
            theme: theme,
            icon: Icons.schedule,
            title: 'Manage Schedules',
            subtitle: 'Create, edit, and view your availability',
            onTap: () => context.go('/instructor/schedules'),
          ),
        ],
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  const _DashboardCard({
    required this.theme,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final ThemeData theme;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Icon(icon, size: 40, color: theme.colorScheme.primary),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(subtitle, style: theme.textTheme.bodyMedium),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios),
            ],
          ),
        ),
      ),
    );
  }
}
