# Smart Trip Planner 🌍

An AI-powered Flutter application that helps users plan their perfect trips using OpenAI's GPT-4 and real-time web search capabilities.

## Features ✨

- 🤖 **AI-Powered Trip Planning**: Natural language trip planning with OpenAI GPT-4
- 🔍 **Real-time Web Search**: Get up-to-date information about destinations
- 💬 **Interactive Chat Interface**: Streaming responses for real-time conversation
- 💾 **Offline Storage**: Save and manage trips locally with Isar database
- 🎨 **Modern UI**: Clean, responsive design with rich itinerary displays
- 🧪 **Comprehensive Testing**: Unit, widget, and integration tests

## Getting Started 🚀

### Prerequisites

- Flutter SDK (>=3.0.0)
- Dart SDK (>=3.0.0)
- OpenAI API Key

### Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/your-username/smart-trip-planner.git
   cd smart-trip-planner
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Set up environment variables**
   ```bash
   cp .env.example .env
   ```
   Edit `.env` and add your OpenAI API key:
   ```
   OPENAI_API_KEY=your-actual-openai-api-key-here
   ```

4. **Run the app**
   ```bash
   flutter run --dart-define-from-file=.env
   ```

### Testing 🧪

Run all tests:
```bash
flutter test
```

Run integration tests:
```bash
flutter test integration_test/
```

## Architecture 🏗️

This project follows Clean Architecture principles:

- **Presentation Layer**: UI components, screens, and state management
- **Domain Layer**: Business logic, entities, and use cases
- **Data Layer**: Data sources, repositories, and models

## Contributing 🤝

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License 📄

This project is licensed under the MIT License - see the LICENSE file for details.
