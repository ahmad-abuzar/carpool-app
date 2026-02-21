import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/location_search_service.dart';

/// Location Autocomplete with Bottom Sheet
/// Search loads in background, user clicks dropdown to see suggestions
class LocationAutocompleteField extends StatefulWidget {
  final String label;
  final IconData icon;
  final String? initialValue;
  final Function(LocationSuggestion) onLocationSelected;

  const LocationAutocompleteField({
    super.key,
    required this.label,
    required this.icon,
    this.initialValue,
    required this.onLocationSelected,
  });

  @override
  State<LocationAutocompleteField> createState() =>
      _LocationAutocompleteFieldState();
}

class _LocationAutocompleteFieldState extends State<LocationAutocompleteField> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final LocationSearchService _searchService = LocationSearchService();

  List<LocationSuggestion> _suggestions = [];
  bool _isLoading = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    if (widget.initialValue != null) {
      _controller.text = widget.initialValue!;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _searchLocations(String query) async {
    if (query.length < 2) {
      setState(() {
        _suggestions = [];
        _isLoading = false;
      });
      return;
    }

    setState(() => _isLoading = true);

    try {
      final results = await _searchService.searchLocations(query);

      if (mounted) {
        setState(() {
          _suggestions = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Search error: $e');
      if (mounted) {
        setState(() {
          _suggestions = [];
          _isLoading = false;
        });
      }
    }
  }

  void _showSuggestionsBottomSheet() {
    if (_suggestions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Type to search for locations'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Title
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Select Location (${_suggestions.length} found)',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),

            const Divider(height: 1),

            // Results list
            Expanded(
              child: ListView.builder(
                itemCount: _suggestions.length,
                itemBuilder: (context, index) {
                  final suggestion = _suggestions[index];
                  return ListTile(
                    leading: Icon(
                      Icons.location_on,
                      color: Theme.of(context).primaryColor,
                    ),
                    title: Text(
                      suggestion.displayName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: suggestion.type.isNotEmpty
                        ? Text(suggestion.type)
                        : null,
                    onTap: () {
                      Navigator.pop(context);
                      _selectLocation(suggestion);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _selectLocation(LocationSuggestion suggestion) {
    print('📍 Location selected: ${suggestion.displayName}');
    print('📍 Lat: ${suggestion.latitude}, Lon: ${suggestion.longitude}');
    _controller.text = suggestion.displayName;
    _focusNode.unfocus();
    widget.onLocationSelected(suggestion);
    print('✅ Callback triggered');
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            decoration: InputDecoration(
              labelText: widget.label,
              prefixIcon: Icon(widget.icon),
              // No suffixIcon - avoids layout issues
            ),
            onChanged: (value) {
              // Cancel previous timer
              if (_debounce?.isActive ?? false) _debounce!.cancel();

              // Start new timer - search after 500ms of no typing
              _debounce = Timer(const Duration(milliseconds: 500), () {
                _searchLocations(value);
              });
            },
          ),
        ),
        // Separate button outside TextField
        SizedBox(
          width: 48,
          height: 48,
          child: _isLoading
              ? const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : (_suggestions.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.arrow_drop_down),
                        onPressed: _showSuggestionsBottomSheet,
                        tooltip: 'Show suggestions',
                      )
                    : const SizedBox.shrink()),
        ),
      ],
    );
  }
}
