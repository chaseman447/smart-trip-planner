import '../../domain/entities/trip.dart';

class OfflineTripService {
  /// Generate a basic trip plan when AI services are unavailable
  static Trip generateBasicTrip(String userPrompt) {
    final now = DateTime.now();
    
    // Extract and improvise missing details
    final destination = _extractDestination(userPrompt);
    final duration = _extractDuration(userPrompt);
    final preferences = _extractPreferences(userPrompt);
    
    // Smart defaults for missing information
    final finalDestination = destination.isNotEmpty ? destination : _getPopularDestination();
    final finalDuration = duration > 0 ? duration : 3; // Default 3 days
    
    final startDate = _extractStartDate(userPrompt) ?? now.add(const Duration(days: 1));
    final endDate = startDate.add(Duration(days: finalDuration - 1));
    
    // Generate dynamic itinerary based on preferences and destination
    final days = _generateDynamicItinerary(finalDestination, startDate, finalDuration, preferences);
    
    return Trip(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'Trip to $finalDestination',
      startDate: startDate,
      endDate: endDate,
      days: days,
      createdAt: DateTime.now(),
    );
  }
  
  /// Generate a basic chat response when AI services are unavailable
  static String generateBasicChatResponse(String userMessage) {
    final message = userMessage.toLowerCase();
    
    if (message.contains('hello') || message.contains('hi')) {
      return 'Hello! I\'m currently in offline mode due to network connectivity issues. I can still help you with basic trip planning. Try asking me to plan a trip to a specific destination!';
    }
    
    if (message.contains('trip') || message.contains('travel') || message.contains('plan')) {
      return 'I\'d be happy to help you plan a trip! Even in offline mode, I can create a basic itinerary. Please specify your destination (e.g., "Plan a trip to Tokyo") and I\'ll generate a simple 2-day itinerary for you.';
    }
    
    if (message.contains('weather')) {
      return 'I\'m currently unable to access real-time weather information due to network connectivity issues. Please check a weather app or website for current conditions at your destination.';
    }
    
    if (message.contains('currency') || message.contains('exchange')) {
      return 'I\'m currently unable to access real-time currency exchange rates due to network connectivity issues. Please check a financial app or website for current exchange rates.';
    }
    
    return 'I\'m currently in offline mode due to network connectivity issues. I can help with basic trip planning - just tell me where you\'d like to go! For detailed information, please check your internet connection and try again when online.';
  }
  
  // Helper methods for extracting information from user prompts
  static String _extractDestination(String prompt) {
    final lowerPrompt = prompt.toLowerCase();
    
    // Common destinations with variations
    final destinations = {
      'tokyo': 'Tokyo, Japan',
      'paris': 'Paris, France', 
      'london': 'London, UK',
      'new york': 'New York, USA',
      'nyc': 'New York, USA',
      'rome': 'Rome, Italy',
      'barcelona': 'Barcelona, Spain',
      'amsterdam': 'Amsterdam, Netherlands',
      'berlin': 'Berlin, Germany',
      'madrid': 'Madrid, Spain',
      'vienna': 'Vienna, Austria',
      'prague': 'Prague, Czech Republic',
      'budapest': 'Budapest, Hungary',
      'istanbul': 'Istanbul, Turkey',
      'dubai': 'Dubai, UAE',
      'singapore': 'Singapore',
      'bangkok': 'Bangkok, Thailand',
      'seoul': 'Seoul, South Korea',
      'sydney': 'Sydney, Australia',
      'melbourne': 'Melbourne, Australia',
    };
    
    for (final entry in destinations.entries) {
      if (lowerPrompt.contains(entry.key)) {
        return entry.value;
      }
    }
    
    return '';
  }
  
  static int _extractDuration(String prompt) {
    final lowerPrompt = prompt.toLowerCase();
    
    // Look for explicit duration
    final durationRegex = RegExp(r'(\d+)\s*(day|days|night|nights)');
    final match = durationRegex.firstMatch(lowerPrompt);
    if (match != null) {
      return int.tryParse(match.group(1)!) ?? 0;
    }
    
    // Common duration phrases
    if (lowerPrompt.contains('weekend')) return 2;
    if (lowerPrompt.contains('long weekend')) return 3;
    if (lowerPrompt.contains('week')) return 7;
    if (lowerPrompt.contains('short trip')) return 2;
    if (lowerPrompt.contains('quick trip')) return 1;
    
    return 0;
  }
  
  static List<String> _extractPreferences(String prompt) {
    final lowerPrompt = prompt.toLowerCase();
    final preferences = <String>[];
    
    if (lowerPrompt.contains('adventure') || lowerPrompt.contains('hiking') || lowerPrompt.contains('outdoor')) {
      preferences.add('adventure');
    }
    if (lowerPrompt.contains('culture') || lowerPrompt.contains('museum') || lowerPrompt.contains('history')) {
      preferences.add('cultural');
    }
    if (lowerPrompt.contains('food') || lowerPrompt.contains('restaurant') || lowerPrompt.contains('cuisine')) {
      preferences.add('food');
    }
    if (lowerPrompt.contains('relax') || lowerPrompt.contains('spa') || lowerPrompt.contains('beach')) {
      preferences.add('relaxation');
    }
    if (lowerPrompt.contains('nightlife') || lowerPrompt.contains('bars') || lowerPrompt.contains('party')) {
      preferences.add('nightlife');
    }
    if (lowerPrompt.contains('shopping') || lowerPrompt.contains('market')) {
      preferences.add('shopping');
    }
    
    return preferences;
  }
  
  static String _getPopularDestination() {
    final destinations = [
      'Paris, France',
      'Tokyo, Japan', 
      'London, UK',
      'New York, USA',
      'Rome, Italy',
      'Barcelona, Spain',
    ];
    
    // Return a random popular destination
    final now = DateTime.now();
    return destinations[now.millisecond % destinations.length];
  }

  static String _getCoordinatesForDestination(String destination) {
    // Map of popular destinations to their approximate coordinates
    final coordinatesMap = {
      'Paris, France': '48.8566,2.3522',
      'Tokyo, Japan': '35.6762,139.6503',
      'London, UK': '51.5074,-0.1278',
      'New York, USA': '40.7128,-74.0060',
      'Rome, Italy': '41.9028,12.4964',
      'Barcelona, Spain': '41.3851,2.1734',
      'Amsterdam, Netherlands': '52.3676,4.9041',
      'Berlin, Germany': '52.5200,13.4050',
      'Sydney, Australia': '-33.8688,151.2093',
      'Dubai, UAE': '25.2048,55.2708',
    };
    
    // Check if we have coordinates for this destination
    for (final entry in coordinatesMap.entries) {
      if (destination.toLowerCase().contains(entry.key.toLowerCase().split(',')[0])) {
        return entry.value;
      }
    }
    
    // Default coordinates for unknown destinations (Central Park, NYC)
    return '40.7829,-73.9654';
  }
  
  static DateTime? _extractStartDate(String prompt) {
    final lowerPrompt = prompt.toLowerCase();
    final now = DateTime.now();
    
    if (lowerPrompt.contains('tomorrow')) {
      return now.add(const Duration(days: 1));
    }
    if (lowerPrompt.contains('next week')) {
      return now.add(const Duration(days: 7));
    }
    if (lowerPrompt.contains('next weekend')) {
      final daysUntilSaturday = (6 - now.weekday) % 7;
      return now.add(Duration(days: daysUntilSaturday == 0 ? 7 : daysUntilSaturday));
    }
    
    return null; // Use default
   }
   
   static List<DayItinerary> _generateDynamicItinerary(
     String destination, 
     DateTime startDate, 
     int duration, 
     List<String> preferences
   ) {
     final days = <DayItinerary>[];
     
     for (int i = 0; i < duration; i++) {
       final currentDate = startDate.add(Duration(days: i));
       final isFirstDay = i == 0;
       final isLastDay = i == duration - 1;
       
       String summary;
       List<ItineraryItem> items;
       
       if (isFirstDay) {
         summary = 'Arrival and Initial Exploration';
         items = _getArrivalDayActivities(destination, preferences);
       } else if (isLastDay) {
         summary = 'Final Day and Departure';
         items = _getDepartureDayActivities(destination, preferences);
       } else {
         summary = _getDaySummary(i + 1, preferences);
         items = _getRegularDayActivities(destination, preferences, i + 1);
       }
       
       days.add(DayItinerary(
         date: currentDate,
         summary: summary,
         items: items,
       ));
     }
     
     return days;
   }
   
   static List<ItineraryItem> _getArrivalDayActivities(String destination, List<String> preferences) {
     final coordinates = _getCoordinatesForDestination(destination);
     final activities = <ItineraryItem>[
       ItineraryItem(
         time: '09:00',
         activity: 'Arrive at $destination Airport/Station',
         location: '$destination Transportation Hub',
         description: 'Arrive at your destination and complete immigration/customs procedures. Collect your luggage and get oriented with the local transportation system.',
         cost: 'Transportation from airport: \$15-50',
         notes: 'Have local currency ready, download offline maps, keep important documents accessible',
         latitude: double.tryParse(coordinates.split(',')[0]),
         longitude: double.tryParse(coordinates.split(',')[1]),
       ),
       ItineraryItem(
         time: '11:00',
         activity: 'Check into accommodation and freshen up',
         location: '$destination City Center',
         description: 'Check into your hotel or accommodation, store your luggage, and take time to refresh after your journey. Get familiar with the local area.',
         cost: 'Tips for staff: \$5-10',
         notes: 'Ask reception for local recommendations, get a city map, confirm checkout time',
         latitude: double.tryParse(coordinates.split(',')[0]),
         longitude: double.tryParse(coordinates.split(',')[1]),
       ),
     ];
     
     if (preferences.contains('food')) {
       activities.add(ItineraryItem(
         time: '13:00',
         activity: 'Try authentic local cuisine at a traditional restaurant',
         location: '$destination Historic District',
         description: 'Experience the authentic flavors of $destination at a highly-rated local restaurant. Try signature dishes and regional specialties.',
         cost: 'Lunch: \$25-45 per person',
         notes: 'Make reservations if possible, ask for menu recommendations, try local beverages',
         latitude: double.tryParse(coordinates.split(',')[0]),
         longitude: double.tryParse(coordinates.split(',')[1]),
       ));
     } else {
       activities.add(ItineraryItem(
         time: '13:00',
         activity: 'Lunch at a popular local restaurant',
         location: '$destination City Center',
         description: 'Enjoy a relaxing lunch at a well-reviewed restaurant in the city center. Perfect opportunity to rest and plan your afternoon.',
         cost: 'Lunch: \$15-30 per person',
         notes: 'Check online reviews, consider dietary restrictions, stay hydrated',
         latitude: double.tryParse(coordinates.split(',')[0]),
         longitude: double.tryParse(coordinates.split(',')[1]),
       ));
     }
     
     if (preferences.contains('cultural')) {
       activities.add(ItineraryItem(
         time: '15:00',
         activity: 'Visit iconic cultural landmarks and museums',
         location: '$destination Cultural Quarter',
         description: 'Explore the rich cultural heritage of $destination by visiting its most famous museums, monuments, and historical sites.',
         cost: 'Museum entries: \$10-25 per site',
         notes: 'Check opening hours, consider combo tickets, bring comfortable walking shoes',
         latitude: double.tryParse(coordinates.split(',')[0]),
         longitude: double.tryParse(coordinates.split(',')[1]),
       ));
     } else {
       activities.add(ItineraryItem(
         time: '15:00',
         activity: 'Explore city center and main tourist attractions',
         location: '$destination Main Square',
         description: 'Take a leisurely walk through the city center, visit main squares, and get familiar with the layout and atmosphere of $destination.',
         cost: 'Free walking, optional guided tour: \$15-25',
         notes: 'Wear comfortable shoes, bring camera, stay aware of surroundings',
         latitude: double.tryParse(coordinates.split(',')[0]),
         longitude: double.tryParse(coordinates.split(',')[1]),
       ));
     }
     
     activities.add(ItineraryItem(
       time: '18:00',
       activity: preferences.contains('nightlife') 
         ? 'Dinner and explore vibrant local nightlife scene'
         : 'Relaxing dinner at atmospheric local restaurant',
       location: preferences.contains('nightlife') ? '$destination Entertainment District' : '$destination Restaurant Quarter',
       description: preferences.contains('nightlife') 
         ? 'Enjoy dinner followed by experiencing the local nightlife - bars, clubs, or evening entertainment venues.'
         : 'End your first day with a peaceful dinner at a cozy restaurant with local atmosphere.',
       cost: preferences.contains('nightlife') ? 'Dinner + drinks: \$40-80 per person' : 'Dinner: \$25-50 per person',
       notes: preferences.contains('nightlife') 
         ? 'Research safe areas, keep valuables secure, know your way back to accommodation'
         : 'Make reservations, try local wine/beverages, enjoy the ambiance',
       latitude: double.tryParse(coordinates.split(',')[0]),
       longitude: double.tryParse(coordinates.split(',')[1]),
     ));
     
     return activities;
   }
   
   static List<ItineraryItem> _getDepartureDayActivities(String destination, List<String> preferences) {
     final coordinates = _getCoordinatesForDestination(destination);
     final activities = <ItineraryItem>[];
     
     if (preferences.contains('shopping')) {
       activities.add(ItineraryItem(
         time: '09:00',
         activity: 'Last-minute shopping and souvenir hunting',
         location: '$destination Shopping District',
         description: 'Visit local markets, souvenir shops, and boutiques to pick up memorable gifts and keepsakes from your trip to $destination.',
         cost: 'Souvenirs and gifts: \$30-100',
         notes: 'Check customs regulations, keep receipts for tax refunds, pack fragile items carefully',
         latitude: double.tryParse(coordinates.split(',')[0]),
         longitude: double.tryParse(coordinates.split(',')[1]),
       ));
     } else {
       activities.add(ItineraryItem(
         time: '09:00',
         activity: 'Final sightseeing and photo opportunities',
         location: '$destination Scenic Viewpoint',
         description: 'Take your final photos at the most photogenic spots in $destination. Capture memories of your favorite places before departure.',
         cost: 'Free, optional photo printing: \$10-20',
         notes: 'Charge camera/phone battery, visit sunrise/sunset spots, backup photos to cloud',
         latitude: double.tryParse(coordinates.split(',')[0]),
         longitude: double.tryParse(coordinates.split(',')[1]),
       ));
     }
     
     activities.addAll([
       ItineraryItem(
         time: '12:00',
         activity: 'Farewell lunch at a memorable restaurant',
         location: '$destination Signature Restaurant',
         description: 'Enjoy your final meal in $destination at a restaurant with great views or special significance to your trip.',
         cost: 'Farewell lunch: \$25-50 per person',
         notes: 'Choose a place with good memories, try one last local specialty, take photos',
         latitude: double.tryParse(coordinates.split(',')[0]),
         longitude: double.tryParse(coordinates.split(',')[1]),
       ),
       ItineraryItem(
         time: '15:00',
         activity: 'Check out and departure preparations',
         location: '$destination Accommodation',
         description: 'Complete hotel checkout, organize luggage, and prepare for departure. Double-check you have all belongings and important documents.',
         cost: 'Luggage storage (if needed): \$5-15',
         notes: 'Confirm transportation to airport/station, check flight/train times, keep important documents accessible',
         latitude: double.tryParse(coordinates.split(',')[0]),
         longitude: double.tryParse(coordinates.split(',')[1]),
       ),
       ItineraryItem(
         time: '17:00',
         activity: 'Departure from $destination',
         location: '$destination Transportation Hub',
         description: 'Head to the airport, train station, or departure point. Complete check-in procedures and begin your journey home with wonderful memories.',
         cost: 'Transportation to departure point: \$15-50',
         notes: 'Arrive early for international flights, keep boarding passes safe, stay hydrated during travel',
         latitude: double.tryParse(coordinates.split(',')[0]),
         longitude: double.tryParse(coordinates.split(',')[1]),
       ),
     ]);
     
     return activities;
   }
   
   static List<ItineraryItem> _getRegularDayActivities(String destination, List<String> preferences, int dayNumber) {
     final coordinates = _getCoordinatesForDestination(destination);
     final activities = <ItineraryItem>[];
     
     // Morning activity based on preferences
     if (preferences.contains('adventure')) {
       activities.add(ItineraryItem(
         time: '08:00',
         activity: 'Exciting adventure activity or outdoor exploration',
         location: '$destination Adventure Zone',
         description: 'Start your day with an adrenaline-pumping adventure activity like hiking, rock climbing, water sports, or guided outdoor tours.',
         cost: 'Adventure activity: \$40-120 per person',
         notes: 'Wear appropriate gear, check weather conditions, book in advance, bring water and snacks',
         latitude: double.tryParse(coordinates.split(',')[0]),
         longitude: double.tryParse(coordinates.split(',')[1]),
       ));
     } else if (preferences.contains('cultural')) {
       activities.add(ItineraryItem(
         time: '09:00',
         activity: 'In-depth visit to museums and historical landmarks',
         location: '$destination Museum District',
         description: 'Immerse yourself in the rich history and culture of $destination through guided museum tours and historical site visits.',
         cost: 'Museum entries + guided tour: \$20-45 per person',
         notes: 'Book guided tours in advance, check special exhibitions, bring comfortable walking shoes',
         latitude: double.tryParse(coordinates.split(',')[0]),
         longitude: double.tryParse(coordinates.split(',')[1]),
       ));
     } else {
       activities.add(ItineraryItem(
         time: '09:00',
         activity: 'Discover charming local neighborhoods and hidden gems',
         location: '$destination Local Quarter',
         description: 'Explore authentic local neighborhoods, discover hidden gems, interact with locals, and experience the real character of $destination.',
         cost: 'Free exploration, optional local guide: \$25-40',
         notes: 'Bring camera, learn basic local phrases, respect local customs, try street food',
         latitude: double.tryParse(coordinates.split(',')[0]),
         longitude: double.tryParse(coordinates.split(',')[1]),
       ));
     }
     
     // Lunch
     activities.add(ItineraryItem(
       time: '12:30',
       activity: preferences.contains('food') 
         ? 'Immersive food tour or hands-on cooking class experience'
         : 'Delicious lunch at highly-rated local restaurant',
       location: preferences.contains('food') ? '$destination Culinary District' : '$destination Restaurant Row',
       description: preferences.contains('food')
         ? 'Join a guided food tour to taste local specialties or participate in a cooking class to learn traditional recipes.'
         : 'Enjoy a satisfying lunch featuring local cuisine at a restaurant recommended by locals.',
       cost: preferences.contains('food') ? 'Food tour/cooking class: \$45-85 per person' : 'Lunch: \$20-35 per person',
       notes: preferences.contains('food') 
         ? 'Book in advance, inform about dietary restrictions, bring appetite and curiosity'
         : 'Try daily specials, ask for local recommendations, pace yourself for afternoon activities',
       latitude: double.tryParse(coordinates.split(',')[0]),
       longitude: double.tryParse(coordinates.split(',')[1]),
     ));
     
     // Afternoon activity
     if (preferences.contains('relaxation')) {
       activities.add(ItineraryItem(
         time: '14:30',
         activity: 'Rejuvenating spa treatment or peaceful retreat',
         location: '$destination Wellness District',
         description: 'Unwind and recharge with a relaxing spa treatment, meditation session, or peaceful time in gardens or quiet spaces.',
         cost: 'Spa treatment: \$60-150, park entry: \$5-15',
         notes: 'Book spa appointments in advance, bring comfortable clothes, stay hydrated',
         latitude: double.tryParse(coordinates.split(',')[0]),
         longitude: double.tryParse(coordinates.split(',')[1]),
       ));
     } else if (preferences.contains('shopping')) {
       activities.add(ItineraryItem(
         time: '14:30',
         activity: 'Shopping adventure at local markets and unique boutiques',
         location: '$destination Shopping Quarter',
         description: 'Browse local markets, artisan shops, and unique boutiques to find special items, crafts, and souvenirs.',
         cost: 'Shopping budget: \$50-200 depending on purchases',
         notes: 'Bring reusable bags, negotiate at markets, check return policies, keep receipts',
         latitude: double.tryParse(coordinates.split(',')[0]),
         longitude: double.tryParse(coordinates.split(',')[1]),
       ));
     } else {
       activities.add(ItineraryItem(
         time: '14:30',
         activity: 'Continue discovering more attractions and local experiences',
         location: '$destination Discovery Zone',
         description: 'Continue your exploration of $destination by visiting additional attractions, parks, or engaging in spontaneous local experiences.',
         cost: 'Various attraction fees: \$10-30 per site',
         notes: 'Stay flexible with plans, ask locals for recommendations, keep energy levels up',
         latitude: double.tryParse(coordinates.split(',')[0]),
         longitude: double.tryParse(coordinates.split(',')[1]),
       ));
     }
     
     // Evening
     activities.add(ItineraryItem(
       time: '18:00',
       activity: preferences.contains('nightlife')
         ? 'Dinner and vibrant nightlife experience'
         : 'Romantic dinner and peaceful evening stroll',
       location: preferences.contains('nightlife') ? '$destination Nightlife District' : '$destination Scenic Promenade',
       description: preferences.contains('nightlife')
         ? 'Experience the local nightlife scene with dinner at a trendy restaurant followed by bars, clubs, or live entertainment venues.'
         : 'Enjoy a relaxing dinner followed by a peaceful evening walk through scenic areas or charming neighborhoods.',
       cost: preferences.contains('nightlife') ? 'Dinner + nightlife: \$50-100 per person' : 'Dinner: \$30-60 per person',
       notes: preferences.contains('nightlife')
         ? 'Research safe nightlife areas, keep valuables secure, know your way back to accommodation, drink responsibly'
         : 'Choose restaurants with good ambiance, bring camera for evening photos, dress appropriately for weather',
       latitude: double.tryParse(coordinates.split(',')[0]),
       longitude: double.tryParse(coordinates.split(',')[1]),
     ));
     
     return activities;
   }
   
   static String _getDaySummary(int dayNumber, List<String> preferences) {
     if (preferences.contains('adventure')) {
       return 'Day $dayNumber: Adventure and Exploration';
     } else if (preferences.contains('cultural')) {
       return 'Day $dayNumber: Cultural Immersion';
     } else if (preferences.contains('relaxation')) {
       return 'Day $dayNumber: Relaxation and Leisure';
     } else if (preferences.contains('food')) {
       return 'Day $dayNumber: Culinary Discoveries';
     } else {
       return 'Day $dayNumber: City Exploration';
     }
   }
 }