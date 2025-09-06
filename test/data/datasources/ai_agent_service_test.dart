import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:dio/dio.dart';
import 'package:smart_tri_planner/data/datasources/ai_agent_service.dart';
import 'package:smart_tri_planner/data/datasources/web_search_service.dart';
import 'package:smart_tri_planner/core/network/dio_client.dart';
import 'package:smart_tri_planner/domain/entities/trip.dart';
import 'package:smart_tri_planner/domain/entities/chat_message.dart';
import 'package:smart_tri_planner/core/errors/failures.dart';

import 'ai_agent_service_test.mocks.dart';

@GenerateMocks([DioClient, WebSearchService])
void main() {
  late AIAgentService aiAgentService;
  late MockDioClient mockDioClient;
  late MockWebSearchService mockWebSearchService;
  const testApiKey = 'test-api-key';

  setUp(() {
    mockDioClient = MockDioClient();
    mockWebSearchService = MockWebSearchService();
    aiAgentService = AIAgentService(mockDioClient, testApiKey, mockWebSearchService);
  });

  group('AIAgentService', () {
    group('generateItinerary', () {
      test('should return Trip when API call is successful', () async {
        // Arrange
        final mockResponse = Response(
          data: {
            'choices': [
              {
                'message': {
                  'function_call': {
                    'arguments': '''
{
  "title": "Tokyo Adventure",
  "startDate": "2024-03-01",
  "endDate": "2024-03-03",
  "days": [
    {
      "date": "2024-03-01",
      "summary": "Arrival and Shibuya exploration",
      "items": [
        {
          "time": "10:00",
          "activity": "Arrive at Tokyo Station",
          "location": "35.6812,139.7671"
        }
      ]
    }
  ]
}
'''
                  }
                }
              }
            ]
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: ''),
        );

        when(mockDioClient.post(any, data: anyNamed('data'), options: anyNamed('options')))
            .thenAnswer((_) async => mockResponse);

        // Act
        final result = await aiAgentService.generateItinerary('Plan a trip to Tokyo');

        // Assert
        expect(result, isA<Trip>());
        expect(result.title, 'Tokyo Adventure');
        expect(result.days.length, 1);
        verify(mockDioClient.post(any, data: anyNamed('data'), options: anyNamed('options'))).called(1);
      });

      test('should throw Failure.server when API returns 401', () async {
        // Arrange
        when(mockDioClient.post(any, data: anyNamed('data'), options: anyNamed('options')))
            .thenThrow(DioException(
              response: Response(
                statusCode: 401,
                requestOptions: RequestOptions(path: ''),
              ),
              requestOptions: RequestOptions(path: ''),
            ));

        // Act & Assert
        expect(
          () => aiAgentService.generateItinerary('Plan a trip'),
          throwsA(isA<Failure>().having(
            (f) => f.message,
            'message',
            'Invalid API key',
          )),
        );
      });

      test('should throw Failure.server when API returns 429', () async {
        // Arrange
        when(mockDioClient.post(any, data: anyNamed('data'), options: anyNamed('options')))
            .thenThrow(DioException(
              response: Response(
                statusCode: 429,
                requestOptions: RequestOptions(path: ''),
              ),
              requestOptions: RequestOptions(path: ''),
            ));

        // Act & Assert
        expect(
          () => aiAgentService.generateItinerary('Plan a trip'),
          throwsA(isA<Failure>().having(
            (f) => f.message,
            'message',
            'Rate limit exceeded',
          )),
        );
      });
    });

    group('searchWeb', () {
      test('should return search results when web search is successful', () async {
        // Arrange
        const query = 'Tokyo weather today';
        const expectedResult = 'Current weather in Tokyo: 22°C, sunny';
        when(mockWebSearchService.searchWeb(query))
            .thenAnswer((_) async => expectedResult);

        // Act
        final result = await aiAgentService.searchWeb(query);

        // Assert
        expect(result, expectedResult);
        verify(mockWebSearchService.searchWeb(query)).called(1);
      });

      test('should throw Failure.network when web search fails', () async {
        // Arrange
        const query = 'Tokyo weather today';
        when(mockWebSearchService.searchWeb(query))
            .thenThrow(Exception('Network error'));

        // Act & Assert
        expect(
          () => aiAgentService.searchWeb(query),
          throwsA(isA<Failure>().having(
            (f) => f.message,
            'message',
            contains('Failed to perform web search'),
          )),
        );
      });
    });

    group('chatWithFunctions', () {
      test('should handle chat messages and return stream', () async {
        // Arrange
        final chatMessages = [
          ChatMessage(
            id: '1',
            content: 'Hello',
            type: ChatMessageType.user,
            timestamp: DateTime.now(),
          ),
        ];

        final mockStreamData = [
          'data: {"choices":[{"delta":{"content":"Hello! "}}]}',
          'data: {"choices":[{"delta":{"content":"How can I help you?"}}]}',
          'data: [DONE]',
        ];

        when(mockDioClient.postStream(any, data: anyNamed('data'), options: anyNamed('options')))
            .thenAnswer((_) => Stream.fromIterable(mockStreamData));

        // Act
        final resultStream = aiAgentService.chatWithFunctions(chatMessages);
        final results = await resultStream.toList();

        // Assert
        expect(results, ['Hello! ', 'How can I help you?']);
        verify(mockDioClient.postStream(any, data: anyNamed('data'), options: anyNamed('options'))).called(1);
      });
    });
  });
}