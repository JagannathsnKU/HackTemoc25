# 📚 Atlas Source Code Structure

## Directory Overview

```
lib/
├── 📱 main.dart                    # App Entry Point
│   ├── AtlasApp (Root Widget)
│   ├── MultiBlocProvider Setup
│   └── AuthWrapper (Routing Logic)
│
├── 📂 blocs/                       # State Management
│   ├── auth_bloc.dart             # Login/Logout Logic
│   │   ├── AuthEvent (LoginWithGoogle, Logout)
│   │   ├── AuthState (unauthenticated, loading, authenticated)
│   │   └── AuthBloc (Handles authentication flow)
│   │
│   └── chat_bloc.dart             # Chat & AI Logic
│       ├── ChatEvent (SendMessage, ReceiveMessage)
│       ├── ChatState (messages list, isThinking flag)
│       └── _getAtlasMockResponse() # Mock AI Brain
│
├── 📂 models/                      # Data Models
│   └── message.dart               # Message Model
│       ├── MessageType enum (text, elevenlabs, share)
│       └── Message class (id, text, isUser, type, audioPath, timestamp)
│
├── 📂 screens/                     # UI Screens
│   ├── login_screen.dart          # Beautiful Login UI
│   │   ├── Gradient Background
│   │   ├── Atlas Logo
│   │   ├── Sign in with Google Button
│   │   └── Loading State
│   │
│   └── chat_screen.dart           # Main Chat Interface
│       ├── App Bar with Logout
│       ├── Messages List View
│       ├── Thinking Indicator
│       ├── Text Input Field
│       ├── Send Button
│       └── Empty State with Suggestions
│
├── 📂 services/                    # Business Logic
│   └── audio_service.dart         # Audio Playback
│       ├── AudioPlayer Instance
│       ├── playAudio(path) Method
│       └── Singleton Pattern
│
└── 📂 widgets/                     # Reusable Components
    └── message_bubble.dart        # Chat Message Widget
        ├── User vs AI Styling
        ├── Avatar Icons
        ├── Message Bubble
        ├── Play Voice Button
        └── Share Button
```

## 🔄 Data Flow

```
User Input
    ↓
ChatScreen
    ↓
ChatBloc.add(SendMessage)
    ↓
ChatBloc._onSendMessage()
    ↓
Add user message to state
    ↓
Future.delayed(2 seconds) [Simulate AI thinking]
    ↓
ChatBloc._getAtlasMockResponse()
    ↓
Pattern matching on user input
    ↓
Return appropriate Message
    ↓
Add AI message to state
    ↓
BlocBuilder updates UI
    ↓
Auto-play audio if available
    ↓
User sees response
```

## 🎯 Key Files Explained

### main.dart
- Sets up the app
- Provides BLoCs to widget tree
- Handles authentication routing

### blocs/chat_bloc.dart
- **MOST IMPORTANT FILE** ⭐
- Contains all mock AI logic
- Easy to add new triggers here
- Manages chat state

### screens/chat_screen.dart
- Main user interface
- Handles user input
- Displays messages
- Integrates audio and share

### widgets/message_bubble.dart
- Makes chat look beautiful
- Handles special message types
- Shows action buttons

## 🔧 How to Extend

### Add New AI Trigger:
1. Open `blocs/chat_bloc.dart`
2. Find `_getAtlasMockResponse()` method
3. Add new if statement:
```dart
if (lowerPrompt.contains('weather')) {
  return Message(
    id: DateTime.now().millisecondsSinceEpoch.toString(),
    text: 'The weather is perfect today!',
    isUser: false,
    audioPath: 'assets/audio/weather_reply.mp3',
  );
}
```

### Add New Screen:
1. Create file in `screens/` directory
2. Add route in `main.dart`
3. Navigate using BLoC events

### Add New Message Type:
1. Add to `MessageType` enum in `models/message.dart`
2. Handle in `widgets/message_bubble.dart`
3. Create trigger in `blocs/chat_bloc.dart`

## 📖 Learning Resources

- **BLoC Pattern**: See how blocs/ folder is structured
- **Widget Composition**: See how screens build from widgets
- **State Management**: Follow the data flow diagram above
- **Async Operations**: Check Future.delayed usage in chat_bloc.dart

---

Happy Coding! 🚀
