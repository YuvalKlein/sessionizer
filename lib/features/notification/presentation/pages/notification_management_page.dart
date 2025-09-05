import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:myapp/core/utils/injection_container.dart';
import 'package:myapp/features/notification/domain/entities/notification_entity.dart';
import 'package:myapp/features/notification/presentation/bloc/notification_bloc.dart';
import 'package:myapp/features/notification/presentation/bloc/notification_event.dart';
import 'package:myapp/features/notification/presentation/bloc/notification_state.dart';

class NotificationManagementPage extends StatefulWidget {
  const NotificationManagementPage({super.key});

  @override
  State<NotificationManagementPage> createState() => _NotificationManagementPageState();
}

class _NotificationManagementPageState extends State<NotificationManagementPage> {
  String? _currentUserId;
  bool _showUnreadOnly = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            icon: Icon(_showUnreadOnly ? Icons.filter_list : Icons.filter_list_off),
            onPressed: () {
              setState(() {
                _showUnreadOnly = !_showUnreadOnly;
              });
              if (_currentUserId != null) {
                if (_showUnreadOnly) {
                  context.read<NotificationBloc>().add(LoadUnreadNotifications(userId: _currentUserId!));
                } else {
                  context.read<NotificationBloc>().add(LoadNotifications(userId: _currentUserId!));
                }
              }
            },
          ),
          if (_currentUserId != null)
            IconButton(
              icon: const Icon(Icons.mark_email_read),
              onPressed: () {
                context.read<NotificationBloc>().add(MarkAllAsRead(userId: _currentUserId!));
              },
            ),
        ],
      ),
      body: BlocProvider(
        create: (context) => sl<NotificationBloc>(),
        child: BlocListener<NotificationBloc, NotificationState>(
          listener: (context, state) {
            if (state is NotificationOperationSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.green,
                ),
              );
              // Refresh notifications after operation
              if (_currentUserId != null) {
                context.read<NotificationBloc>().add(LoadNotifications(userId: _currentUserId!));
              }
            } else if (state is NotificationError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          child: BlocBuilder<NotificationBloc, NotificationState>(
            builder: (context, state) {
              if (state is NotificationLoading) {
                return const Center(child: CircularProgressIndicator());
              } else if (state is NotificationError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading notifications',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        state.message,
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          if (_currentUserId != null) {
                            context.read<NotificationBloc>().add(LoadNotifications(userId: _currentUserId!));
                          }
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              } else if (state is NotificationLoaded) {
                if (state.notifications.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _showUnreadOnly ? Icons.mark_email_read : Icons.notifications_none,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _showUnreadOnly ? 'No unread notifications' : 'No notifications',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _showUnreadOnly
                              ? 'You\'re all caught up!'
                              : 'You\'ll see notifications here when they arrive.',
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: [
                    if (state.unreadCount > 0 && !_showUnreadOnly)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        color: Colors.blue[50],
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue[700]),
                            const SizedBox(width: 8),
                            Text(
                              '${state.unreadCount} unread notification${state.unreadCount == 1 ? '' : 's'}',
                              style: TextStyle(
                                color: Colors.blue[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: state.notifications.length,
                        itemBuilder: (context, index) {
                          final notification = state.notifications[index];
                          return _buildNotificationCard(notification);
                        },
                      ),
                    ),
                  ],
                );
              }

              return const Center(
                child: Text('Select a user to view notifications'),
              );
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showUserSelectionDialog(),
        tooltip: 'Select User',
        child: const Icon(Icons.person),
      ),
    );
  }

  Widget _buildNotificationCard(NotificationEntity notification) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getNotificationColor(notification.type),
          child: Icon(
            _getNotificationIcon(notification.type),
            color: Colors.white,
          ),
        ),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight: notification.status == NotificationStatus.pending
                ? FontWeight.bold
                : FontWeight.normal,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification.body),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  _formatDateTime(notification.createdAt),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(width: 8),
                _buildStatusChip(notification.status),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'mark_read':
                if (notification.status == NotificationStatus.pending) {
                  context.read<NotificationBloc>().add(
                    MarkAsRead(notificationId: notification.id),
                  );
                }
                break;
              case 'delete':
                _showDeleteConfirmation(notification);
                break;
            }
          },
          itemBuilder: (context) => [
            if (notification.status == NotificationStatus.pending)
              const PopupMenuItem(
                value: 'mark_read',
                child: Row(
                  children: [
                    Icon(Icons.mark_email_read),
                    SizedBox(width: 8),
                    Text('Mark as Read'),
                  ],
                ),
              ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete'),
                ],
              ),
            ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }

  Widget _buildStatusChip(NotificationStatus status) {
    Color color;
    String text;

    switch (status) {
      case NotificationStatus.pending:
        color = Colors.orange;
        text = 'Unread';
        break;
      case NotificationStatus.sent:
        color = Colors.blue;
        text = 'Sent';
        break;
      case NotificationStatus.read:
        color = Colors.green;
        text = 'Read';
        break;
      case NotificationStatus.failed:
        color = Colors.red;
        text = 'Failed';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Color _getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.bookingConfirmation:
        return Colors.green;
      case NotificationType.bookingReminder:
        return Colors.orange;
      case NotificationType.bookingCancellation:
        return Colors.red;
      case NotificationType.scheduleChange:
        return Colors.blue;
      case NotificationType.general:
        return Colors.grey;
    }
  }

  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.bookingConfirmation:
        return Icons.check_circle;
      case NotificationType.bookingReminder:
        return Icons.schedule;
      case NotificationType.bookingCancellation:
        return Icons.cancel;
      case NotificationType.scheduleChange:
        return Icons.update;
      case NotificationType.general:
        return Icons.notifications;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  void _showDeleteConfirmation(NotificationEntity notification) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Notification'),
        content: const Text('Are you sure you want to delete this notification?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<NotificationBloc>().add(
                DeleteNotification(notificationId: notification.id),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showUserSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select User'),
        content: const Text('Enter user ID to view their notifications'),
        actions: [
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'User ID',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              _currentUserId = value;
            },
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (_currentUserId != null && _currentUserId!.isNotEmpty) {
                    Navigator.of(context).pop();
                    context.read<NotificationBloc>().add(
                      LoadNotifications(userId: _currentUserId!),
                    );
                  }
                },
                child: const Text('Load'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
