import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import '../../../core/services/location_service.dart';

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
  final LocationService _locationService = LocationService();

  // Sample search results - in a real app, this would come from a places API
  final List<Map<String, String>> _searchResults = [
    {'name': 'Market Area', 'address': 'Main Market Road', 'area': 'Commercial Area'},
    {'name': 'Hospital Area', 'address': 'Hospital Road', 'area': 'Medical District'},
    {'name': 'College Area', 'address': 'College Road', 'area': 'Educational Zone'},
    {'name': 'Bus Stand', 'address': 'Transport Hub', 'area': 'Transport Area'},
    {'name': 'Police Station', 'address': 'Police Line', 'area': 'Administrative Area'},
    {'name': 'Stadium', 'address': 'Sports Complex', 'area': 'Sports Zone'},
    {'name': 'Post Office', 'address': 'Main Post Office', 'area': 'Postal Area'},
    {'name': 'Railway Station', 'address': 'Railway Complex', 'area': 'Transport Hub'},
  ];

  List<Map<String, String>> _filteredResults = [];
  bool _isGettingLocation = false;

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

  Future<void> _useCurrentLocation() async {
    setState(() {
      _isGettingLocation = true;
    });

    try {
      // Get current location with address
      LocationData? locationData = await _locationService.getCurrentLocationWithAddress();

      if (locationData != null && mounted) {
        widget.onLocationSelected({
          'address': locationData.address ?? 'GPS Location Detected',
          'area': '${locationData.city ?? ''}, ${locationData.state ?? ''}'.trim(),
        });
        Navigator.pop(context);
      } else {
        // Show error if location detection failed
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Unable to detect current location. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error getting current location: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location detection failed. Please check GPS settings.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGettingLocation = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
            onPressed: _isGettingLocation ? null : _useCurrentLocation,
            child: _isGettingLocation
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.green,
                    ),
                  )
                : const Text(
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
                              color: Colors.green.withOpacity(0.1),
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
