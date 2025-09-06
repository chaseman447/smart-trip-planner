import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/trip.dart';
import '../providers/trip_provider.dart';
import '../widgets/trip_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/error_widget.dart';
import '../../core/constants/app_constants.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripsAsync = ref.watch(tripsListProvider);
    final uiState = ref.watch(uiStateNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Trip Planner'),
        actions: [
          IconButton(
            onPressed: () => _showDebugOverlay(context, ref),
            icon: const Icon(Icons.info_outline),
            tooltip: 'Debug Info',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(tripsListProvider);
        },
        child: tripsAsync.when(
          data: (trips) => _buildTripsList(context, ref, trips),
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
          error: (error, stackTrace) => CustomErrorWidget(
            error: error.toString(),
            onRetry: () => ref.invalidate(tripsListProvider),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/chat'),
        icon: const Icon(Icons.add),
        label: const Text('New Trip'),
      ),
    );
  }

  Widget _buildTripsList(BuildContext context, WidgetRef ref, List<Trip> trips) {
    if (trips.isEmpty) {
      return const EmptyState(
        icon: Icons.luggage,
        title: 'No trips yet',
        subtitle: 'Start planning your first adventure!',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      itemCount: trips.length,
      itemBuilder: (context, index) {
        final trip = trips[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: AppConstants.defaultPadding),
          child: TripCard(
            trip: trip,
            onTap: () => context.push('/trip/${trip.id}'),
            onDelete: () => _showDeleteDialog(context, ref, trip),
          ),
        );
      },
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref, Trip trip) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Trip'),
        content: Text('Are you sure you want to delete "${trip.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(tripNotifierProvider.notifier).deleteTrip(trip.id);
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

  void _showDebugOverlay(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Debug Information'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('App Version: ${AppConstants.appVersion}'),
            const SizedBox(height: 8),
            Text('API Base URL: ${AppConstants.openAiApiUrl}'),
            const SizedBox(height: 8),
            Text('Database: ${AppConstants.databaseName}'),
            const SizedBox(height: 8),
            const Text('Token Usage: Coming soon...'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}