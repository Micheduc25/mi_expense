import 'package:get/get.dart';
import 'dart:math' as math;
import '../models/transaction.dart';
import '../controllers/category_controller.dart';

/// Result of parsing a voice command containing transaction information
class VoiceCommandResult {
  final bool isValid;
  final TransactionType? type;
  final double? amount;
  final String? categoryId;
  final String? description;
  final DateTime? date;
  final PaymentMethod? paymentMethod;
  final String? errorMessage;

  VoiceCommandResult({
    this.isValid = false,
    this.type,
    this.amount,
    this.categoryId,
    this.description,
    this.date,
    this.paymentMethod,
    this.errorMessage,
  });

  /// Returns a success result with parsed transaction details
  factory VoiceCommandResult.success({
    required TransactionType type,
    required double amount,
    required String categoryId,
    String? description,
    DateTime? date,
    PaymentMethod? paymentMethod,
  }) {
    // Always default to today's date if date is null
    final DateTime finalDate = date ?? DateTime.now();

    return VoiceCommandResult(
      isValid: true,
      type: type,
      amount: amount,
      categoryId: categoryId,
      description: description,
      date: finalDate,
      paymentMethod: paymentMethod ?? PaymentMethod.cash,
    );
  }

  /// Returns an error result with an error message
  factory VoiceCommandResult.error(String message) {
    return VoiceCommandResult(
      isValid: false,
      errorMessage: message,
    );
  }
}

class CommandParser {
  final CategoryController _categoryController = Get.find<CategoryController>();
  // Regex to find common filler words at the start of the command
  final _fillerWords = RegExp(
      r"^\s*(euh|um|uh|ok|okay|like|you know|bon|alors|donc)\b\s*",
      caseSensitive: false);

  /// Parse a voice command and extract transaction details
  VoiceCommandResult parseCommand(String command) {
    // 1. Preprocessing: Remove filler words and normalize
    final String cleanedCommand =
        command.replaceAll(_fillerWords, '').toLowerCase().trim();
    if (cleanedCommand.isEmpty) {
      return VoiceCommandResult.error(
          "Command is empty after removing filler words.");
    }

    // Determine transaction type
    TransactionType? type = _determineTransactionType(cleanedCommand);
    if (type == null) {
      // Basic check for cancellation keywords
      if (cleanedCommand.contains('cancel') ||
          cleanedCommand.contains('ignore') ||
          cleanedCommand.contains('annuler')) {
        return VoiceCommandResult.error('Command cancelled.');
      }
      return VoiceCommandResult.error(
          'Could not determine if this is an expense or income. Try starting with "Add expense" or "Add income".');
    }

    // Extract amount
    double? amount = _extractAmount(cleanedCommand);
    if (amount == null) {
      return VoiceCommandResult.error(
          'Could not determine the amount. Please specify an amount like "1000", "5k" or "cinq mille".');
    }

    // Extract date (will be defaulted to today in VoiceCommandResult.success if null)
    DateTime? date = _extractDate(cleanedCommand);

    // Extract category
    String? categoryId = _extractCategory(cleanedCommand, type);
    if (categoryId == null) {
      // Try to find a default category ('Other' or 'Uncategorized') if extraction failed
      print(
          "Category not found in command, attempting to find 'Other' or 'Uncategorized'.");
      final defaultCategory = _categoryController.categories.firstWhereOrNull(
        (cat) =>
            cat.name.toLowerCase() == 'other' ||
            cat.name.toLowerCase() == 'uncategorized',
      );

      if (defaultCategory != null) {
        categoryId = defaultCategory.id;
        print(
            "Using default category: ${defaultCategory.name} (ID: $categoryId)");
      } else {
        // Only return error if no category could be extracted AND no suitable default found
        return VoiceCommandResult.error(
            'Could not determine the category, and a default category ("Other" or "Uncategorized") was not found.');
      }
    }

    // Extract description (can be null)
    // Pass extracted amount and date to help description logic avoid removing the wrong parts
    String? description =
        _extractDescription(cleanedCommand, type, amount, date);

    // Extract payment method (can be null, will default to cash in VoiceCommandResult.success)
    PaymentMethod? paymentMethod = _extractPaymentMethod(cleanedCommand);

    return VoiceCommandResult.success(
      type: type,
      amount: amount,
      categoryId: categoryId,
      description: description,
      date: date,
      paymentMethod: paymentMethod,
    );
  }

  /// Finds the best matching keyword for a given input string from a list of keywords
  /// Returns the matching keyword if similarity is above threshold, null otherwise
  String? _findBestMatch(String input, List<String> keywords,
      {double threshold = 0.75}) {
    // Normalize input
    final normalizedInput = input.trim().toLowerCase();
    if (normalizedInput.isEmpty) return null;

    // Check for exact match first (more efficient)
    // Use case-insensitive comparison for keywords list as well
    if (keywords.any((k) => k.toLowerCase() == normalizedInput)) {
      // Return the matched keyword from the list to preserve potential casing if needed upstream
      // Although most internal logic uses lowercase.
      return keywords.firstWhere((k) => k.toLowerCase() == normalizedInput);
    }

    String? bestMatch; // Use nullable type
    double highestSimilarity = 0;

    for (final keyword in keywords) {
      final normalizedKeyword = keyword.toLowerCase();
      // Avoid comparing empty strings if keyword list contains them
      if (normalizedKeyword.isEmpty) continue;

      double similarity =
          _calculateStringSimilarity(normalizedInput, normalizedKeyword);

      // Small bonus for keywords starting similarly (helps with prefixes)
      if (normalizedKeyword.isNotEmpty && // Check non-empty before substring
          (normalizedInput.startsWith(normalizedKeyword.substring(
                  0, math.min(3, normalizedKeyword.length))) ||
              normalizedKeyword.startsWith(normalizedInput.substring(
                  0, math.min(3, normalizedInput.length))))) {
        similarity += 0.05;
      }

      if (similarity > highestSimilarity) {
        highestSimilarity = similarity;
        bestMatch = keyword; // Store original keyword
      }
    }

    // Return the best match only if similarity meets the threshold
    // Ensure the score is strictly >= threshold to avoid near misses on low thresholds
    return (highestSimilarity >= threshold) ? bestMatch : null;
  }

  /// Calculates string similarity using a combination of Jaro-Winkler and containment
  double _calculateStringSimilarity(String s1, String s2) {
    // Quick return for exact match or empty strings
    if (s1 == s2) return 1.0;
    if (s1.isEmpty || s2.isEmpty) return 0.0;

    // Normalize for comparison (already done in caller but safe to repeat)
    s1 = s1.toLowerCase();
    s2 = s2.toLowerCase();

    // Handle containment (one string contains the other) - boost significantly
    // Check lengths to avoid trivial containment
    if (s1.length >= 3 && s2.length > s1.length && s2.contains(s1)) return 0.95;
    if (s2.length >= 3 && s1.length > s2.length && s1.contains(s2)) return 0.95;

    // Simple Jaro-Winkler-like algorithm
    int maxDist = (math.max(s1.length, s2.length) / 2).floor();
    List<bool> s1Matches = List.filled(s1.length, false);
    List<bool> s2Matches = List.filled(s2.length, false);

    int matchingChars = 0;
    for (int i = 0; i < s1.length; i++) {
      int start = math.max(0, i - maxDist);
      int end = math.min(i + maxDist + 1, s2.length);

      for (int j = start; j < end; j++) {
        if (!s2Matches[j] && s1[i] == s2[j]) {
          s1Matches[i] = true;
          s2Matches[j] = true;
          matchingChars++;
          break;
        }
      }
    }

    if (matchingChars == 0) return 0.0;

    int transpositions = 0;
    int k = 0;
    for (int i = 0; i < s1.length; i++) {
      if (s1Matches[i]) {
        while (!s2Matches[k]) k++;
        if (s1[i] != s2[k]) transpositions++;
        k++;
      }
    }

    double jaro = (matchingChars / s1.length +
            matchingChars / s2.length +
            (matchingChars - transpositions / 2) / matchingChars) /
        3.0;

    // Simplified Winkler prefix bonus
    int prefixLength = 0;
    for (int i = 0; i < math.min(4, math.min(s1.length, s2.length)); i++) {
      if (s1[i] == s2[i])
        prefixLength++;
      else
        break;
    }
    double winklerBonus = prefixLength * 0.1 * (1 - jaro);
    double similarity = jaro + winklerBonus;

    // Boost score for longer common substrings
    int substrLength = _longestCommonSubstring(s1, s2).length;
    if (substrLength > 2) {
      // Slightly lower threshold for substring start
      // Give more bonus for longer substrings relative to string length
      double substrBonus = (substrLength / math.max(s1.length, s2.length)) *
          0.15; // Increased bonus slightly
      similarity = math.min(1.0, similarity + substrBonus);
    }

    return math.min(1.0, similarity); // Ensure score doesn't exceed 1.0
  }

  /// Finds the longest common substring between two strings
  String _longestCommonSubstring(String s1, String s2) {
    if (s1.isEmpty || s2.isEmpty) return '';

    // Use lowercase for substring finding as well
    s1 = s1.toLowerCase();
    s2 = s2.toLowerCase();

    List<List<int>> table =
        List.generate(s1.length + 1, (_) => List.filled(s2.length + 1, 0));

    int longest = 0;
    int endPos = 0;

    for (int i = 1; i <= s1.length; i++) {
      for (int j = 1; j <= s2.length; j++) {
        if (s1[i - 1] == s2[j - 1]) {
          table[i][j] = table[i - 1][j - 1] + 1;
          if (table[i][j] > longest) {
            longest = table[i][j];
            endPos = i;
          }
        }
      }
    }

    // Return the substring from the original s1 (before lowercasing) if needed?
    // Currently returns lowercase. Sticking with lowercase for consistency.
    return longest > 0 ? s1.substring(endPos - longest, endPos) : '';
  }

  TransactionType? _determineTransactionType(String command) {
    // Enhanced expense indicators
    final expenseKeywords = [
      'expense', 'spent', 'bought', 'paid', 'purchase', 'pay', 'spending',
      'withdrew', 'took out', 'cost', 'charge', 'debit', 'bill', 'payment',
      'sortie', 'depense', 'acheter', 'achat', 'buy', 'paid for', 'payed',
      // Typos/Variations
      'expence', 'expanse', 'expens', 'spnt', 'bougt', 'paied', 'coast',
      'purchace',
      'expenses', 'depenses', 'achats' // Plurals
    ];

    // Enhanced income indicators
    final incomeKeywords = [
      'income', 'earned', 'received', 'salary', 'revenue', 'gain', 'deposit',
      'paid me', 'getting', 'entree', 'revenu', 'salaire', 'recevoir', 'recu',
      'business', 'sale', 'vente', 'profit', 'stipend', 'allowance', 'grant',
      'scholarship', 'bourse', 'got', // Added 'got'
      // Typos/Variations
      'incom', 'recieved', 'erned', 'salari', 'revinue', 'recevd', 'inkoam',
      'salery',
      'ernings', 'recive', 'earnt', 'salery', 'revenu', 'revenus',
      'profits', // Plurals
      'receive' // Common misspelling
    ];

    // NOTE: Cancellation check moved to parseCommand

    // Use fuzzy matching with a reasonably high threshold for type keywords
    final words = command.split(' ');
    double expenseScore = 0;
    double incomeScore = 0;

    for (var word in words) {
      String cleanWord = word.replaceAll(RegExp(r'[^\w]'), '').toLowerCase();
      if (cleanWord.isEmpty || cleanWord.length < 3)
        continue; // Skip short/empty words

      if (_findBestMatch(cleanWord, expenseKeywords, threshold: 0.85) != null) {
        // Increase score more for better matches, maybe based on similarity?
        // For now, just increment.
        expenseScore += 1.0;
      }
      if (_findBestMatch(cleanWord, incomeKeywords, threshold: 0.85) != null) {
        incomeScore += 1.0;
      }
    }

    // Compare scores
    if (expenseScore > incomeScore) {
      return TransactionType.expense;
    } else if (incomeScore > expenseScore) {
      return TransactionType.income;
    } else if (expenseScore > 0) {
      // Ambiguous if scores are equal but positive, maybe default to expense?
      // Or require a clearer signal?
      // Let's try defaulting to expense if ambiguous but present.
      return TransactionType.expense;
    }

    // Fallback to simple contains check (lower confidence) if fuzzy matching inconclusive
    bool hasExpenseKeyword =
        expenseKeywords.any((k) => command.contains(k.toLowerCase()));
    bool hasIncomeKeyword =
        incomeKeywords.any((k) => command.contains(k.toLowerCase()));

    if (hasExpenseKeyword && !hasIncomeKeyword) return TransactionType.expense;
    if (hasIncomeKeyword && !hasExpenseKeyword) return TransactionType.income;

    // If contains check is also ambiguous or finds nothing, return null
    return null;
  }

  double? _extractAmount(String command) {
    // Handle "k" suffix for thousands (e.g., 5k = 5000)
    RegExp kSuffixRegex = RegExp(r'(\d+[\.,]?\d*)\s*k\b', caseSensitive: false);
    Match? kMatch = kSuffixRegex.firstMatch(command);
    if (kMatch != null) {
      String numPart = kMatch
          .group(1)!
          .replaceAll(RegExp(r'[,\.]'), ''); // Remove separators
      double? baseAmount = double.tryParse(numPart);
      if (baseAmount != null) {
        return baseAmount * 1000;
      }
    }

    // Match patterns with CFA currency specifics: 1000, 1.000, 1,000, 1000 XAF/FCFA/francs
    // Updated regex to better handle separators and avoid grabbing parts of words
    RegExp amountRegexWithCurrency = RegExp(
        r'\b(\d{1,3}(?:[,\.\s]\d{3})*|\d+)\s*(?:xaf|cfa|fcfa|f\.?cfa|francs?(\s+cfa)?)\b',
        caseSensitive: false);

    // French numeric expressions
    Map<String, int> frenchNumbers = {
      // Add more as needed
      'mille': 1000, 'deux mille': 2000, 'trois mille': 3000,
      'quatre mille': 4000,
      'cinq mille': 5000, 'dix mille': 10000, 'vingt mille': 20000,
      'cinquante mille': 50000,
      'cent mille': 100000, 'un million': 1000000, 'deux millions': 2000000,
      'cinq millions': 5000000, 'dix millions': 10000000,
      // Handle potential variations like "mil"
      'mil': 1000, 'deux mil': 2000, 'cinq mil': 5000, 'dix mil': 10000,
    };

    // Prioritize French number words if found
    // Check longer phrases first (reversed order)
    // Ensure it's a whole word match
    for (var entry in frenchNumbers.entries.toList()
      ..sort((a, b) => b.key.length.compareTo(a.key.length))) {
      // Sort by length desc
      if (command.contains(entry.key)) {
        if (RegExp(r'\b' + entry.key + r'\b').hasMatch(command)) {
          return entry.value.toDouble();
        }
      }
    }

    // Match numbers with currency next
    Match? match = amountRegexWithCurrency.firstMatch(command);
    if (match != null) {
      String amountStr = match.group(1)!.replaceAll(RegExp(r'[,\s]'), '');
      amountStr =
          amountStr.replaceAll('.', ''); // Handle dot as thousand separator
      return double.tryParse(amountStr);
    }

    // If no currency match, find any standalone number sequence
    // Refined regex to avoid capturing years, times, or parts of codes
    RegExp amountRegex = RegExp(
        r'(?<!\d[\/\-\.]|\d[ap]m|\w)(\d{1,3}(?:[,\.\s]\d{3})*|\d+)(?![\/\-\.]\d|\s*(?:am|pm|h|k)\b|\w)',
        caseSensitive: false);

    // Find all potential number matches and try to pick the best one
    double? bestAmountFound;
    Iterable<Match> matches = amountRegex.allMatches(command);
    for (Match m in matches) {
      String amountStr = m
          .group(1)!
          .replaceAll(RegExp(r'[,\s\.]'), ''); // Remove all separators
      double? parsedAmount = double.tryParse(amountStr);

      if (parsedAmount != null && parsedAmount > 0) {
        // Basic sanity check: avoid year-like numbers if context strongly suggests date
        // Check if the number is adjacent to month names or date separators
        int matchStart = m.start;
        int matchEnd = m.end;
        String prefix =
            command.substring(math.max(0, matchStart - 8), matchStart).trim();
        String suffix = command
            .substring(matchEnd, math.min(command.length, matchEnd + 8))
            .trim();

        // Check if the number looks like a year and is near date indicators
        bool likelyYear = (parsedAmount >= 1900 &&
                parsedAmount <= (DateTime.now().year + 5)) &&
            (
                // Ends with separator? e.g., ".../ 2023"
                prefix.contains(RegExp(r'[/\-.]\s*$')) ||
                    // Starts with separator? e.g., "2023 /..."
                    suffix.startsWith(RegExp(r'^\s*[/\-.]')) ||
                    // Preceded by a month name/abbreviation?
                    _isPrecededByMonth(prefix));

        if (likelyYear) {
          continue; // Skip likely year
        }

        // Prefer larger amounts? Or amounts mentioned near type keywords?
        // For now, take the first plausible one that isn't a likely year.
        // Consider refining this: if multiple amounts, which one is most plausible?
        bestAmountFound = parsedAmount;
        break; // Take the first plausible amount found
      }
    }

    if (bestAmountFound != null) {
      return bestAmountFound;
    }

    // Final fallback: Check if the only number present is potentially the amount
    // (Less reliable)
    var allNumbers =
        RegExp(r'\d+').allMatches(command).map((m) => m.group(0)).toList();
    if (allNumbers.length == 1) {
      double? singleNum = double.tryParse(allNumbers.first!);
      // Avoid using year as amount if found alone
      if (singleNum != null &&
          !(singleNum >= 1900 && singleNum <= (DateTime.now().year + 5))) {
        return singleNum;
      }
    }

    return null; // No amount found
  }

  DateTime? _extractDate(String command, {bool simpleCheck = false}) {
    DateTime now = DateTime.now();

    // Relative dates (aujourd'hui, hier, demain, last week, ce matin, etc.)
    if (command.contains('today') || command.contains("aujourd'hui")) {
      return DateTime(now.year, now.month, now.day); // Return just date part
    }
    if (command.contains('yesterday') || command.contains('hier')) {
      return DateTime(now.year, now.month, now.day)
          .subtract(const Duration(days: 1));
    }
    if (command.contains('tomorrow') || command.contains('demain')) {
      return DateTime(now.year, now.month, now.day)
          .add(const Duration(days: 1));
    }
    if (command.contains('avant-hier')) {
      return DateTime(now.year, now.month, now.day)
          .subtract(const Duration(days: 2)); // Day before yesterday
    }
    if (command.contains('apres-demain')) {
      return DateTime(now.year, now.month, now.day)
          .add(const Duration(days: 2)); // Day after tomorrow
    }
    // Week references (return start of the week, typically Monday)
    if (command.contains('last week') ||
        command.contains('la semaine derniere') ||
        command.contains('la semaine passee')) {
      DateTime startOfThisWeek = now.subtract(Duration(days: now.weekday - 1));
      return DateTime(
              startOfThisWeek.year, startOfThisWeek.month, startOfThisWeek.day)
          .subtract(const Duration(days: 7));
    }
    if (command.contains('this week') || command.contains('cette semaine')) {
      DateTime startOfThisWeek = now.subtract(Duration(days: now.weekday - 1));
      return DateTime(
          startOfThisWeek.year, startOfThisWeek.month, startOfThisWeek.day);
    }
    if (command.contains('next week') ||
        command.contains('la semaine prochaine')) {
      DateTime startOfThisWeek = now.subtract(Duration(days: now.weekday - 1));
      return DateTime(
              startOfThisWeek.year, startOfThisWeek.month, startOfThisWeek.day)
          .add(const Duration(days: 7));
    }

    // Time of day references (set to specific times, but return Date part only for consistency?)
    // Or maybe return DateTime with time? Let's stick to Date for now.
    if (command.contains('this morning') || command.contains('ce matin')) {
      return DateTime(now.year, now.month, now.day);
    }
    if (command.contains('this afternoon') ||
        command.contains('cet apres-midi')) {
      return DateTime(now.year, now.month, now.day);
    }
    if (command.contains('this evening') || command.contains('ce soir')) {
      return DateTime(now.year, now.month, now.day);
    }

    // Day of week references (handle "last", "next", current week)
    Map<String, int> daysOfWeek = {
      'monday': 1,
      'lundi': 1,
      'tuesday': 2,
      'mardi': 2,
      'wednesday': 3,
      'mercredi': 3,
      'thursday': 4,
      'jeudi': 4,
      'friday': 5,
      'vendredi': 5,
      'saturday': 6,
      'samedi': 6,
      'sunday': 7,
      'dimanche': 7
    };

    for (var entry in daysOfWeek.entries) {
      String dayKey = entry.key;
      int targetWeekday = entry.value;
      // Use word boundaries for day matching
      RegExp dayRegex = RegExp(r'\b' + dayKey + r'\b', caseSensitive: false);

      if (dayRegex.hasMatch(command)) {
        int currentWeekday = now.weekday;
        int daysToAdd = targetWeekday - currentWeekday;

        // Check for "last" or "next" modifiers more robustly
        bool isLast = RegExp(r'\b(last|dernier|passe)\s+' + dayKey + r'\b',
                    caseSensitive: false)
                .hasMatch(command) ||
            RegExp(r'\b' + dayKey + r'\s+(dernier|passe)\b',
                    caseSensitive: false)
                .hasMatch(command);
        bool isNext =
            RegExp(r'\bnext\s+' + dayKey + r'\b', caseSensitive: false)
                    .hasMatch(command) ||
                RegExp(r'\b' + dayKey + r'\s+prochain\b', caseSensitive: false)
                    .hasMatch(command);

        if (isLast) {
          // If today is Wednesday (3) and command is "last Monday" (1), target is -2. Add -7 -> -9 days.
          // If today is Monday (1) and command is "last Wednesday" (3), target is +2. Add -7 -> -5 days.
          if (daysToAdd >= 0) daysToAdd -= 7;
        } else if (isNext) {
          // If today is Wednesday (3) and command is "next Monday" (1), target is -2. Add +7 -> +5 days.
          // If today is Monday (1) and command is "next Wednesday" (3), target is +2. Add +7 -> +9 days?
          // No, if target day is later this week, "next" should mean week after next.
          // If target day already passed this week, "next" means the upcoming one.
          if (daysToAdd <= 0) daysToAdd += 7; // Ensure it's in the future
          daysToAdd += 7; // Add a full week for "next"
        } else {
          // No modifier: Assume the *next* occurrence of this day.
          // If today is Wednesday (3) and command is "Monday" (1), target is -2. Add +7 -> +5 days (next Monday).
          // If today is Monday (1) and command is "Wednesday" (3), target is +2. Add 0 -> +2 days (this Wednesday).
          if (daysToAdd < 0) daysToAdd += 7;
        }

        DateTime resultDate = DateTime(now.year, now.month, now.day)
            .add(Duration(days: daysToAdd));
        return resultDate;
      }
    }

    // If simpleCheck is true, don't parse complex formats
    if (simpleCheck) return null;

    // Specific date formats (DD/MM/YYYY, DD-MM-YY, DD.MM.YY etc.)
    // Ensure word boundaries to avoid matching numbers within words
    RegExp dateRegex =
        RegExp(r'\b(\d{1,2})[\/\-\.](\d{1,2})(?:[\/\-\.](\d{2}|\d{4}))?\b');
    Match? match = dateRegex.firstMatch(command);
    if (match != null) {
      try {
        int day = int.parse(match.group(1)!);
        int month = int.parse(match.group(2)!);
        int year;
        if (match.group(3) != null) {
          String yearStr = match.group(3)!;
          year = int.parse(yearStr);
          if (yearStr.length == 2) year += 2000; // Adjust 2-digit year
        } else {
          year = now.year; // Assume current year if not specified
          // If MM/DD looks like a past date this year, maybe assume last year?
          // Heuristic: If month is later than current month, assume last year.
          if (month > now.month) {
            year -= 1;
          }
        }

        // Basic validation before creating DateTime
        if (month > 0 && month <= 12 && day > 0 && day <= 31) {
          // Attempt to create the date, catch errors for invalid day/month combos
          return DateTime(year, month, day);
        }
      } catch (e) {/* Ignore parsing/DateTime errors */}
    }

    // Month names (English and French) - try finding day nearby
    Map<String, int> months = {
      'january': 1,
      'janvier': 1,
      'february': 2,
      'fevrier': 2,
      'march': 3,
      'mars': 3,
      'april': 4,
      'avril': 4,
      'may': 5,
      'mai': 5,
      'june': 6,
      'juin': 6,
      'july': 7,
      'juillet': 7,
      'august': 8,
      'aout': 8,
      'september': 9,
      'septembre': 9,
      'october': 10,
      'octobre': 10,
      'november': 11,
      'novembre': 11,
      'december': 12,
      'decembre': 12
    };

    for (var entry in months.entries) {
      String monthKey = entry.key;
      int monthValue = entry.value;
      // Use word boundaries
      RegExp monthRegex =
          RegExp(r'\b' + monthKey + r'\b', caseSensitive: false);

      Match? monthMatchInstance = monthRegex.firstMatch(command);
      if (monthMatchInstance != null) {
        // Try finding day number immediately before or after the month name
        // Look in a small window around the month match
        int monthStartIndex = monthMatchInstance.start;
        int monthEndIndex = monthMatchInstance.end;
        String prefix = command
            .substring(math.max(0, monthStartIndex - 5), monthStartIndex)
            .trim();
        String suffix = command
            .substring(
                monthEndIndex, math.min(command.length, monthEndIndex + 5))
            .trim();

        RegExp dayNumRegex = RegExp(r'^(\d{1,2})\\b|\\b(\d{1,2})$');
        Match? dayMatchPrefix = dayNumRegex.firstMatch(prefix);
        Match? dayMatchSuffix = dayNumRegex.firstMatch(suffix);

        int day = 1; // Default to 1st if no day specified
        String? dayStr;
        if (dayMatchPrefix != null) {
          dayStr = dayMatchPrefix.group(1) ?? dayMatchPrefix.group(2);
        } else if (dayMatchSuffix != null) {
          dayStr = dayMatchSuffix.group(1) ?? dayMatchSuffix.group(2);
        }

        if (dayStr != null) {
          day = int.tryParse(dayStr) ?? 1;
        }

        // Assume current year unless specified otherwise (e.g., "December 5 2022")
        int year = now.year;
        // Look for a year number near the month/day
        RegExp yearRegex = RegExp(r'\b(19d{2}|20d{2})\b');
        Match? yearMatch = yearRegex.firstMatch(command.substring(
            math.max(0, monthStartIndex - 10),
            math.min(command.length, monthEndIndex + 10)));
        if (yearMatch != null) {
          year = int.parse(yearMatch.group(0)!);
        }
        // Heuristic: If month/day is in the future this year, assume this year.
        // If month/day is in the past this year, assume this year (unless year specified).
        // If no year specified and month is past, stick with current year for simplicity unless it creates date far in future?

        // Basic validation
        if (day > 0 && day <= 31) {
          try {
            // Create the date, let DateTime handle validation (e.g., Feb 30)
            return DateTime(year, monthValue, day);
          } catch (e) {/* Invalid date combination */}
        }
      }
    }

    // African time expressions (Example)
    if (command.contains('market day') || command.contains('jour de marche')) {
      // Placeholder: return a fixed day offset or lookup logic
      // Return date part only
      DateTime resultDate = now.add(const Duration(days: 4));
      return DateTime(resultDate.year, resultDate.month, resultDate.day);
    }

    // Default: No specific date found
    return null; // Let the caller handle defaulting to DateTime.now()
  }

  String? _extractCategory(String command, TransactionType type) {
    final categories = _categoryController.categories;
    if (categories.isEmpty) {
      print("Warning: No categories found in CategoryController.");
      return null; // No categories defined
    }

    // Consider filtering categories by type if your app associates categories with types
    final relevantCategories = categories;

    // --- Extraction Strategies --- Priority Order:
    // 1. Explicit mention: "for category [name]"
    // 2. Exact category name match within command
    // 3. High-confidence fuzzy match on category name
    // 4. Inference from associated keywords (food -> groceries etc.)

    List<String> commandWords =
        command.split(' ').where((w) => w.length >= 3).toList();

    // Strategy 1: Explicit Category Mention
    RegExp explicitCategoryRegex = RegExp(
        r'(?:for|category|catégorie)\s+([\w\s]+?)(?:\s+on|\s+at|\s+with|\s+using|\s+pour|$)',
        caseSensitive: false);
    Match? explicitMatch = explicitCategoryRegex.firstMatch(command);
    if (explicitMatch != null) {
      String potentialCategoryName = explicitMatch.group(1)!.trim();
      if (potentialCategoryName.isNotEmpty) {
        // Try exact match first (case-insensitive)
        for (final category in relevantCategories) {
          if (category.name.toLowerCase() ==
              potentialCategoryName.toLowerCase()) {
            print(
                "Category found by explicit mention (Exact): ${category.name}");
            return category.id;
          }
        }
        // Try high-confidence fuzzy match if exact fails
        for (final category in relevantCategories) {
          if (_calculateStringSimilarity(potentialCategoryName, category.name) >
              0.88) {
            // High threshold for explicit
            print(
                "Category found by explicit mention (Fuzzy): ${category.name} (matched: $potentialCategoryName)");
            return category.id;
          }
        }
      }
    }

    // Strategy 2 & 3: Exact and Fuzzy Matching of Category Names
    String? bestFuzzyMatchId;
    double highestSimilarity = 0.0;
    String? exactMatchId;

    for (final category in relevantCategories) {
      String categoryNameLower = category.name.toLowerCase();

      // Strategy 2: Exact substring match (whole category name)
      // Use word boundaries to avoid partial matches (e.g., "car" in "card")
      if (RegExp(r'\b' + RegExp.escape(categoryNameLower) + r'\b')
          .hasMatch(command)) {
        print("Category found by exact name match: ${category.name}");
        exactMatchId = category.id;
        break; // Exact match is highest priority, stop searching here
      }

      // Strategy 3: Fuzzy match preparation (compare against words and phrase)
      // Calculate similarity against each relevant word
      for (final word in commandWords) {
        double wordSimilarity =
            _calculateStringSimilarity(word, categoryNameLower);
        if (wordSimilarity > highestSimilarity) {
          highestSimilarity = wordSimilarity;
          bestFuzzyMatchId = category.id;
        }
      }
      // Also check similarity against the whole category name phrase
      double phraseSimilarity =
          _calculateStringSimilarity(command, categoryNameLower);
      if (phraseSimilarity > highestSimilarity) {
        highestSimilarity = phraseSimilarity;
        bestFuzzyMatchId = category.id;
      }
    }

    // If an exact match was found, return its
    if (exactMatchId != null) {
      return exactMatchId;
    }

    // Evaluate fuzzy match result
    if (highestSimilarity > 0.82) {
      // Adjusted threshold for general fuzzy category match
      final matchedCategory =
          relevantCategories.firstWhere((c) => c.id == bestFuzzyMatchId);
      print(
          "Category found by fuzzy name match: ${matchedCategory.name} (Score: $highestSimilarity)");
      return bestFuzzyMatchId;
    }

    // Strategy 4: Infer from Keywords
    Map<String, List<String>> keywordsMap = type == TransactionType.expense
        ? _getExpenseKeywords()
        : _getIncomeKeywords();
    String? inferredCategoryId;
    double highestKeywordInferenceScore = 0.0;

    for (final entry in keywordsMap.entries) {
      String categoryConcept = entry.key; // e.g., 'food', 'transportation'
      List<String> associatedTerms = entry.value;

      // Check if any associated term fuzzy-matches a word in the command
      for (final word in commandWords) {
        String? termMatch = _findBestMatch(word, associatedTerms,
            threshold: 0.80); // Threshold for keyword terms
        if (termMatch != null) {
          // Found a keyword match (e.g., command has 'riz', matches term 'rice' under 'food')
          // Now, find the user's category *most similar* to the categoryConcept ('food')
          String? bestMatchingUserCategoryId;
          double bestCategorySimilarity =
              0.65; // Minimum similarity between user category name and concept

          for (final category in relevantCategories) {
            double sim = _calculateStringSimilarity(
                category.name.toLowerCase(), categoryConcept);
            if (sim > bestCategorySimilarity) {
              bestCategorySimilarity = sim;
              bestMatchingUserCategoryId = category.id;
            }
          }
          // If we found a user category that matches the concept well enough,
          // consider this inference stronger based on the concept similarity.
          if (bestMatchingUserCategoryId != null &&
              bestCategorySimilarity > highestKeywordInferenceScore) {
            highestKeywordInferenceScore = bestCategorySimilarity;
            inferredCategoryId = bestMatchingUserCategoryId;
            print(
                "Category inferred via keyword: Concept '$categoryConcept' (term: $termMatch) -> User Category: ${relevantCategories.firstWhere((c) => c.id == inferredCategoryId).name} (Sim: $bestCategorySimilarity)");
          }
          // Optimization: If we found a very strong inference, maybe stop early?
          if (highestKeywordInferenceScore > 0.9)
            break; // Break inner loop if highly confident
        }
      }
      if (highestKeywordInferenceScore > 0.9) break; // Break outer loop too
    }

    // Return inferred category only if the inference score is decent
    if (inferredCategoryId != null && highestKeywordInferenceScore > 0.70) {
      // Threshold for keyword inference
      return inferredCategoryId;
    }

    // Fallback: No category found or confidence too low
    print("Could not confidently determine category.");
    return null;
  }

  // Helper maps for keyword inference (keep these updated)
  Map<String, List<String>> _getExpenseKeywords() => {
        'food': [
          'food',
          'lunch',
          'dinner',
          'breakfast',
          'meal',
          'restaurant',
          'eat',
          'grocery',
          'groceries',
          'nourriture',
          'dejeuner',
          'diner',
          'petit-dejeuner',
          'repas',
          'manger',
          'sauce',
          'rice',
          'riz',
          'beans',
          'haricots',
          'meat',
          'viande',
          'fish',
          'poisson',
          'fruits',
          'legumes',
          'vegetables',
          'bread',
          'pain',
          'snack',
          'snacks',
          'boulangerie',
          'bakery',
          'fast food',
          'street food',
          'nourriture de rue',
          'marche',
          'market',
          'fod',
          'fuud',
          'bred',
          'groccery',
          'resturant',
          'restorant',
          'brekfast',
          'lunsh',
          'restrant',
          'resta',
          'grocer',
          'groserys',
          'fruites',
          'drink',
          'boisson',
          'water',
          'eau',
          'cafe',
          'coffee'
        ],
        'transportation': [
          'transport',
          'uber',
          'taxi',
          'car',
          'bus',
          'train',
          'fuel',
          'gas',
          'petrol',
          'voiture',
          'essence',
          'carburant',
          'petrole',
          'moto',
          'motorcycle',
          'okada',
          'boda boda',
          'zemidjan',
          'zem',
          'bendskin',
          'bike',
          'velo',
          'bicycle',
          'fare',
          'ticket',
          'billet',
          'pass',
          'passe',
          'toll',
          'peage',
          'taxi-moto',
          'mototaxi',
          'taxi-brousse',
          'bush taxi',
          'tro-tro',
          'danfo',
          'matatu',
          'transpot',
          'transprt',
          'transportatn',
          'trasport',
          'trnsprt',
          'ubar',
          'ubr',
          'texsi',
          'teksi',
          'taxe',
          'mottorcycle',
          'motocycle',
          'motorbike',
          'bycicle',
          'bik',
          'buss',
          'trein',
          'trane',
          'feul',
          'gazoline',
          'gaz',
          'parking',
          'stationnement',
          'flight',
          'vol',
          'boat',
          'bateau'
        ],
        'bills': [
          'bill',
          'bills',
          'utility',
          'utilities',
          'electricity',
          'water',
          'internet',
          'phone',
          'rent',
          'facture',
          'factures',
          'utilitaire',
          'electricite',
          'eau',
          'telephone',
          'loyer',
          'subscription',
          'abonnement',
          'fee',
          'fees',
          'frais',
          'electri',
          'phon',
          'subscr',
          'gaz bill',
          'tv',
          'cable',
          'canal+',
          'dstv'
        ],
        'shopping': [
          'shopping',
          'clothes',
          'shoes',
          'electronics',
          'gifts',
          'online shopping',
          'magasinage',
          'vetements',
          'chaussures',
          'electroniques',
          'cadeaux',
          'achat en ligne',
          'store',
          'magasin',
          'boutique',
          'cloths',
          'elektro',
          'appliance',
          'appareil',
          'furniture',
          'meubles',
          'books',
          'livres'
        ],
        'entertainment': [
          'entertainment',
          'movies',
          'cinema',
          'concert',
          'bar',
          'drinks',
          'game',
          'hobby',
          'divertissement',
          'film',
          'boissons',
          'jeu',
          'loisir',
          'party',
          'fete',
          'outing',
          'sortie',
          'fun',
          'amusant',
          'music',
          'musique',
          'sport',
          'event',
          'evenement'
        ],
        'health': [
          'health',
          'doctor',
          'pharmacy',
          'medicine',
          'hospital',
          'sante',
          'medecin',
          'pharmacie',
          'medicament',
          'hopital',
          'clinic',
          'clinique',
          'drug',
          'drugs',
          'helth',
          'docteur',
          'dentist',
          'dentiste',
          'therapy',
          'therapie'
        ],
        'education': [
          'education',
          'school',
          'books',
          'course',
          'tuition',
          'ecole',
          'livres',
          'cours',
          'frais de scolarite',
          'university',
          'universite',
          'learn',
          'apprendre',
          'student loan',
          'pret etudiant'
        ],
        'personal care': [
          'personal care',
          'haircut',
          'beauty',
          'salon',
          'soins personnels',
          'coiffure',
          'beaute',
          'cosmetics',
          'cosmetiques',
          'gym',
          'fitness'
        ],
        'gifts_donations': [
          'gift',
          'present',
          'cadeau',
          'donation',
          'don',
          'charity',
          'charite',
          'tithe',
          'dime'
        ], // Renamed to avoid clash with income
        'travel': [
          'travel',
          'holiday',
          'vacation',
          'hotel',
          'flight',
          'voyage',
          'vacances',
          'vol',
          'trip',
          'journey',
          'accommodation',
          'hebergement'
        ],
        'home': [
          'home',
          'maison',
          'repair',
          'reparation',
          'maintenance',
          'garden',
          'jardin',
          'improvement',
          'amelioration',
          'decor'
        ],
        'family': [
          'family',
          'kids',
          'children',
          'famille',
          'enfants',
          'childcare',
          'garde d\'enfants',
          'support'
        ],
        'fees_charges': [
          'fee',
          'charge',
          'bank fee',
          'frais',
          'frais bancaires',
          'tax',
          'impot',
          'interest paid',
          'interet paye'
        ], // More specific than just 'bills'
        'other': ['other', 'miscellaneous', 'autre', 'divers']
        // Add more specific expense categories and keywords
      };

  Map<String, List<String>> _getIncomeKeywords() => {
        'salary': [
          'salary',
          'wage',
          'pay',
          'paycheck',
          'job',
          'work',
          'earning',
          'salaire',
          'paie',
          'paiement',
          'cheque de paie',
          'emploi',
          'travail',
          'monthly pay',
          'paie mensuelle',
          'weekly pay',
          'paie hebdomadaire',
          'stipend',
          'allocation',
          'bonus',
          'prime',
          'overtime',
          'heures supplementaires',
          'allowance',
          'indemnite',
          'salery',
          'salry',
          'wages',
          'waiges',
          'payslip',
          'paychek',
          'sallary',
          'sallery',
          'wadge',
          'montly salary',
          'weakly pay',
          'earnngs',
          'commission'
        ],
        'business': [
          'business',
          'sales',
          'revenue',
          'profit',
          'customer',
          'client',
          'service',
          'product',
          'vente',
          'revenu',
          'benefice',
          'produit',
          'freelance',
          'consulting',
          'gig',
          'contract',
          'contrat',
          'invoice',
          'facture payee'
        ],
        'gifts_received': [
          'gift',
          'present',
          'cadeau',
          'donation received',
          'don recu',
          'received gift',
          'cadeau recu',
          'inheritance',
          'heritage'
        ], // Renamed
        'investment': [
          'investment',
          'dividends',
          'interest',
          'capital gain',
          'investissement',
          'dividendes',
          'interet',
          'plus-value',
          'stocks',
          'shares',
          'actions',
          'crypto gain'
        ],
        'rental': [
          'rental income',
          'rent received',
          'property income',
          'location',
          'loyer recu',
          'revenu immobilier'
        ],
        'government': [
          'government payment',
          'benefit',
          'pension',
          'social security',
          'aide sociale',
          'retraite',
          'allocation familiale'
        ],
        'reimbursement': ['reimbursement', 'refund', 'remboursement'],
        'other': [
          'other income',
          'miscellaneous income',
          'autre revenu',
          'divers revenu'
        ]
        // Add more specific income categories and keywords
      };

  String? _extractDescription(
      String command, TransactionType type, double? amount, DateTime? date) {
    // First, try to find explicit description markers
    // Common prefixes users might use to indicate a description
    final descriptionPrefixes = [
      'description', 'desc', 'note', 'remark', 'reason', 'comment', 'for',
      'details',
      'description:', 'desc:', 'note:', 'details:',
      'description is', 'note is', 'purpose is',
      'comment:', 'regarding', 'about',
      // French equivalents
      'description', 'desc', 'note', 'remarque', 'commentaire', 'pour',
      'détails',
      'à propos de', 'concernant', 'au sujet de'
    ];

    // Try to match patterns like "description: buying groceries" or "note is buying groceries"
    for (final prefix in descriptionPrefixes) {
      // Use word boundary for prefix and allow for colon or "is" after the prefix
      final pattern = RegExp(
          r'\b' +
              RegExp.escape(prefix) +
              r'\b\s*(?::|is|est|sont)?\s+(.+?)(?:\s+(?:with|using|via|by|par|avec)\b|$)',
          caseSensitive: false);

      final match = pattern.firstMatch(command);
      if (match != null && match.group(1) != null) {
        String explicitDesc = match.group(1)!.trim();
        // Clean up trailing punctuation
        explicitDesc = explicitDesc.replaceAll(RegExp(r'[\.,;:]+$'), '').trim();

        // Only return if we have something substantial
        if (explicitDesc.length > 2) {
          return explicitDesc;
        }
      }
    }

    // Check for "for" pattern separately (e.g., "spent 5000 for lunch")
    // This is common in expense descriptions
    if (type == TransactionType.expense) {
      final forPattern = RegExp(
          r'\b(?:for|pour)\s+(.+?)(?:\s+(?:with|using|via|by|par|avec)\b|$)',
          caseSensitive: false);
      final forMatch = forPattern.firstMatch(command);
      if (forMatch != null && forMatch.group(1) != null) {
        String forDesc = forMatch.group(1)!.trim();
        // Remove common noise words that might appear after "for"
        forDesc = forDesc
            .replaceAll(
                RegExp(
                    r'\b(?:the|my|her|his|our|their|this|that|le|la|les|mon|ma|mes|son|sa|ses)\b',
                    caseSensitive: false),
                '')
            .trim();
        forDesc = forDesc.replaceAll(RegExp(r'[\.,;:]+$'), '').trim();

        if (forDesc.length > 2) {
          return forDesc;
        }
      }
    }

    // Fallback to original extraction method if no explicit description found
    // Start with the original cleaned command
    String potentialDesc = command;

    // --- Removal Steps --- (Order can matter)

    // 1. Remove Explicit Type Phrases (more specific first)
    potentialDesc = potentialDesc
        .replaceFirst(
            RegExp(
                r'^\s*(add|at|ajouter)\s+(expense|income|depense|revenu)\b'), // Added 'at' here
            '')
        .trim();

    // 2. Remove Amount
    if (amount != null) {
      // Create various representations of the amount for removal
      String amountStrInt = amount.toInt().toString();
      String amountStrDecimal = amount.toStringAsFixed(
          amount.truncateToDouble() == amount ? 0 : 2); // Basic decimal check
      String amountStrComma = amount.toInt().toString().replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
      String amountStrDot = amount.toInt().toString().replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
      String amountStrK =
          '${(amount / 1000).toStringAsFixed((amount / 1000).truncateToDouble() == (amount / 1000) ? 0 : 1)}k';

      List<String> amountRepresentations = [
        amountStrInt,
        amountStrDecimal,
        amountStrComma,
        amountStrDot
      ];
      if (amount >= 1000 && amount % 1000 == 0) {
        amountRepresentations.add(amountStrK);
      }

      // Add French number words if they matched the amount
      Map<String, int> frenchNumbers = _getFrenchNumbersMap();
      frenchNumbers.forEach((key, value) {
        if (value == amount.toInt()) {
          amountRepresentations.add(key);
        }
      });

      // Remove amount representations, trying longer ones first, with optional currency
      amountRepresentations
          .sort((a, b) => b.length.compareTo(a.length)); // Sort desc by length
      for (String rep in amountRepresentations) {
        // Regex to match the amount representation, potentially followed by currency/unit, as a whole word/phrase
        potentialDesc = potentialDesc.replaceAll(
            RegExp(
                r'\b' +
                    RegExp.escape(rep) +
                    r'\s*(xaf|cfa|fcfa|f\.?cfa|francs?(\s+cfa)?)?\b',
                caseSensitive: false),
            '');
      }
    }

    // 3. Remove Date References
    // Simple relative terms (today, yesterday, etc.)
    potentialDesc = potentialDesc.replaceAll(
        RegExp(
            r'\b(today|yesterday|tomorrow|hier|demain|avant-hier|apres-demain)\b',
            caseSensitive: false),
        '');
    potentialDesc = potentialDesc.replaceAll(
        RegExp(r"\baujourd'hui\b", caseSensitive: false),
        ''); // Use double-quoted raw string
    // Week references
    potentialDesc = potentialDesc.replaceAll(
        RegExp(
            r'\b(last week|this week|next week|la semaine derniere|cette semaine|la semaine prochaine|semaine passee)\b',
            caseSensitive: false),
        '');
    // Time of day
    potentialDesc = potentialDesc.replaceAll(
        RegExp(
            r'\b(this morning|this afternoon|this evening|ce matin|cet apres-midi|ce soir)\b',
            caseSensitive: false),
        '');
    // Days of the week
    potentialDesc = potentialDesc.replaceAll(
        RegExp(
            r'\b(mon|tue|wed|thu|fri|sat|sun|lun|mar|mer|jeu|ven|sam|dim)(?:day|di|credi|di|dredi|edi|anche)?\b',
            caseSensitive: false),
        '');
    // Months (abbreviations are safer)
    potentialDesc = potentialDesc.replaceAll(
        RegExp(
            r'\b(jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec|janv|fevr|mars|avr|mai|juin|juil|aout|sept|octo|nove|dece)\b',
            caseSensitive: false),
        '');
    // Specific date formats (less aggressive)
    potentialDesc = potentialDesc.replaceAll(
        RegExp(r'\b\d{1,2}[/\-\.]\d{1,2}(?:[/\-\.]\d{2,4})?\b',
            caseSensitive: false),
        '');

    // 4. Remove Payment Method Keywords (use a combined list)
    // Get all keywords from the map, flatten the list, remove duplicates, convert to list
    List<String> paymentKeywords =
        _getPaymentKeywordsMap().values.expand((list) => list).toSet().toList();
    paymentKeywords
        .sort((a, b) => b.length.compareTo(a.length)); // Remove longer first
    for (String pk in paymentKeywords) {
      if (pk.length < 3)
        continue; // Avoid removing short words like 'on', 'at' if they overlap
      potentialDesc = potentialDesc.replaceAll(
          RegExp(r'\b' + RegExp.escape(pk) + r'\b', caseSensitive: false), '');
    }

    // 5. Remove Category Name (if identified confidently)
    // Re-extract category using a higher threshold to be sure before removing
    String? confirmedCategoryId =
        _extractCategory(command, type); // Use original command here
    if (confirmedCategoryId != null) {
      final category = _categoryController.categories
          .firstWhereOrNull((c) => c.id == confirmedCategoryId);
      if (category != null) {
        potentialDesc = potentialDesc.replaceAll(
            RegExp(r'\b' + RegExp.escape(category.name.toLowerCase()) + r'\b',
                caseSensitive: false),
            '');
      }
    }

    // 6. Remove common type/action keywords (less specific)
    potentialDesc = potentialDesc.replaceAll(
        RegExp(
            r'\b(expense|income|depense|revenu|spent|paid|bought|received|earned|got|paye|achete|recu|gagne|obtenu|cost|charge|bill|payment|sale|achat)\b',
            caseSensitive: false),
        '');

    // 7. Remove common prepositions/conjunctions that might be left over
    potentialDesc = potentialDesc.replaceAll(
        RegExp(
            r'\b(for|on|pour|sur|with|using|par|avec|via|by|at|de|des|du|a|in|en)\b',
            caseSensitive: false),
        '');

    // 8. Clean up extra whitespace and leading/trailing punctuation
    potentialDesc = potentialDesc.replaceAll(RegExp(r'\s{2,}'), ' ').trim();
    potentialDesc =
        potentialDesc.replaceAll(RegExp(r'^[\.,;:]+|[\.,;:]+$'), '').trim();

    // Return the cleaned string if it's meaningful, otherwise null
    return potentialDesc.length > 2 ? potentialDesc : null;
  }

  // Helper to get French numbers map
  Map<String, int> _getFrenchNumbersMap() => {
        'mille': 1000,
        'deux mille': 2000,
        'trois mille': 3000,
        'quatre mille': 4000,
        'cinq mille': 5000,
        'dix mille': 10000,
        'vingt mille': 20000,
        'cinquante mille': 50000,
        'cent mille': 100000,
        'un million': 1000000,
        'deux millions': 2000000,
        'cinq millions': 5000000,
        'dix millions': 10000000,
        'mil': 1000,
        'deux mil': 2000,
        'cinq mil': 5000,
        'dix mil': 10000,
      };

  // Helper to get all payment keywords
  Map<PaymentMethod, List<String>> _getPaymentKeywordsMap() => {
        PaymentMethod.cash: [
          'cash',
          'money',
          'especes',
          'liquide',
          'argent liquide',
          'hard cash',
          'physical cash',
          'notes',
          'coins',
          'paper money',
          'cash money',
          'espece',
          'paid in cash',
          'paye en especes',
          'cash payment',
          'paiement en especes',
          'liquid cash',
          'petty cash',
          'pocket money',
          'by cash',
          'in cash',
          'avec du liquide',
          'cashe',
          'kash',
          'ca\$h',
          'monney',
          'liqid',
          'likit',
          'monies',
          'cash on hand',
          'argent comptant',
          'billets',
          'pieces',
          'monnaie',
          'fiduciaire',
          'franc',
          'francs',
          'cfa',
          'fcfa',
          'dollar',
          'dollars',
          'naira',
          'cedis',
          'shilling',
          'birr',
          'dirham',
          'gourdes',
          'rand',
          'peso',
          'dinar'
        ],
        PaymentMethod.card: [
          'card',
          'credit card',
          'debit card',
          'bank card',
          'carte de credit',
          'carte bancaire',
          'carte',
          'visa',
          'mastercard',
          'master card',
          'amex',
          'american express',
          'discover',
          'paid by card',
          'paye par carte',
          'card payment',
          'paiement par carte',
          'paid with card',
          'paye avec carte',
          'via card',
          'by card',
          'with card',
          'par carte',
          'avec carte',
          'visa card',
          'master',
          'carte bleu',
          'carte visa',
          'cb',
          'credit',
          'debit',
          'plastique',
          'plastic',
          'kard',
          'atm card',
          'bank plastic',
          'carte electron',
          'tap to pay',
          'contactless',
          'sans contact',
          'nfc',
          'chip',
          'puce',
          'swipe',
          'terminal',
          'pos',
          'tpe',
          'terminal de paiement',
          'swiped',
          'tapped'
        ],
        PaymentMethod.bankTransfer: [
          'transfer',
          'bank transfer',
          'transfert bancaire',
          'wire transfer',
          'virement',
          'bank deposit',
          'depot bancaire',
          'banking',
          'bank payment',
          'paiement bancaire',
          'direct deposit',
          'deposit direct',
          'online banking',
          'banque en ligne',
          'internet banking',
          'bank to bank',
          'banque a banque',
          'account transfer',
          'transfert de compte',
          'bank wire',
          'wire',
          'paid by transfer',
          'paye par virement',
          'to account',
          'vers compte',
          'transf',
          'xfer',
          'swift',
          'iban',
          'interbancario',
          'viremnt',
          'vrmt',
          'to bank',
          'a la banque',
          'ach',
          'sepa',
          'rtgs',
          'neft',
          'imps',
          'chaps',
          'bacs',
          'giro',
          'electronic transfer',
          'transfert electronique',
          'remittance',
          'ecobank',
          'uba',
          'afriland',
          'bicec',
          'societe generale',
          'sgbc',
          'citibank',
          'atlantic bank',
          'bank of africa',
          'stanbic',
          'zenith',
          'access',
          'absa',
          'standard chartered',
          'gtbank'
        ],
        PaymentMethod.mobilePayment: [
          'mobile money',
          'momo',
          'orange money',
          'mtn money',
          'airtel money',
          'wave',
          'mobile payment',
          'paiement mobile',
          'money mobile',
          'moov money',
          'vodacom mpesa',
          'mpesa',
          'ecocash',
          'tigo cash',
          'om',
          'yoomee',
          'orange',
          'mtn',
          'airtel',
          'moov',
          'camtel',
          'nexttel',
          'blue money',
          'mobile wallet',
          'portefeuille mobile',
          'digital wallet',
          'e-wallet',
          'ewallet',
          'mobile transfer',
          'transfert mobile',
          'ussd payment',
          'paiement ussd',
          'qr code payment',
          'paiement par qr code',
          'scan to pay',
          'scanner pour payer',
          'phone payment',
          'paiement par telephone',
          'pay by phone',
          'payer par telephone',
          'orange pay',
          'mtn momo',
          'airtel money',
          'by mobile',
          'via mobile',
          'par mobile',
          'mobil money',
          'mony mobile',
          'monile payment',
          'orangemoney',
          'mtn mony',
          'mpsa',
          'momoney',
          'mo money',
          'mobilmoney',
          'mobile mony',
          'orng money',
          'phone money',
          'telephne money',
          'mobil moni',
          'moni mobil',
          'mobil paiement',
          'mtn mobil',
          'ornj moni',
          'muv mani',
          'mobyle',
          'mm',
          'fon pay',
          'movil',
          'celular',
          'telefono',
          'watsap pay',
          'whatsapp pay',
          'digital',
          'emoney',
          'e-money',
          'mobile banking',
          'mtn mobile',
          'om payment',
          'orange payment',
          'orng pay',
          'mtn pay',
          'paga',
          'palmpay',
          'opay',
          'kuda',
          'flutter wave',
          'flutterwave',
          'paystack'
        ],
        PaymentMethod.cheque: [
          'cheque',
          'check',
          'bank cheque',
          'bank check',
          'cheque bancaire',
          'check payment',
          'paiement par cheque',
          'paid by cheque',
          'paye par cheque',
          'cheque payment',
          'personal cheque',
          'cheque personnel',
          'certified cheque',
          'cheque certifie',
          'cashier\'s cheque',
          'cashiers check',
          'chq',
          'chk',
          'cheque book',
          'checkbook',
          'cashed cheque',
          'encashed',
          'pay check',
          'paycheck',
          'post-dated cheque',
          'crossed cheque',
          'bearer cheque',
          'order cheque',
          'bank draft'
        ],
        PaymentMethod.crypto: [
          'bitcoin',
          'btc',
          'ethereum',
          'eth',
          'crypto',
          'cryptocurrency',
          'crypto-monnaie',
          'usdt',
          'tether',
          'blockchain',
          'dogecoin',
          'crypto payment',
          'paiement crypto',
          'paid in crypto',
          'paye en crypto',
          'usdc',
          'binance',
          'binance pay',
          'coin',
          'wallet',
          'portefeuille crypto',
          'crypto wallet',
          'digital currency',
          'monnaie numerique',
          'crypto transfer',
          'transfert crypto',
          'satoshi',
          'wei',
          'gwei',
          'token',
          'jetons',
          'xrp',
          'solana'
        ],
        PaymentMethod.other: ['other', 'autre']
      };

  PaymentMethod? _extractPaymentMethod(String command) {
    // Use the helper to get keywords
    final keywordMap = _getPaymentKeywordsMap();

    // Context patterns (prioritize these)
    final List<RegExp> paymentContextPatterns = [
      // Add more specific patterns if needed
      RegExp(r'paid (?:with|in|using|via|by) cash', caseSensitive: false),
      RegExp(r'paye (?:avec|en) especes', caseSensitive: false),
      RegExp(r'using cash', caseSensitive: false),
      RegExp(r'in cash', caseSensitive: false),
      RegExp(r'avec (?:du )?(?:argent|especes|liquide)', caseSensitive: false),
      RegExp(
          r'paid (?:with|using|via|by) (?:my |a |the )?(?:credit |debit |bank |visa |master)?card',
          caseSensitive: false),
      RegExp(r'paye (?:avec|par) (?:ma |une |la )?carte', caseSensitive: false),
      RegExp(
          r'using (?:my |a |the )?(?:credit |debit |bank |visa |master)?card',
          caseSensitive: false),
      RegExp(r'via (?:credit |debit |bank |visa |master)?card',
          caseSensitive: false),
      RegExp(r'by (?:credit |debit |bank |visa |master)?card',
          caseSensitive: false),
      RegExp(r'swiped (?:my |the |a )?card', caseSensitive: false),
      RegExp(r'tap(?:ped)?(?: to)? pay', caseSensitive: false),
      RegExp(r'(?:bank|wire) (?:transfer|payment|deposit)',
          caseSensitive: false),
      RegExp(r'paid (?:with|using|via|by) (?:bank|wire) (?:transfer|payment)',
          caseSensitive: false),
      RegExp(r'transfert? bancaire', caseSensitive: false),
      RegExp(r'virement bancaire', caseSensitive: false),
      RegExp(r'paye (?:avec|par) (?:transfert|virement) bancaire',
          caseSensitive: false),
      RegExp(
          r'(?:mobile|momo|orange|mtn|airtel|moov|wave) (?:money|payment|pay)',
          caseSensitive: false),
      RegExp(
          r'paid (?:with|using|via|by) (?:mobile|momo|orange|mtn|airtel|moov|wave) (?:money|payment|pay)',
          caseSensitive: false),
      RegExp(
          r'paye (?:avec|par) (?:mobile|momo|orange|mtn|airtel|moov) (?:money|monnaie)',
          caseSensitive: false),
      RegExp(r'(?:via|using|with|by) (?:mpesa|ecocash|tigo cash)',
          caseSensitive: false),
      RegExp(r'(?:by|with|using|via) (?:cheque|check)', caseSensitive: false),
      RegExp(r'paid (?:by|with|using|via) (?:a |my |the )?(?:cheque|check)',
          caseSensitive: false),
      RegExp(r'paye (?:par|avec) (?:cheque|cheq)', caseSensitive: false),
      RegExp(r'(?:by|with|using|via) (?:bitcoin|crypto|eth|btc)',
          caseSensitive: false),
      RegExp(r'paid (?:by|with|using|via) (?:bitcoin|crypto|eth|btc)',
          caseSensitive: false),
      RegExp(r'paye (?:par|avec) (?:bitcoin|crypto|eth|btc)',
          caseSensitive: false),
    ];

    // Step 1: Check context patterns (high confidence - return immediately)
    for (final pattern in paymentContextPatterns) {
      Match? contextMatch = pattern.firstMatch(command);
      if (contextMatch != null) {
        String matchedPattern = contextMatch.group(0)?.toLowerCase() ?? '';
        if (matchedPattern.contains('cash') ||
            matchedPattern.contains('espece') ||
            matchedPattern.contains('liquide')) return PaymentMethod.cash;
        if (matchedPattern.contains('card') ||
            matchedPattern.contains('carte') ||
            matchedPattern.contains('visa') ||
            matchedPattern.contains('master') ||
            matchedPattern.contains('tap') ||
            matchedPattern.contains('swipe')) return PaymentMethod.card;
        if (matchedPattern.contains('transfer') ||
            matchedPattern.contains('virement') ||
            matchedPattern.contains('bank') ||
            matchedPattern.contains('wire')) return PaymentMethod.bankTransfer;
        if (matchedPattern.contains('mobile') ||
            matchedPattern.contains('momo') ||
            matchedPattern.contains('orange') ||
            matchedPattern.contains('mtn') ||
            matchedPattern.contains('mpesa') ||
            matchedPattern.contains('wave')) return PaymentMethod.mobilePayment;
        if (matchedPattern.contains('cheque') ||
            matchedPattern.contains('check') ||
            matchedPattern.contains('chq')) return PaymentMethod.cheque;
        if (matchedPattern.contains('bitcoin') ||
            matchedPattern.contains('crypto') ||
            matchedPattern.contains('eth') ||
            matchedPattern.contains('btc')) return PaymentMethod.crypto;
        // If a pattern matches but doesn't map clearly, ignore and continue to keyword matching
      }
    }

    // Step 2: Fuzzy matching for individual terms, weighted scoring
    Map<PaymentMethod, double> scores = {
      PaymentMethod.cash: 0,
      PaymentMethod.card: 0,
      PaymentMethod.bankTransfer: 0,
      PaymentMethod.mobilePayment: 0,
      PaymentMethod.cheque: 0,
      PaymentMethod.crypto: 0,
      PaymentMethod.other: 0
    };

    final words = command.split(' ');
    for (final word in words) {
      String cleanWord = word
          .replaceAll(RegExp(r'[^\w-$]'), '')
          .toLowerCase(); // Keep $ for cash keywords
      if (cleanWord.length < 3 &&
          !['om', 'cb', 'mm', 'btc', 'eth'].contains(cleanWord))
        continue; // Allow specific short terms

      for (final entry in keywordMap.entries) {
        PaymentMethod method = entry.key;
        List<String> keywords = entry.value;
        // Use a slightly lower threshold for keyword spotting than type/category?
        String? match = _findBestMatch(cleanWord, keywords, threshold: 0.80);
        if (match != null) {
          double similarity = _calculateStringSimilarity(cleanWord, match);
          scores[method] =
              scores[method]! + similarity; // Base score on similarity
        }
      }
    }

    // Boost for multi-word phrases (already done in _findBestMatch indirectly? No, check full command)
    for (final entry in keywordMap.entries) {
      PaymentMethod method = entry.key;
      List<String> multiWordKeywords =
          entry.value.where((k) => k.contains(' ')).toList();
      for (final keyword in multiWordKeywords) {
        if (command.contains(keyword.toLowerCase())) {
          // Check against lowercase command
          scores[method] =
              scores[method]! + 1.5; // Strong boost for direct phrase match
        }
      }
    }

    // Find best match based on score
    PaymentMethod? bestMatch;
    double highestScore =
        0.7; // Minimum score threshold to consider a match (slightly higher than before)

    scores.forEach((method, score) {
      if (score > highestScore) {
        highestScore = score;
        bestMatch = method;
      } else if (score == highestScore && bestMatch != null) {
        // If scores are tied, maybe return null (ambiguous)? Or keep the first one found?
        // For now, let's prefer the first one that reached the highest score.
      }
    });

    // Return the best match if score is sufficient, otherwise null
    // Let the VoiceCommandResult handle the default to cash if this returns null.
    if (bestMatch != null) {
      print("Payment method selected: $bestMatch (Score: $highestScore)");
    } else {
      print(
          "No confident payment method match found (Highest score <= $highestScore). Will default later.");
    }
    return bestMatch;
  }

  bool _isPrecededByMonth(String text) {
    final monthPattern = RegExp(
        r'\b(jan|janv|feb|fevr|mar|mars|apr|avr|may|mai|jun|juin|jul|juil|aug|aout|sep|sept|oct|octo|nov|nove|dec|dece)(?:\.|uary|ruary|ch|ril|ember|embre)?\s*$',
        caseSensitive: false);
    return monthPattern.hasMatch(text.trim());
  }
}
