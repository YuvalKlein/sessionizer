import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/features/session_type/presentation/bloc/session_type_bloc.dart';
import 'package:myapp/features/session_type/presentation/bloc/session_type_event.dart';
import 'package:myapp/features/session_type/presentation/bloc/session_type_state.dart';
import 'package:myapp/features/session_type/domain/entities/session_type_entity.dart';
import 'package:myapp/core/utils/logger.dart';
import 'package:myapp/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:myapp/features/auth/presentation/bloc/auth_state.dart';

class SessionTypeManagementPage extends StatefulWidget {
  const SessionTypeManagementPage({super.key});

  @override
  State<SessionTypeManagementPage> createState() => _SessionTypeManagementPageState();
}

class _SessionTypeManagementPageState extends State<SessionTypeManagementPage> {
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    AppLogger.widgetBuild('SessionTypeManagementPage', data: {'action': 'initState'});
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadSessionTypes();
      }
    });
  }

  void _loadSessionTypes() {
    if (!mounted) return;
    
    try {
      final authState = context.read<AuthBloc>().state;
      if (authState is AuthAuthenticated) {
        context.read<SessionTypeBloc>().add(LoadSessionTypesByInstructor(instructorId: authState.user.id));
        AppLogger.blocEvent('SessionTypeBloc', 'LoadSessionTypesByInstructor', data: {'instructorId': authState.user.id});
      } else {
        AppLogger.error('User not authenticated');
      }
    } catch (e) {
      AppLogger.error('Failed to load session types', e);
    }
  }

  @override
  Widget build(BuildContext context) {
    AppLogger.widgetBuild('SessionTypeManagementPage', data: {'action': 'build'});

    return BlocListener<SessionTypeBloc, SessionTypeState>(
      listener: (context, state) {
        if (state is SessionTypeError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
            ),
          );
        } else if (state is SessionTypeLoaded && _isDeleting) {
          // Show success message after delete
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Session type deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
          _isDeleting = false;
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Session Types'),
          leading: IconButton(
            onPressed: () => context.go('/instructor-dashboard'),
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Back to Dashboard',
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                AppLogger.navigation('session-type-management', 'session-type-creation');
                context.go('/session-types/create');
              },
              tooltip: 'Create New Session Type',
            ),
          ],
        ),
        body: BlocBuilder<SessionTypeBloc, SessionTypeState>(
          builder: (context, state) {
            AppLogger.blocState('SessionTypeBloc', state.runtimeType.toString());

            if (state is SessionTypeLoading) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (state is SessionTypeError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading session types',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _loadSessionTypes,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            if (state is SessionTypeLoaded) {
              final sessionTypes = state.sessionTypes;
              
              if (sessionTypes.isEmpty) {
                return _buildEmptyState();
              }
              
              return _buildSessionTypeList(sessionTypes);
            }

            return const Center(
              child: Text('No session types found'),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.sports_tennis,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No session types created yet',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first session type to start offering services',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              AppLogger.navigation('session-type-management', 'session-type-creation');
              context.go('/session-types/create');
            },
            icon: const Icon(Icons.add),
            label: const Text('Create Session Type'),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionTypeList(List<SessionTypeEntity> sessionTypes) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sessionTypes.length,
      itemBuilder: (context, index) {
        final sessionType = sessionTypes[index];
        return _buildSessionTypeCard(sessionType);
      },
    );
  }

  Widget _buildSessionTypeCard(SessionTypeEntity sessionType) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue,
          child: Icon(
            _getCategoryIcon(sessionType.category),
            color: Colors.white,
          ),
        ),
        title: Text(
          sessionType.title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(sessionType.details),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  '${sessionType.duration} min',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
                const SizedBox(width: 16),
                Icon(Icons.attach_money, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  '\$${sessionType.price}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
                const SizedBox(width: 16),
                Icon(Icons.people, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  '${sessionType.minPlayers}-${sessionType.maxPlayers}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 4),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleMenuAction(value, sessionType),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 20),
                  SizedBox(width: 8),
                  Text('Edit'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'duplicate',
              child: Row(
                children: [
                  Icon(Icons.copy, size: 20),
                  SizedBox(width: 8),
                  Text('Duplicate'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 20, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'tennis':
        return Icons.sports_tennis;
      case 'fitness':
        return Icons.fitness_center;
      case 'yoga':
        return Icons.self_improvement;
      default:
        return Icons.sports;
    }
  }

  void _handleMenuAction(String action, SessionTypeEntity sessionType) {
    switch (action) {
      case 'edit':
        AppLogger.navigation('session-type-management', 'session-type-edit');
        context.go('/session-types/create', extra: {
          'sessionType': sessionType,
          'isEdit': true,
        });
        break;
      case 'duplicate':
        _duplicateSessionType(sessionType);
        break;
      case 'delete':
        _deleteSessionType(sessionType);
        break;
    }
  }

  void _duplicateSessionType(SessionTypeEntity sessionType) {
    AppLogger.navigation('session-type-management', 'session-type-duplicate');
    context.go('/session-types/create', extra: {
      'sessionType': sessionType,
      'isEdit': false, // This is a duplicate, not an edit
    });
  }

  void _deleteSessionType(SessionTypeEntity sessionType) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Session Type'),
        content: Text('Are you sure you want to delete "${sessionType.title}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _performDelete(sessionType);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _performDelete(SessionTypeEntity sessionType) {
    setState(() {
      _isDeleting = true;
    });
    
    try {
      context.read<SessionTypeBloc>().add(DeleteSessionTypeEvent(id: sessionType.id ?? ''));
      AppLogger.blocEvent('SessionTypeBloc', 'DeleteSessionTypeEvent', data: {'sessionTypeId': sessionType.id});
    } catch (e) {
      AppLogger.error('Failed to delete session type', e);
      setState(() {
        _isDeleting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to delete session type'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}