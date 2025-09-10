import 'package:flutter/material.dart';
import '../../domain/entities/trip.dart';

class ItineraryDiffWidget extends StatelessWidget {
  final Trip? oldTrip;
  final Trip newTrip;
  final bool showChangesOnly;

  const ItineraryDiffWidget({
    Key? key,
    this.oldTrip,
    required this.newTrip,
    this.showChangesOnly = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (oldTrip == null) {
      // No previous version, show all as new
      return _buildNewItinerary(theme);
    }
    
    final changes = _calculateChanges(oldTrip!, newTrip);
    
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (changes.hasChanges) ...[
            _buildChangeSummary(theme, changes),
            const SizedBox(height: 16),
          ],
          ...newTrip.days.asMap().entries.map((entry) {
            final dayIndex = entry.key;
            final day = entry.value;
            final oldDay = dayIndex < oldTrip!.days.length ? oldTrip!.days[dayIndex] : null;
            
            return _buildDayDiff(theme, day, oldDay, dayIndex, changes);
          }),
        ],
      ),
    );
  }

  Widget _buildNewItinerary(ThemeData theme) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.add_circle, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                Text(
                  'New itinerary created',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: _getShadeColor(Colors.green, 700),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ...newTrip.days.asMap().entries.map((entry) {
            final day = entry.value;
            return _buildDayCard(theme, day, ChangeType.added);
          }),
        ],
      ),
    );
  }

  Widget _buildChangeSummary(ThemeData theme, ItineraryChanges changes) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.compare_arrows, color: theme.colorScheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Itinerary Changes',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 16,
            children: [
              if (changes.addedItems > 0)
                _buildChangeChip(theme, '${changes.addedItems} added', Colors.green),
              if (changes.modifiedItems > 0)
                _buildChangeChip(theme, '${changes.modifiedItems} modified', Colors.orange),
              if (changes.removedItems > 0)
                _buildChangeChip(theme, '${changes.removedItems} removed', Colors.red),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChangeChip(ThemeData theme, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: theme.textTheme.bodySmall?.copyWith(
          color: _getShadeColor(color, 700),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildDayDiff(ThemeData theme, DayItinerary day, DayItinerary? oldDay, int dayIndex, ItineraryChanges changes) {
    final dayChanges = _calculateDayChanges(day, oldDay);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Day header with change indicator
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _getChangeColor(dayChanges.changeType).withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
              border: Border.all(
                color: _getChangeColor(dayChanges.changeType).withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                _getChangeIcon(dayChanges.changeType),
                const SizedBox(width: 8),
                Text(
                '${day.date.day}/${day.date.month}/${day.date.year}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (dayChanges.hasChanges) ...[
                  const Spacer(),
                  Text(
                    '${dayChanges.itemChanges} changes',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: _getShadeColor(_getChangeColor(dayChanges.changeType), 700),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // Day items
          Container(
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
              border: Border(
                left: BorderSide(color: _getChangeColor(dayChanges.changeType).withOpacity(0.3)),
                right: BorderSide(color: _getChangeColor(dayChanges.changeType).withOpacity(0.3)),
                bottom: BorderSide(color: _getChangeColor(dayChanges.changeType).withOpacity(0.3)),
              ),
            ),
            child: Column(
              children: day.items.map((item) {
                final oldItem = _findMatchingItem(item, oldDay?.items ?? []);
                final itemChangeType = _getItemChangeType(item, oldItem);
                
                return _buildItemDiff(theme, item, oldItem, itemChangeType);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayCard(ThemeData theme, DayItinerary day, ChangeType changeType) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _getChangeColor(changeType).withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _getChangeColor(changeType).withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: Row(
              children: [
                _getChangeIcon(changeType),
                const SizedBox(width: 8),
                Text(
                '${day.date.day}/${day.date.month}/${day.date.year}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ...day.items.map((item) => _buildItemDiff(theme, item, null, changeType)),
        ],
      ),
    );
  }

  Widget _buildItemDiff(ThemeData theme, ItineraryItem item, ItineraryItem? oldItem, ChangeType changeType) {
    final hasChanges = changeType != ChangeType.unchanged;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: hasChanges ? _getChangeColor(changeType).withOpacity(0.05) : null,
        border: hasChanges ? Border(
          left: BorderSide(
            color: _getChangeColor(changeType),
            width: 3,
          ),
        ) : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time
          Container(
            width: 60,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: hasChanges 
                  ? _getChangeColor(changeType).withOpacity(0.1)
                  : theme.colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(8),
              border: hasChanges ? Border.all(
                color: _getChangeColor(changeType).withOpacity(0.3),
              ) : null,
            ),
            child: Text(
              item.time,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
                color: hasChanges ? _getShadeColor(_getChangeColor(changeType), 700) : null,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 12),
          
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (hasChanges) ...[
                      _getChangeIcon(changeType, size: 16),
                      const SizedBox(width: 4),
                    ],
                    Expanded(
                      child: Text(
                        item.activity,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: hasChanges ? _getShadeColor(_getChangeColor(changeType), 700) : null,
                          decoration: changeType == ChangeType.removed 
                              ? TextDecoration.lineThrough 
                              : null,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 16,
                      color: hasChanges 
                          ? _getShadeColor(_getChangeColor(changeType), 600)
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        item.location,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: hasChanges 
                              ? _getShadeColor(_getChangeColor(changeType), 600)
                              : theme.colorScheme.onSurfaceVariant,
                          decoration: changeType == ChangeType.removed 
                              ? TextDecoration.lineThrough 
                              : null,
                        ),
                      ),
                    ),
                  ],
                ),
                
                // Description
                if (item.description != null && item.description!.isNotEmpty) ...[  
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.description,
                        size: 16,
                        color: hasChanges 
                            ? _getShadeColor(_getChangeColor(changeType), 600)
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          item.description!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: hasChanges 
                                ? _getShadeColor(_getChangeColor(changeType), 600)
                                : theme.colorScheme.onSurfaceVariant,
                            decoration: changeType == ChangeType.removed 
                                ? TextDecoration.lineThrough 
                                : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                
                // Cost
                if (item.cost != null && item.cost!.isNotEmpty) ...[  
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.attach_money,
                        size: 16,
                        color: hasChanges 
                            ? _getShadeColor(_getChangeColor(changeType), 600)
                            : Colors.green.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        item.cost!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: hasChanges 
                              ? _getShadeColor(_getChangeColor(changeType), 600)
                              : Colors.green.shade600,
                          fontWeight: FontWeight.w500,
                          decoration: changeType == ChangeType.removed 
                              ? TextDecoration.lineThrough 
                              : null,
                        ),
                      ),
                    ],
                  ),
                ],
                
                // Notes
                if (item.notes != null && item.notes!.isNotEmpty) ...[  
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.note,
                        size: 16,
                        color: hasChanges 
                            ? _getShadeColor(_getChangeColor(changeType), 600)
                            : Colors.orange.shade600,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          item.notes!,
                          style: theme.textTheme.bodySmall?.copyWith(
                             color: hasChanges 
                                 ? _getShadeColor(_getChangeColor(changeType), 600)
                                 : Colors.orange.shade600,
                             fontStyle: FontStyle.italic,
                             decoration: changeType == ChangeType.removed 
                                 ? TextDecoration.lineThrough 
                                 : null,
                           ),
                        ),
                      ),
                    ],
                  ),
                ],
                
                // Show old vs new for modified items
                if (changeType == ChangeType.modified && oldItem != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Previous:',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${oldItem.time} - ${oldItem.activity}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade600,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        Text(
                          oldItem.location,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade600,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  ItineraryChanges _calculateChanges(Trip oldTrip, Trip newTrip) {
    int addedItems = 0;
    int modifiedItems = 0;
    int removedItems = 0;

    // Count items in new trip
    for (final newDay in newTrip.days) {
      for (final newItem in newDay.items) {
        final oldDay = _findDayByDate(oldTrip.days, newDay.date);
        final oldItem = _findMatchingItem(newItem, oldDay?.items ?? []);
        
        if (oldItem == null) {
          addedItems++;
        } else if (_itemsAreDifferent(newItem, oldItem)) {
          modifiedItems++;
        }
      }
    }

    // Count removed items
    for (final oldDay in oldTrip.days) {
      for (final oldItem in oldDay.items) {
        final newDay = _findDayByDate(newTrip.days, oldDay.date);
        final newItem = _findMatchingItem(oldItem, newDay?.items ?? []);
        
        if (newItem == null) {
          removedItems++;
        }
      }
    }

    return ItineraryChanges(
      addedItems: addedItems,
      modifiedItems: modifiedItems,
      removedItems: removedItems,
    );
  }

  DayChanges _calculateDayChanges(DayItinerary day, DayItinerary? oldDay) {
    if (oldDay == null) {
      return DayChanges(
        changeType: ChangeType.added,
        itemChanges: day.items.length,
      );
    }

    int changes = 0;
    ChangeType overallType = ChangeType.unchanged;

    for (final item in day.items) {
      final oldItem = _findMatchingItem(item, oldDay.items);
      if (oldItem == null) {
        changes++;
        overallType = ChangeType.modified;
      } else if (_itemsAreDifferent(item, oldItem)) {
        changes++;
        overallType = ChangeType.modified;
      }
    }

    for (final oldItem in oldDay.items) {
      final newItem = _findMatchingItem(oldItem, day.items);
      if (newItem == null) {
        changes++;
        overallType = ChangeType.modified;
      }
    }

    return DayChanges(
      changeType: overallType,
      itemChanges: changes,
    );
  }

  ChangeType _getItemChangeType(ItineraryItem item, ItineraryItem? oldItem) {
    if (oldItem == null) {
      return ChangeType.added;
    }
    if (_itemsAreDifferent(item, oldItem)) {
      return ChangeType.modified;
    }
    return ChangeType.unchanged;
  }

  DayItinerary? _findDayByDate(List<DayItinerary> days, DateTime date) {
    try {
      return days.firstWhere((day) => 
        day.date.year == date.year && 
        day.date.month == date.month && 
        day.date.day == date.day
      );
    } catch (e) {
      return null;
    }
  }

  ItineraryItem? _findMatchingItem(ItineraryItem item, List<ItineraryItem> items) {
    // Try to find by activity name first (most reliable)
    for (final candidate in items) {
      if (candidate.activity.toLowerCase().trim() == item.activity.toLowerCase().trim()) {
        return candidate;
      }
    }
    
    // Try to find by time if activity doesn't match
    for (final candidate in items) {
      if (candidate.time == item.time) {
        return candidate;
      }
    }
    
    return null;
  }

  bool _itemsAreDifferent(ItineraryItem item1, ItineraryItem item2) {
    return item1.time != item2.time ||
           item1.activity != item2.activity ||
           item1.location != item2.location;
  }

  Color _getChangeColor(ChangeType changeType) {
    switch (changeType) {
      case ChangeType.added:
        return Colors.green;
      case ChangeType.modified:
        return Colors.orange;
      case ChangeType.removed:
        return Colors.red;
      case ChangeType.unchanged:
        return Colors.grey;
    }
  }

  Widget _getChangeIcon(ChangeType changeType, {double size = 20}) {
    switch (changeType) {
      case ChangeType.added:
        return Icon(Icons.add_circle, color: Colors.green, size: size);
      case ChangeType.modified:
        return Icon(Icons.edit, color: Colors.orange, size: size);
      case ChangeType.removed:
        return Icon(Icons.remove_circle, color: Colors.red, size: size);
      case ChangeType.unchanged:
        return Icon(Icons.check_circle, color: Colors.grey, size: size);
    }
  }

  Color _getShadeColor(Color color, int shade) {
    if (color == Colors.green) {
      return Colors.green.shade700;
    } else if (color == Colors.orange) {
      return Colors.orange.shade700;
    } else if (color == Colors.red) {
      return Colors.red.shade700;
    } else if (color == Colors.grey) {
      return Colors.grey.shade700;
    }
    
    // Fallback: create a darker version of the color
    final hsl = HSLColor.fromColor(color);
    return hsl.withLightness((hsl.lightness * 0.7).clamp(0.0, 1.0)).toColor();
  }
}

enum ChangeType {
  added,
  modified,
  removed,
  unchanged,
}

class ItineraryChanges {
  final int addedItems;
  final int modifiedItems;
  final int removedItems;

  ItineraryChanges({
    required this.addedItems,
    required this.modifiedItems,
    required this.removedItems,
  });

  bool get hasChanges => addedItems > 0 || modifiedItems > 0 || removedItems > 0;
}

class DayChanges {
  final ChangeType changeType;
  final int itemChanges;

  DayChanges({
    required this.changeType,
    required this.itemChanges,
  });

  bool get hasChanges => itemChanges > 0;
}