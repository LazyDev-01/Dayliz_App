import 'package:flutter/material.dart';

class SearchBarWidget extends StatefulWidget {
  final TextEditingController controller;
  final List<String> suggestions;
  final Function(String) onSearch;
  final String hintText;
  
  const SearchBarWidget({
    Key? key,
    required this.controller,
    required this.suggestions,
    required this.onSearch,
    this.hintText = 'Search products...',
  }) : super(key: key);

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  bool _showSuggestions = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: widget.controller,
          decoration: InputDecoration(
            hintText: widget.hintText,
            prefixIcon: const Icon(Icons.search),
            suffixIcon: widget.controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      widget.controller.clear();
                      setState(() {
                        _showSuggestions = false;
                      });
                    },
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.grey[200],
            contentPadding: const EdgeInsets.symmetric(vertical: 8),
          ),
          onChanged: (value) {
            setState(() {
              _showSuggestions = value.isNotEmpty;
            });
          },
          onTap: () {
            setState(() {
              _showSuggestions = widget.controller.text.isNotEmpty;
            });
          },
          onSubmitted: widget.onSearch,
        ),
        if (_showSuggestions)
          _buildSuggestionsList(),
      ],
    );
  }
  
  Widget _buildSuggestionsList() {
    return Container(
      color: Colors.white,
      constraints: const BoxConstraints(maxHeight: 200),
      width: double.infinity,
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: widget.suggestions.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(widget.suggestions[index]),
            leading: const Icon(Icons.search),
            onTap: () {
              widget.controller.text = widget.suggestions[index];
              setState(() {
                _showSuggestions = false;
              });
              widget.onSearch(widget.suggestions[index]);
            },
          );
        },
      ),
    );
  }
} 