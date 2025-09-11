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

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}

class SessionTypeCreationPage extends StatefulWidget {
  final SessionTypeEntity? existingSessionType;
  final bool isEdit;
  
  const SessionTypeCreationPage({
    super.key,
    this.existingSessionType,
    this.isEdit = false,
  });

  @override
  State<SessionTypeCreationPage> createState() => _SessionTypeCreationPageState();
}

class _SessionTypeCreationPageState extends State<SessionTypeCreationPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _detailsController = TextEditingController();
  final _priceController = TextEditingController();
  final _durationController = TextEditingController(text: '1');
  final _maxPlayersController = TextEditingController(text: '1');
  final _minPlayersController = TextEditingController(text: '1');
  
  // Cancellation Policy Controllers
  final _cancellationTimeController = TextEditingController(text: '18');
  final _cancellationFeeController = TextEditingController(text: '100');
  
  String _selectedDurationUnit = 'hours';
  String _selectedCancellationTimeUnit = 'hours';
  String _selectedCancellationFeeType = '%';
  bool _notifyCancelation = false;
  bool _showParticipants = true;
  bool _showMinMax = true;
  bool _isLoading = false;
  bool _hasCancellationFee = true;

  final List<String> _durationUnits = ['hours', 'minutes'];
  final List<String> _cancellationTimeUnits = ['hours', 'minutes'];
  final List<String> _cancellationFeeTypes = ['%', '\$'];


  @override
  void initState() {
    super.initState();
    AppLogger.widgetBuild('SessionTypeCreationPage', data: {'action': 'initState'});
    
    if (widget.existingSessionType != null) {
      _populateForm(widget.existingSessionType!);
    }
  }

  void _populateForm(SessionTypeEntity sessionType) {
    _titleController.text = sessionType.title;
    _detailsController.text = sessionType.details;
    _priceController.text = sessionType.price.toString();
    
    // Convert duration back to the original unit
    if (sessionType.durationUnit == 'hours') {
      _durationController.text = (sessionType.duration ~/ 60).toString();
      _selectedDurationUnit = 'hours';
    } else {
      _durationController.text = sessionType.duration.toString();
      _selectedDurationUnit = 'minutes';
    }
    
    _maxPlayersController.text = sessionType.maxPlayers.toString();
    _minPlayersController.text = sessionType.minPlayers.toString();
    _notifyCancelation = sessionType.notifyCancelation;
    _showParticipants = sessionType.showParticipants;
    _showMinMax = sessionType.showParticipants; // Use showParticipants as default for showMinMax
    
    // Populate cancellation policy fields
    _hasCancellationFee = sessionType.hasCancellationFee;
    _cancellationTimeController.text = sessionType.cancellationTimeBefore.toString();
    _selectedCancellationTimeUnit = sessionType.cancellationTimeUnit;
    _cancellationFeeController.text = sessionType.cancellationFeeAmount.toString();
    _selectedCancellationFeeType = sessionType.cancellationFeeType;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _detailsController.dispose();
    _priceController.dispose();
    _durationController.dispose();
    _maxPlayersController.dispose();
    _minPlayersController.dispose();
    _cancellationTimeController.dispose();
    _cancellationFeeController.dispose();
    super.dispose();
  }

  void _validateMaxPlayers() {
    final minPlayers = int.tryParse(_minPlayersController.text) ?? 1;
    final maxPlayers = int.tryParse(_maxPlayersController.text) ?? 1;
    
    if (maxPlayers < minPlayers) {
      setState(() {
        _maxPlayersController.text = minPlayers.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    AppLogger.widgetBuild('SessionTypeCreationPage', data: {'action': 'build'});

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEdit ? 'Edit Session Type' : 'Create Session Type'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/session-types'),
        ),
      ),
      body: BlocListener<SessionTypeBloc, SessionTypeState>(
        listener: (context, state) {
          if (state is SessionTypeLoaded) {
            // Success - session type was created and list was reloaded
            setState(() {
              _isLoading = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Session type created successfully!'),
                backgroundColor: Colors.green,
              ),
            );
            // Navigate back to session types list
            context.go('/session-types');
          } else if (state is SessionTypeError) {
            setState(() {
              _isLoading = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state is SessionTypeLoading) {
            setState(() {
              _isLoading = true;
            });
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBasicInfoSection(),
                const SizedBox(height: 24),
                _buildPricingSection(),
                const SizedBox(height: 24),
                _buildDurationSection(),
                const SizedBox(height: 24),
                _buildStatusSection(),
                const SizedBox(height: 24),
                _buildCancellationPolicySection(),
                const SizedBox(height: 100), // Space for floating action button
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isLoading ? null : _saveSessionType,
        icon: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : Icon(widget.isEdit ? Icons.update : Icons.add),
        label: Text(widget.isEdit ? 'Update' : 'Create'),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Basic Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Session Type Title',
                hintText: 'e.g., Yoga Class, Personal Training',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a session type title';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _detailsController,
              decoration: const InputDecoration(
                labelText: 'Details',
                hintText: 'Describe what this session type includes',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter details';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPricingSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pricing',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _priceController,
              decoration: const InputDecoration(
                labelText: 'Price per Session',
                hintText: '0.00',
                prefixText: '\$',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a price';
                }
                final price = double.tryParse(value);
                if (price == null || price < 0) {
                  return 'Please enter a valid price';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDurationSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Duration & Capacity',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _durationController,
                    decoration: const InputDecoration(
                      labelText: 'Duration',
                      hintText: '1',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter duration';
                      }
                      final duration = int.tryParse(value);
                      if (duration == null || duration <= 0) {
                        return 'Please enter a valid duration';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedDurationUnit,
                    decoration: const InputDecoration(
                      labelText: 'Unit',
                      border: OutlineInputBorder(),
                    ),
                    items: _durationUnits.map((String unit) {
                      return DropdownMenuItem<String>(
                        value: unit,
                        child: Text(unit.capitalize()),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedDurationUnit = newValue!;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _minPlayersController,
                    decoration: const InputDecoration(
                      labelText: 'Min Players',
                      hintText: '1',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      _validateMaxPlayers();
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter min players';
                      }
                      final min = int.tryParse(value);
                      if (min == null || min < 1) {
                        return 'Please enter a valid number (min 1)';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _maxPlayersController,
                    decoration: const InputDecoration(
                      labelText: 'Max Players',
                      hintText: '1',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter max players';
                      }
                      final max = int.tryParse(value);
                      if (max == null || max <= 0) {
                        return 'Please enter a valid number';
                      }
                      final min = int.tryParse(_minPlayersController.text) ?? 1;
                      if (max < min) {
                        return 'Max must be >= min';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }



  Widget _buildStatusSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Session Settings',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Notify Cancellation'),
              subtitle: const Text('Send notifications when session is cancelled'),
              value: _notifyCancelation,
              onChanged: (value) {
                setState(() {
                  _notifyCancelation = value;
                });
              },
            ),
            SwitchListTile(
              title: const Text('Show Participants'),
              subtitle: const Text('Show participant list to other users'),
              value: _showParticipants,
              onChanged: (value) {
                setState(() {
                  _showParticipants = value;
                });
              },
            ),
            SwitchListTile(
              title: const Text('Show Min/Max'),
              subtitle: const Text('Display minimum and maximum participants'),
              value: _showMinMax,
              onChanged: (value) {
                setState(() {
                  _showMinMax = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCancellationPolicySection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cancellation Policy',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Cancellation Fee Toggle
            SwitchListTile(
              title: const Text('Cancellation Fee'),
              subtitle: const Text('Enable cancellation fees for late cancellations'),
              value: _hasCancellationFee,
              onChanged: (value) {
                setState(() {
                  _hasCancellationFee = value;
                });
              },
            ),
            
            // Cancellation Policy Details (shown when enabled)
            if (_hasCancellationFee) ...[
              const SizedBox(height: 16),
              
              // Time to Cancel
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _cancellationTimeController,
                      decoration: const InputDecoration(
                        labelText: 'Time to Cancel',
                        hintText: '18',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (_hasCancellationFee && (value == null || value.isEmpty)) {
                          return 'Please enter cancellation time';
                        }
                        final time = int.tryParse(value ?? '');
                        if (_hasCancellationFee && (time == null || time <= 0)) {
                          return 'Please enter a valid time';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedCancellationTimeUnit,
                      decoration: const InputDecoration(
                        labelText: 'Unit',
                        border: OutlineInputBorder(),
                      ),
                      items: _cancellationTimeUnits.map((String unit) {
                        return DropdownMenuItem<String>(
                          value: unit,
                          child: Text(unit.capitalize()),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedCancellationTimeUnit = newValue!;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Tooltip(
                    message: 'How much time before the session the client can cancel without a fee',
                    child: Icon(
                      Icons.info_outline,
                      color: Colors.grey[600],
                      size: 20,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Cancellation Fee Amount
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _cancellationFeeController,
                      decoration: const InputDecoration(
                        labelText: 'Cancellation Fee',
                        hintText: '100',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (_hasCancellationFee && (value == null || value.isEmpty)) {
                          return 'Please enter cancellation fee';
                        }
                        final fee = int.tryParse(value ?? '');
                        if (_hasCancellationFee && (fee == null || fee < 0)) {
                          return 'Please enter a valid fee';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedCancellationFeeType,
                      decoration: const InputDecoration(
                        labelText: 'Type',
                        border: OutlineInputBorder(),
                      ),
                      items: _cancellationFeeTypes.map((String type) {
                        return DropdownMenuItem<String>(
                          value: type,
                          child: Text(type == '%' ? 'Percentage (%)' : 'Fixed Amount (\$)'),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedCancellationFeeType = newValue!;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _saveSessionType() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Get current user ID from auth context
    final authBloc = context.read<AuthBloc>();
    final authState = authBloc.state;
    String currentUserId = 'unknown_user';
    
    if (authState is AuthAuthenticated) {
      currentUserId = authState.user.id;
    }

    final sessionType = SessionTypeEntity(
      id: widget.isEdit ? widget.existingSessionType!.id : null, // Keep existing ID for edit
      title: _titleController.text.trim(),
      notifyCancelation: _notifyCancelation,
      createdTime: widget.isEdit ? widget.existingSessionType!.createdTime : DateTime.now().millisecondsSinceEpoch,
      duration: _selectedDurationUnit == 'hours' 
          ? int.parse(_durationController.text) * 60 
          : int.parse(_durationController.text),
      durationUnit: _selectedDurationUnit,
      details: _detailsController.text.trim(),
      idCreatedBy: widget.isEdit ? widget.existingSessionType!.idCreatedBy : currentUserId,
      maxPlayers: int.parse(_maxPlayersController.text),
      minPlayers: int.parse(_minPlayersController.text),
      showParticipants: _showParticipants,
      category: 'tennis',
      price: int.parse(_priceController.text),
      
      // Cancellation Policy
      hasCancellationFee: _hasCancellationFee,
      cancellationTimeBefore: _hasCancellationFee 
          ? (_selectedCancellationTimeUnit == 'hours' 
              ? int.parse(_cancellationTimeController.text) * 60 
              : int.parse(_cancellationTimeController.text))
          : 0,
      cancellationTimeUnit: _selectedCancellationTimeUnit,
      cancellationFeeAmount: _hasCancellationFee 
          ? int.parse(_cancellationFeeController.text)
          : 0,
      cancellationFeeType: _selectedCancellationFeeType,
    );

    if (widget.isEdit) {
      context.read<SessionTypeBloc>().add(UpdateSessionTypeEvent(sessionType: sessionType));
      AppLogger.blocEvent('SessionTypeBloc', 'UpdateSessionTypeEvent', data: {'sessionTypeTitle': sessionType.title});
    } else {
      context.read<SessionTypeBloc>().add(CreateSessionTypeEvent(sessionType: sessionType));
      AppLogger.blocEvent('SessionTypeBloc', 'CreateSessionTypeEvent', data: {'sessionTypeTitle': sessionType.title});
    }
  }
}
