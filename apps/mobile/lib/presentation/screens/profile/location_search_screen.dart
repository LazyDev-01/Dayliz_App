import 'package:flutter/material.dart';

class LocationSearchScreen extends StatefulWidget {
  final Function(Map<String, String>) onLocationSelected;

  const LocationSearchScreen({
    Key? key,
    required this.onLocationSelected,
  }) : super(key: key);

  @override
  State<LocationSearchScreen> createState() => _LocationSearchScreenState();
}

class _LocationSearchScreenState extends State<LocationSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final List<Map<String, String>> _searchResults = [
    {'name': 'Tura Market', 'address': 'Main Market Road, Tura', 'area': 'Commercial Area'},
    {'name': 'Tura Civil Hospital', 'address': 'Hospital Road, Tura', 'area': 'Medical District'},
    {'name': 'Tura Government College', 'address': 'College Road, Tura', 'area': 'Educational Zone'},
    {'name': 'Tura Bus Stand', 'address': 'Transport Hub, Tura', 'area': 'Transport Area'},
    {'name': 'Tura Police Station', 'address': 'Police Line, Tura', 'area': 'Administrative Area'},
    {'name': 'Tura Stadium', 'address': 'Sports Complex, Tura', 'area': 'Sports Zone'},
    {'name': 'Tura Post Office', 'address': 'Main Post Office, Tura', 'area': 'Postal Area'},
    {'name': 'Tura Railway Station', 'address': 'Railway Complex, Tura', 'area': 'Transport Hub'},
  ];

  List<Map<String, String>> _filteredResults = [];

  @override
  void initState() {
    super.initState();
    _filteredResults = _searchResults;
    _searchController.addListener(_filterResults);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterResults);
    _searchController.dispose();
    super.dispose();
  }

  void _filterResults() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredResults = _searchResults;
      } else {
        _filteredResults = _searchResults.where((result) {
          return result['name']!.toLowerCase().contains(query) ||
                 result['address']!.toLowerCase().contains(query) ||
                 result['area']!.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  void _selectLocation(Map<String, String> location) {
    widget.onLocationSelected({
      'address': location['address']!,
      'area': location['area']!,
    });
    Navigator.pop(context);
  }

  void _useCurrentLocation() {
    widget.onLocationSelected({
      'address': 'Current GPS Location',
      'area': 'GPS detected',
    });
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true, // Important: Allow screen to resize when keyboard appears
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Search Location',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
        actions: [
          TextButton(
            onPressed: _useCurrentLocation,
            child: const Text(
              'Use Current',
              style: TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Search for area, landmark, address...',
                hintStyle: TextStyle(color: Colors.grey[500]),
                prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: Colors.grey[400]),
                        onPressed: () {
                          _searchController.clear();
                          FocusScope.of(context).unfocus();
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),
          
          // Results header
          if (_filteredResults.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Text(
                    '${_filteredResults.length} locations found',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          
          // Search results
          Expanded(
            child: _filteredResults.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.location_off,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No locations found',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Try searching with different keywords',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filteredResults.length,
                    itemBuilder: (context, index) {
                      final result = _filteredResults[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        elevation: 0,
                        color: Colors.grey[50],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: Colors.grey[200]!),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(
                              Icons.location_on,
                              color: Colors.green,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            result['name']!,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                result['address']!,
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                result['area']!,
                                style: TextStyle(
                                  color: Colors.green,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: Colors.grey,
                          ),
                          onTap: () => _selectLocation(result),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
