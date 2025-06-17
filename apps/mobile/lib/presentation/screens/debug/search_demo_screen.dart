import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/enhanced_search_providers.dart';
import '../../widgets/common/unified_app_bar.dart';

/// Demo screen to showcase enhanced search features
class SearchDemoScreen extends ConsumerWidget {
  const SearchDemoScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchState = ref.watch(searchStateProvider);
    final searchActions = ref.watch(searchActionsProvider);

    return Scaffold(
      appBar: UnifiedAppBars.withBackButton(
        title: 'Search System Demo',
        fallbackRoute: '/home',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 24),
            _buildSearchScreenButtons(context),
            const SizedBox(height: 24),
            _buildSearchStateInfo(context, searchState),
            const SizedBox(height: 24),
            _buildSearchActions(context, searchActions),
            const SizedBox(height: 24),
            _buildAnalytics(context, ref),
            const SizedBox(height: 24),
            _buildCacheInfo(context, ref),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.search,
                  color: Theme.of(context).primaryColor,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'Enhanced Search System',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Phase 1: Enhanced Search Foundation',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '✅ Unified Search Service\n'
              '✅ Advanced Search Providers\n'
              '✅ Search Analytics & Caching\n'
              '✅ Intelligent Suggestions',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchScreenButtons(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Search Screens',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => context.push('/clean/enhanced-search'),
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Enhanced Search'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchStateInfo(BuildContext context, SearchState searchState) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current Search State',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Query', searchState.query.isEmpty ? 'None' : searchState.query),
            _buildInfoRow('Debounced Query', searchState.debouncedQuery.isEmpty ? 'None' : searchState.debouncedQuery),
            _buildInfoRow('Loading', searchState.isLoading ? 'Yes' : 'No'),
            _buildInfoRow('Error', searchState.error ?? 'None'),
            _buildInfoRow('History Items', '${searchState.history.length}'),
            _buildInfoRow('Suggestions', '${searchState.suggestions.length}'),
            _buildInfoRow('Popular Searches', '${searchState.popularSearches.length}'),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchActions(BuildContext context, SearchActions searchActions) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Search Actions',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton(
                  onPressed: () => searchActions.updateQuery('milk'),
                  child: const Text('Search "milk"'),
                ),
                ElevatedButton(
                  onPressed: () => searchActions.updateQuery('bread'),
                  child: const Text('Search "bread"'),
                ),
                ElevatedButton(
                  onPressed: () => searchActions.updateQuery('eggs'),
                  child: const Text('Search "eggs"'),
                ),
                ElevatedButton(
                  onPressed: () => searchActions.clearQuery(),
                  child: const Text('Clear Query'),
                ),
                ElevatedButton(
                  onPressed: () => searchActions.clearHistory(),
                  child: const Text('Clear History'),
                ),
                ElevatedButton(
                  onPressed: () => searchActions.clearCache(),
                  child: const Text('Clear Cache'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalytics(BuildContext context, WidgetRef ref) {
    final analytics = ref.watch(searchAnalyticsProvider);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Search Analytics',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (analytics.isEmpty)
              const Text('No search analytics yet. Try searching for something!')
            else
              ...analytics.entries.map((entry) => 
                _buildInfoRow(entry.key, '${entry.value} searches'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCacheInfo(BuildContext context, WidgetRef ref) {
    final cacheStats = ref.watch(searchCacheStatsProvider);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cache Statistics',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Cached Queries', '${cacheStats['cached_queries']}'),
            _buildInfoRow('Cache Size', '${(cacheStats['cache_size_mb'] as double).toStringAsFixed(2)} MB'),
            _buildInfoRow('Oldest Entry', 
              cacheStats['oldest_cache_entry'] != null 
                ? (cacheStats['oldest_cache_entry'] as DateTime).toString().split('.')[0]
                : 'None'
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
