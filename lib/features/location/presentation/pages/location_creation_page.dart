import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/core/utils/logger.dart';
import 'package:myapp/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:myapp/features/auth/presentation/bloc/auth_state.dart';
import 'package:myapp/features/location/domain/entities/location_entity.dart';
import 'package:myapp/features/location/presentation/bloc/location_bloc.dart';
import 'package:myapp/features/location/presentation/bloc/location_event.dart';

class LocationCreationPage extends StatefulWidget {
  final LocationEntity? existingLocation;
  final bool isEdit;

  const LocationCreationPage({
    super.key,
    this.existingLocation,
    this.isEdit = false,
  });

  @override
  State<LocationCreationPage> createState() => _LocationCreationPageState();
}

class _LocationCreationPageState extends State<LocationCreationPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();

  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    _populateForm();
  }

  void _populateForm() {
    if (widget.isEdit && widget.existingLocation != null) {
      final location = widget.existingLocation!;
      _nameController.text = location.name;
      _descriptionController.text = location.description ?? '';
      _addressController.text = location.address ?? '';
      _latitudeController.text = location.latitude?.toString() ?? '';
      _longitudeController.text = location.longitude?.toString() ?? '';
      _isActive = location.isActive;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    AppLogger.widgetBuild('LocationCreationPage', data: {'action': 'build', 'isEdit': widget.isEdit});

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEdit ? 'Edit Location' : 'Create Location'),
        backgroundColor: Colors.green[600],
        foregroundColor: Colors.white,
        leading: IconButton(
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              context.pop();
            } else {
              context.go('/locations');
            }
          },
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBasicInfoSection(),
              const SizedBox(height: 24),
              _buildLocationDetailsSection(),
              const SizedBox(height: 24),
              _buildStatusSection(),
              const SizedBox(height: 100), // Space for floating button
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saveLocation,
        icon: Icon(widget.isEdit ? Icons.update : Icons.add),
        label: Text(widget.isEdit ? 'Update Location' : 'Create Location'),
        backgroundColor: Colors.green[600],
        foregroundColor: Colors.white,
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
            Text(
              'Basic Information',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Location Name *',
                border: OutlineInputBorder(),
                hintText: 'e.g., Main Court, Studio A',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Location name is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
                hintText: 'Optional description of the location',
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationDetailsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Location Details',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Address',
                border: OutlineInputBorder(),
                hintText: 'Street address, city, state, zip code',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _latitudeController,
                    decoration: const InputDecoration(
                      labelText: 'Latitude',
                      border: OutlineInputBorder(),
                      hintText: 'e.g., 40.7128',
                    ),
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        final lat = double.tryParse(value);
                        if (lat == null || lat < -90 || lat > 90) {
                          return 'Latitude must be between -90 and 90';
                        }
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _longitudeController,
                    decoration: const InputDecoration(
                      labelText: 'Longitude',
                      border: OutlineInputBorder(),
                      hintText: 'e.g., -74.0060',
                    ),
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        final lng = double.tryParse(value);
                        if (lng == null || lng < -180 || lng > 180) {
                          return 'Longitude must be between -180 and 180';
                        }
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'GPS coordinates are optional but help with location-based features',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
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
            Text(
              'Status',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Active'),
              subtitle: const Text('Inactive locations won\'t be available for booking'),
              value: _isActive,
              onChanged: (value) {
                setState(() {
                  _isActive = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  void _saveLocation() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authBloc = context.read<AuthBloc>();
    final authState = authBloc.state;
    String currentUserId = 'unknown_user';

    if (authState is AuthAuthenticated) {
      currentUserId = authState.user.id;
    }

    final location = LocationEntity(
      id: widget.isEdit ? widget.existingLocation!.id : null,
      instructorId: widget.isEdit ? widget.existingLocation!.instructorId : currentUserId,
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
      address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
      latitude: _latitudeController.text.trim().isEmpty ? null : double.tryParse(_latitudeController.text.trim()),
      longitude: _longitudeController.text.trim().isEmpty ? null : double.tryParse(_longitudeController.text.trim()),
      isActive: _isActive,
      createdAt: widget.isEdit ? widget.existingLocation!.createdAt : DateTime.now(),
      updatedAt: DateTime.now(),
    );

    if (widget.isEdit) {
      context.read<LocationBloc>().add(UpdateLocationEvent(location: location));
    } else {
      context.read<LocationBloc>().add(CreateLocationEvent(location: location));
    }

    AppLogger.blocEvent(
      'LocationBloc',
      widget.isEdit ? 'UpdateLocationEvent' : 'CreateLocationEvent',
      data: {'locationId': location.id, 'locationName': location.name},
    );

    // Navigate back to management page
    context.go('/locations');
  }
}
