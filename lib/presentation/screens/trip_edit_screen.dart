import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/trip.dart';
import '../../core/constants/app_constants.dart';
import '../providers/trip_provider.dart';

class TripEditScreen extends ConsumerStatefulWidget {
  final Trip trip;

  const TripEditScreen({super.key, required this.trip});

  @override
  ConsumerState<TripEditScreen> createState() => _TripEditScreenState();
}

class _TripEditScreenState extends ConsumerState<TripEditScreen> {
  late Trip _editedTrip;
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _editedTrip = widget.trip.copyWith();
    _titleController = TextEditingController(text: widget.trip.title);
    _descriptionController = TextEditingController(text: widget.trip.description ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _markAsChanged() {
    if (!_hasChanges) {
      setState(() {
        _hasChanges = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: !_hasChanges,
      onPopInvoked: (didPop) {
        if (!didPop && _hasChanges) {
          _showUnsavedChangesDialog(context);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Edit Trip'),
          actions: [
            if (_hasChanges)
              TextButton(
                onPressed: _saveTrip,
                child: const Text('Save'),
              ),
          ],
        ),
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTripBasicInfo(theme),
                const SizedBox(height: AppConstants.largePadding),
                _buildItinerarySection(theme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTripBasicInfo(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Trip Details',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Trip Title',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a trip title';
                }
                return null;
              },
              onChanged: (value) {
                _editedTrip = _editedTrip.copyWith(title: value);
                _markAsChanged();
              },
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              onChanged: (value) {
                _editedTrip = _editedTrip.copyWith(description: value.isEmpty ? null : value);
                _markAsChanged();
              },
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    leading: const Icon(Icons.calendar_today),
                    title: const Text('Start Date'),
                    subtitle: Text(_formatDate(_editedTrip.startDate)),
                    onTap: () => _selectDate(context, true),
                  ),
                ),
                Expanded(
                  child: ListTile(
                    leading: const Icon(Icons.calendar_today),
                    title: const Text('End Date'),
                    subtitle: Text(_formatDate(_editedTrip.endDate)),
                    onTap: () => _selectDate(context, false),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItinerarySection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Itinerary',
              style: theme.textTheme.headlineSmall,
            ),
            ElevatedButton.icon(
              onPressed: _addNewDay,
              icon: const Icon(Icons.add),
              label: const Text('Add Day'),
            ),
          ],
        ),
        const SizedBox(height: AppConstants.defaultPadding),
        ..._editedTrip.days.asMap().entries.map((entry) {
          final dayIndex = entry.key;
          final day = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: AppConstants.defaultPadding),
            child: _buildEditableDayCard(day, dayIndex, theme),
          );
        }),
      ],
    );
  }

  Widget _buildEditableDayCard(DayItinerary day, int dayIndex, ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Day ${dayIndex + 1} - ${_formatDate(day.date)}',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: () => _addActivity(dayIndex),
                      icon: const Icon(Icons.add_circle_outline),
                      tooltip: 'Add Activity',
                    ),
                    if (_editedTrip.days.length > 1)
                      IconButton(
                        onPressed: () => _removeDay(dayIndex),
                        icon: const Icon(Icons.delete_outline),
                        tooltip: 'Remove Day',
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            ...day.items.asMap().entries.map((entry) {
              final itemIndex = entry.key;
              final item = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildEditableItineraryItem(item, dayIndex, itemIndex, theme),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildEditableItineraryItem(ItineraryItem item, int dayIndex, int itemIndex, ThemeData theme) {
    return Card(
      color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.activity,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        _editActivity(dayIndex, itemIndex);
                        break;
                      case 'delete':
                        _removeActivity(dayIndex, itemIndex);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildItemDetail(Icons.access_time, item.time, theme),
            _buildItemDetail(Icons.location_on, item.location, theme),
            if (item.description != null && item.description!.isNotEmpty)
              _buildItemDetail(Icons.description, item.description!, theme),
            if (item.cost != null && item.cost!.isNotEmpty)
              _buildItemDetail(Icons.attach_money, item.cost!, theme),
            if (item.notes != null && item.notes!.isNotEmpty)
              _buildItemDetail(Icons.note, item.notes!, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildItemDetail(IconData icon, String text, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _selectDate(BuildContext context, bool isStartDate) async {
    final initialDate = isStartDate ? _editedTrip.startDate : _editedTrip.endDate;
    final firstDate = isStartDate ? DateTime.now() : _editedTrip.startDate;
    final lastDate = DateTime.now().add(const Duration(days: 365 * 2));

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (selectedDate != null) {
      setState(() {
        if (isStartDate) {
          _editedTrip = _editedTrip.copyWith(startDate: selectedDate);
          // Adjust end date if it's before start date
          if (_editedTrip.endDate.isBefore(selectedDate)) {
            _editedTrip = _editedTrip.copyWith(endDate: selectedDate);
          }
        } else {
          _editedTrip = _editedTrip.copyWith(endDate: selectedDate);
        }
        _markAsChanged();
      });
    }
  }

  void _addNewDay() {
    final newDate = _editedTrip.days.isNotEmpty
        ? _editedTrip.days.last.date.add(const Duration(days: 1))
        : _editedTrip.startDate;

    final newDay = DayItinerary(
      date: newDate,
      summary: '',
      items: [],
    );

    setState(() {
      _editedTrip = _editedTrip.copyWith(
        days: [..._editedTrip.days, newDay],
      );
      _markAsChanged();
    });
  }

  void _removeDay(int dayIndex) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Day'),
        content: const Text('Are you sure you want to remove this day and all its activities?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                final newDays = List<DayItinerary>.from(_editedTrip.days);
                newDays.removeAt(dayIndex);
                _editedTrip = _editedTrip.copyWith(days: newDays);
                _markAsChanged();
              });
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _addActivity(int dayIndex) {
    _showActivityDialog(dayIndex: dayIndex);
  }

  void _editActivity(int dayIndex, int itemIndex) {
    _showActivityDialog(dayIndex: dayIndex, itemIndex: itemIndex);
  }

  void _removeActivity(int dayIndex, int itemIndex) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Activity'),
        content: const Text('Are you sure you want to remove this activity?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                final newDays = List<DayItinerary>.from(_editedTrip.days);
                final newItems = List<ItineraryItem>.from(newDays[dayIndex].items);
                newItems.removeAt(itemIndex);
                newDays[dayIndex] = newDays[dayIndex].copyWith(items: newItems);
                _editedTrip = _editedTrip.copyWith(days: newDays);
                _markAsChanged();
              });
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _showActivityDialog({required int dayIndex, int? itemIndex}) {
    final isEditing = itemIndex != null;
    final existingItem = isEditing ? _editedTrip.days[dayIndex].items[itemIndex] : null;

    final timeController = TextEditingController(text: existingItem?.time ?? '');
    final activityController = TextEditingController(text: existingItem?.activity ?? '');
    final locationController = TextEditingController(text: existingItem?.location ?? '');
    final descriptionController = TextEditingController(text: existingItem?.description ?? '');
    final costController = TextEditingController(text: existingItem?.cost ?? '');
    final notesController = TextEditingController(text: existingItem?.notes ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'Edit Activity' : 'Add Activity'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: timeController,
                decoration: const InputDecoration(
                  labelText: 'Time (e.g., 09:00)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: activityController,
                decoration: const InputDecoration(
                  labelText: 'Activity *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: locationController,
                decoration: const InputDecoration(
                  labelText: 'Location',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: costController,
                decoration: const InputDecoration(
                  labelText: 'Cost',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (activityController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Activity name is required')),
                );
                return;
              }

              final newItem = ItineraryItem(
                time: timeController.text.trim().isEmpty ? 'TBD' : timeController.text.trim(),
                activity: activityController.text.trim(),
                location: locationController.text.trim().isEmpty ? 'TBD' : locationController.text.trim(),
                description: descriptionController.text.trim().isEmpty ? null : descriptionController.text.trim(),
                cost: costController.text.trim().isEmpty ? null : costController.text.trim(),
                notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
              );

              setState(() {
                final newDays = List<DayItinerary>.from(_editedTrip.days);
                final newItems = List<ItineraryItem>.from(newDays[dayIndex].items);
                
                if (isEditing) {
                  newItems[itemIndex] = newItem;
                } else {
                  newItems.add(newItem);
                }
                
                newDays[dayIndex] = newDays[dayIndex].copyWith(items: newItems);
                _editedTrip = _editedTrip.copyWith(days: newDays);
                _markAsChanged();
              });

              Navigator.of(context).pop();
            },
            child: Text(isEditing ? 'Update' : 'Add'),
          ),
        ],
      ),
    );
  }

  void _saveTrip() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      await ref.read(tripNotifierProvider.notifier).saveTrip(_editedTrip);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Trip updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        
        setState(() {
          _hasChanges = false;
        });
        
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update trip: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showUnsavedChangesDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unsaved Changes'),
        content: const Text('You have unsaved changes. Do you want to save them before leaving?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.pop(); // Go back without saving
            },
            child: const Text('Discard'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _saveTrip();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}