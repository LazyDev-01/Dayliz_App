import 'package:equatable/equatable.dart';

/// Represents a search suggestion with metadata
class SearchSuggestion extends Equatable {
  final String text;
  final SearchSuggestionType type;
  final int? popularity;
  final DateTime? lastUsed;
  final String? category;
  final Map<String, dynamic>? metadata;

  const SearchSuggestion({
    required this.text,
    required this.type,
    this.popularity,
    this.lastUsed,
    this.category,
    this.metadata,
  });

  @override
  List<Object?> get props => [
        text,
        type,
        popularity,
        lastUsed,
        category,
        metadata,
      ];

  SearchSuggestion copyWith({
    String? text,
    SearchSuggestionType? type,
    int? popularity,
    DateTime? lastUsed,
    String? category,
    Map<String, dynamic>? metadata,
  }) {
    return SearchSuggestion(
      text: text ?? this.text,
      type: type ?? this.type,
      popularity: popularity ?? this.popularity,
      lastUsed: lastUsed ?? this.lastUsed,
      category: category ?? this.category,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'type': type.name,
      'popularity': popularity,
      'lastUsed': lastUsed?.toIso8601String(),
      'category': category,
      'metadata': metadata,
    };
  }

  factory SearchSuggestion.fromJson(Map<String, dynamic> json) {
    return SearchSuggestion(
      text: json['text'] as String,
      type: SearchSuggestionType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => SearchSuggestionType.query,
      ),
      popularity: json['popularity'] as int?,
      lastUsed: json['lastUsed'] != null 
          ? DateTime.parse(json['lastUsed'] as String)
          : null,
      category: json['category'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }
}

/// Types of search suggestions
enum SearchSuggestionType {
  /// User's search history
  history,
  
  /// Popular searches across all users
  popular,
  
  /// Product name suggestions
  product,
  
  /// Category suggestions
  category,
  
  /// Brand suggestions
  brand,
  
  /// General query suggestions
  query,
  
  /// Trending searches
  trending,
  
  /// Autocomplete suggestions
  autocomplete,
}

extension SearchSuggestionTypeExtension on SearchSuggestionType {
  String get displayName {
    switch (this) {
      case SearchSuggestionType.history:
        return 'Recent';
      case SearchSuggestionType.popular:
        return 'Popular';
      case SearchSuggestionType.product:
        return 'Product';
      case SearchSuggestionType.category:
        return 'Category';
      case SearchSuggestionType.brand:
        return 'Brand';
      case SearchSuggestionType.query:
        return 'Search';
      case SearchSuggestionType.trending:
        return 'Trending';
      case SearchSuggestionType.autocomplete:
        return 'Suggestion';
    }
  }

  String get iconName {
    switch (this) {
      case SearchSuggestionType.history:
        return 'history';
      case SearchSuggestionType.popular:
        return 'trending_up';
      case SearchSuggestionType.product:
        return 'shopping_bag';
      case SearchSuggestionType.category:
        return 'category';
      case SearchSuggestionType.brand:
        return 'business';
      case SearchSuggestionType.query:
        return 'search';
      case SearchSuggestionType.trending:
        return 'whatshot';
      case SearchSuggestionType.autocomplete:
        return 'auto_awesome';
    }
  }
}

/// Search analytics data
class SearchAnalytics extends Equatable {
  final Map<String, int> searchCounts;
  final Map<String, DateTime> lastSearchTimes;
  final List<String> trendingSearches;
  final Map<String, double> searchSuccessRates;
  final DateTime lastUpdated;

  const SearchAnalytics({
    required this.searchCounts,
    required this.lastSearchTimes,
    required this.trendingSearches,
    required this.searchSuccessRates,
    required this.lastUpdated,
  });

  @override
  List<Object?> get props => [
        searchCounts,
        lastSearchTimes,
        trendingSearches,
        searchSuccessRates,
        lastUpdated,
      ];

  int getTotalSearches() {
    return searchCounts.values.fold(0, (sum, count) => sum + count);
  }

  List<String> getTopSearches({int limit = 10}) {
    final sortedEntries = searchCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sortedEntries
        .take(limit)
        .map((entry) => entry.key)
        .toList();
  }

  double getSearchSuccessRate(String query) {
    return searchSuccessRates[query] ?? 0.0;
  }

  Map<String, dynamic> toJson() {
    return {
      'searchCounts': searchCounts,
      'lastSearchTimes': lastSearchTimes.map(
        (key, value) => MapEntry(key, value.toIso8601String()),
      ),
      'trendingSearches': trendingSearches,
      'searchSuccessRates': searchSuccessRates,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  factory SearchAnalytics.fromJson(Map<String, dynamic> json) {
    return SearchAnalytics(
      searchCounts: Map<String, int>.from(json['searchCounts'] ?? {}),
      lastSearchTimes: (json['lastSearchTimes'] as Map<String, dynamic>? ?? {})
          .map((key, value) => MapEntry(key, DateTime.parse(value as String))),
      trendingSearches: List<String>.from(json['trendingSearches'] ?? []),
      searchSuccessRates: Map<String, double>.from(json['searchSuccessRates'] ?? {}),
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
    );
  }

  SearchAnalytics copyWith({
    Map<String, int>? searchCounts,
    Map<String, DateTime>? lastSearchTimes,
    List<String>? trendingSearches,
    Map<String, double>? searchSuccessRates,
    DateTime? lastUpdated,
  }) {
    return SearchAnalytics(
      searchCounts: searchCounts ?? this.searchCounts,
      lastSearchTimes: lastSearchTimes ?? this.lastSearchTimes,
      trendingSearches: trendingSearches ?? this.trendingSearches,
      searchSuccessRates: searchSuccessRates ?? this.searchSuccessRates,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}
