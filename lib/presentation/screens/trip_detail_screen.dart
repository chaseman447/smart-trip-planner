import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/services/token_tracking_service.dart';
import '../../domain/entities/trip.dart';
import '../../core/constants/app_constants.dart';
import '../providers/trip_provider.dart';

import '../widgets/empty_state.dart';

class TripDetailScreen extends ConsumerWidget {
  final String tripId;
  final Trip? trip;

  const TripDetailScreen({
    super.key,
    required this.tripId,
    this.trip,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    
    // If trip is not provided, load it using tripId
    if (trip == null) {
      final tripAsync = ref.watch(tripByIdProvider(tripId));
      
      return tripAsync.when(
        data: (loadedTrip) {
          if (loadedTrip == null) {
            return Scaffold(
              appBar: AppBar(
                title: const Text('Trip Details'),
              ),
              body: const Center(
                child: Text('Trip not found'),
              ),
            );
          }
          // Recursively call build with the loaded trip
          return TripDetailScreen(tripId: tripId, trip: loadedTrip).build(context, ref);
        },
        loading: () => Scaffold(
          appBar: AppBar(
            title: const Text('Trip Details'),
          ),
          body: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
        error: (error, stack) => Scaffold(
          appBar: AppBar(
            title: const Text('Trip Details'),
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error loading trip: $error'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.refresh(tripByIdProvider(tripId)),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(trip!.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () => _saveTrip(context, ref),
            tooltip: 'Save Trip',
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareTrip(context),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'edit':
                  _editTrip(context);
                  break;
                case 'delete':
                  _deleteTrip(context);
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
                    Text('Edit Trip'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete Trip', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: trip!.days.isEmpty
          ? const EmptyState(
              icon: Icons.event_note,
              title: 'No Itinerary',
              subtitle: 'This trip doesn\'t have any itinerary items yet.',
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTripHeader(theme),
                  const SizedBox(height: AppConstants.largePadding),
                  _buildItinerary(context, theme),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _startNewChat(context),
        icon: const Icon(Icons.chat),
        label: const Text('Continue Planning'),
      ),
    );
  }

  Widget _buildTripHeader(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${_formatDate(trip!.startDate)} - ${_formatDate(trip!.endDate)}',
                    style: theme.textTheme.titleMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '${trip!.days} days',
                  style: theme.textTheme.bodyLarge,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Consumer(
              builder: (context, ref, child) {
                final tokenSummary = ref.watch(tokenMetricsSummaryProvider);
                final estimatedCost = (trip!.totalTokensUsed * 0.00002).toStringAsFixed(4);
                
                return Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.token,
                          color: theme.colorScheme.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Tokens used: ${trip!.totalTokensUsed} (~\$${estimatedCost})',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (tokenSummary['totalTokens'] > 0) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const SizedBox(width: 28),
                          Expanded(
                            child: Text(
                              'Session total: ${tokenSummary['totalTokens']} tokens (~\$${tokenSummary['totalCost'].toStringAsFixed(4)})',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                                fontSize: 11,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItinerary(BuildContext context, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Itinerary',
          style: theme.textTheme.headlineSmall,
        ),
        const SizedBox(height: AppConstants.defaultPadding),
        ...trip!.days.map((day) => Padding(
              padding: const EdgeInsets.only(bottom: AppConstants.defaultPadding),
              child: _buildDayCard(context, day, theme),
            )),
      ],
    );
  }

  Widget _buildDayCard(BuildContext context, DayItinerary day, ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'Day ${trip!.days.indexOf(day) + 1}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _formatDate(day.date),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              day.summary,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            ...day.items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildItineraryItem(context, item, theme),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildItineraryItem(BuildContext context, ItineraryItem item, ThemeData theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 60,
          padding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 4,
          ),
          decoration: BoxDecoration(
            color: item.time == 'TBD' ? theme.colorScheme.errorContainer : theme.colorScheme.surfaceVariant,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            item.time == 'TBD' ? '⏰' : item.time,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
              color: item.time == 'TBD' ? theme.colorScheme.onErrorContainer : null,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.activity,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: item.location == 'TBD'
                        ? Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.errorContainer,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '📍 Location TBD',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onErrorContainer,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          )
                        : _isValidCoordinates(item.location)
                            ? InkWell(
                                onTap: () => _openInMaps(context, item.location),
                                borderRadius: BorderRadius.circular(4),
                                child: Text(
                                  item.location,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.primary,
                                    decoration: TextDecoration.underline,
                                    decorationColor: theme.colorScheme.primary,
                                  ),
                                ),
                              )
                            : Text(
                                item.location,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                  ),
                ],
              ),
              if (item.description != null) ...[
                const SizedBox(height: 4),
                Text(
                  item.description!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  bool _isValidCoordinates(String location) {
    if (location == '0,0') return false;
    final parts = location.split(',');
    if (parts.length != 2) return false;
    
    try {
      final lat = double.parse(parts[0].trim());
      final lng = double.parse(parts[1].trim());
      return lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180;
    } catch (e) {
      return false;
    }
  }

  Future<void> _openInMaps(BuildContext context, String coordinates) async {
    print('DEBUG: Attempting to open coordinates: $coordinates');
    
    final parts = coordinates.split(',');
    if (parts.length != 2) {
      print('DEBUG: Invalid coordinate format: $coordinates');
      _showLocationError(context, 'Invalid coordinate format');
      return;
    }
    
    final lat = parts[0].trim();
    final lng = parts[1].trim();
    
    print('DEBUG: Parsed coordinates - lat: $lat, lng: $lng');
    
    // Try different map URLs in order of preference
    final urls = [
      'https://maps.apple.com/?q=$lat,$lng', // Apple Maps (iOS)
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng', // Google Maps (web)
      'geo:$lat,$lng', // Generic geo URI
    ];
    
    bool launched = false;
    for (final urlString in urls) {
      print('DEBUG: Trying URL: $urlString');
      final uri = Uri.parse(urlString);
      if (await canLaunchUrl(uri)) {
        print('DEBUG: Successfully launching: $urlString');
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        launched = true;
        return;
      } else {
        print('DEBUG: Cannot launch: $urlString');
      }
    }
    
    if (!launched) {
      print('DEBUG: No map app could handle the coordinates');
      _showLocationError(context, 'No map app available to open location');
    }
  }
  
  void _showLocationError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  void _shareTrip(BuildContext context) {
    // TODO: Implement trip sharing
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Trip sharing coming soon!'),
      ),
    );
  }

  void _editTrip(BuildContext context) {
    // TODO: Navigate to edit trip screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Trip editing coming soon!'),
      ),
    );
  }

  void _deleteTrip(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Trip'),
        content: const Text('Are you sure you want to delete this trip? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Implement trip deletion
              context.pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Trip deletion coming soon!'),
                ),
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _startNewChat(BuildContext context) {
    context.push('/chat', extra: trip);
  }

  Future<void> _saveTrip(BuildContext context, WidgetRef ref) async {
    if (trip == null) return;
    
    try {
      await ref.read(tripNotifierProvider.notifier).saveTrip(trip!);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Trip saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save trip: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}