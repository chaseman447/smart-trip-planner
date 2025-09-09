import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/trip.dart';
import '../providers/trip_provider.dart';
import '../widgets/trip_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/error_widget.dart';
import '../widgets/location_permission_widget.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/token_tracking_service.dart';

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
      return const SingleChildScrollView(
        padding: EdgeInsets.all(AppConstants.defaultPadding),
        child: EmptyState(
          icon: Icons.luggage,
          title: 'No trips yet',
          subtitle: 'Start planning your first adventure!',
        ),
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
    final tokenMetrics = ref.read(tokenTrackingServiceProvider);
    final tokenSummary = ref.read(tokenMetricsSummaryProvider);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Debug Information & Token Metrics'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // App Info Section
              const Text(
                'App Information',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text('Version: ${AppConstants.appVersion}'),
              Text('Database: ${AppConstants.databaseName}'),
              const SizedBox(height: 16),
              
              // Token Metrics Section
              const Text(
                'Token Usage Metrics',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              _buildMetricRow('Total Requests:', '${tokenSummary['requestCount']}'),
              _buildMetricRow('Total Tokens:', '${tokenSummary['totalTokens']}'),
              _buildMetricRow('Estimated Cost:', '\$${tokenSummary['totalCost'].toStringAsFixed(4)}'),
              const SizedBox(height: 8),
              
              const Text(
                'Last 24 Hours',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 4),
              _buildMetricRow('Tokens (24h):', '${tokenSummary['tokensLast24h']}'),
              _buildMetricRow('Cost (24h):', '\$${tokenSummary['costLast24h'].toStringAsFixed(4)}'),
              _buildMetricRow('Avg per Request:', '${tokenSummary['averageTokensPerRequest']} tokens'),
              
              if (tokenSummary['lastRequest'] != null) ...[
                 const SizedBox(height: 8),
                 Text(
                   'Last Request: ${_formatDateTime(DateTime.parse(tokenSummary['lastRequest']))}',
                   style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                 ),
               ],
               
               // Recent Usage History
               if (tokenMetrics.usageHistory.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'Recent Usage',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 150,
                  child: ListView.builder(
                    itemCount: tokenMetrics.usageHistory.take(5).length,
                    itemBuilder: (context, index) {
                      final usage = tokenMetrics.usageHistory.reversed.toList()[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 2),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    usage.requestType,
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                  Text('${usage.totalTokens} tokens'),
                                ],
                              ),
                              Text(
                                _formatDateTime(usage.timestamp),
                                style: const TextStyle(fontSize: 11, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              ref.read(tokenTrackingServiceProvider.notifier).clearMetrics();
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Token metrics cleared')),
              );
            },
            child: const Text('Clear Metrics'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMetricRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
  
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')} ${dateTime.day}/${dateTime.month}';
  }
}