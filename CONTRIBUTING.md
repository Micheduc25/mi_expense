# Contributing to Mi Expense

Thank you for your interest in contributing to Mi Expense! This document provides guidelines and steps for contributing to this Flutter-based expense tracking application.

## Prerequisites

Before you begin contributing, ensure you have:

- Flutter 3.0+
- Dart 2.17+
- A working development environment for iOS/Android
- Basic knowledge of GetX state management
- Git installed on your machine

## Setting Up the Development Environment

1. Fork the repository on GitHub
2. Clone your fork locally:
   ```bash
   git clone https://github.com/Micheduc25/mi-expense.git
   cd mi-expense
   ```
3. Add the upstream remote:
   ```bash
   git remote add upstream https://github.com/Micheduc25/mi-expense.git
   ```
4. Install dependencies:
   ```bash
   flutter pub get
   ```

## Development Workflow

1. Create a new branch for your feature/fix:
   ```bash
   git checkout -b feature/your-feature-name
   # or
   git checkout -b fix/your-bug-fix
   ```

2. Make your changes following our coding standards
3. Write/update tests as needed
4. Run tests locally:
   ```bash
   flutter test
   ```

## Coding Standards

### Dart/Flutter Guidelines

- Follow the [Dart style guide](https://dart.dev/guides/language/effective-dart/style)
- Use proper null safety
- Maintain widget independence where possible
- Keep widget files under 300 lines, split if necessary
- Document all public APIs
- Always use XAF (CFA Francs) as the default currency in examples and tests
- Format currency values according to CFA Francs convention (e.g., 1.000 XAF)

### Project Structure

Follow the established project structure:
```
lib/
├── models/           # Data models
├── screens/          # UI screens
├── controllers/      # GetX controllers
├── services/         # Backend services
├── utils/           # Helper functions
├── widgets/         # Reusable UI components
├── routes/          # GetX route management
└── voice/           # Voice command processing
```

### GetX Standards

- Use GetX controllers for state management
- Follow reactive programming patterns
- Implement proper dependency injection
- Use GetX routes for navigation

## Making a Pull Request

1. Update your branch with the latest changes from upstream:
   ```bash
   git fetch upstream
   git rebase upstream/main
   ```

2. Push your changes:
   ```bash
   git push origin your-branch-name
   ```

3. Create a Pull Request on GitHub with:
   - Clear title and description
   - Screenshots/GIFs for UI changes
   - List of major changes
   - Any related issues

## What We're Looking For

- Bug fixes
- Performance improvements
- New features from the roadmap
- Documentation improvements
- Test coverage improvements

## Areas of Focus

Current priorities include:
- Receipt scanning with OCR
- Bank account integration
- Group expense splitting
- Investment tracking
- Multi-currency support (with XAF as base currency)
- AI-powered spending predictions

## Getting Help

- Create an issue for bugs or feature discussions
- Join our community discussions
- Tag maintainers for urgent issues

## Code of Conduct

- Be respectful and inclusive
- Provide constructive feedback
- Help others in the community
- Focus on the problem, not the person

## License

By contributing, you agree that your contributions will be licensed under the MIT License.