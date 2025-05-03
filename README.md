# Mi Expense

A Flutter-based expense tracking application with voice command capabilities, designed primarily for CFA Francs (XAF) transactions.

## About

Mi Expense helps you track your finances through an engaging, interactive interface. Record expenses and income using simple voice commands, visualize your spending patterns, and stay motivated to reach your financial goals. The app uses CFA Francs (XAF) as its default currency.

## Features

### Core Functionality

- **Expense & Income Tracking**
  - Record transactions with details (amount in XAF, date, category, payment method)
  - Attach receipt photos
  - Tag locations with expenses

- **Voice Command System**
  - Add expenses hands-free: "Add expense of 7,500 XAF for lunch today"
  - Record income: "Record 1,000,000 XAF income from salary yesterday"
  - Query data: "How much did I spend on groceries this month?"
  - Natural language processing extracts transaction details

- **Budget Planning**
  - Set monthly budgets by category
  - Track progress with visual indicators
  - Get alerts when approaching limits

- **Reports & Analytics**
  - View income vs expenses dashboards
  - See category breakdowns
  - Track spending trends
  - Export data to CSV/PDF

### Engagement Features

- **Achievement System**
  - Earn badges for consistent tracking
  - Unlock milestones for reaching savings goals
  - Build streaks with daily app usage

- **Financial Insights**
  - Get personalized spending tips
  - Track financial health score
  - Complete weekly saving challenges

- **Smart Reminders**
  - Receive bill payment alerts
  - Get budget notifications
  - Review weekly spending summaries

## Installation

```bash
# Clone the repository
git clone https://github.com/Micheduc25/mi-expense.git

# Navigate to the project directory
cd mi-expense

# Install dependencies
flutter pub get

# Run the app
flutter run
```

## Requirements

- Flutter 3.0+
- Dart 2.17+
- Android 6.0+ or iOS 13.0+
- Device with microphone access for voice commands

## Tech Stack

- **Frontend**: Flutter/Dart
- **State Management**: GetX
- **Authentication**: Firebase Auth
- **Database**: Firebase Firestore
- **Storage**: Firebase Storage
- **Voice Recognition**: Speech Recognition API
- **NLP**: DialogFlow or custom NLP solution
- **Analytics**: Firebase Analytics
- **Notifications**: Firebase Cloud Messaging

## Project Structure

```
mi-expense/
├── lib/
│   ├── main.dart
│   ├── models/           # Data models
│   ├── screens/          # UI screens
│   ├── controllers/      # GetX controllers
│   ├── services/         # Backend services
│   ├── utils/            # Helper functions
│   ├── widgets/          # Reusable UI components
│   ├── routes/           # GetX route management
│   └── voice/            # Voice command processing
├── assets/               # Images, fonts, etc.
├── test/                 # Unit and widget tests
└── pubspec.yaml          # Dependencies
```

## State Management

The app uses GetX for state management and more:

- **Reactive state management** with simple syntax
- **Route management** for navigation without context
- **Dependency injection** for clean service access
- **Theme management** with dark/light mode support
- **Form validation** with GetX controllers
- **Internationalization** for multi-language support

## Roadmap

- Receipt scanning with OCR
- Bank account integration
- Group expense splitting
- Investment tracking
- Multi-currency support
- AI-powered spending predictions

## Contributing

We welcome contributions to Mi Expense! Please check our issues page for open tasks or suggest new features.

## License

MIT License
