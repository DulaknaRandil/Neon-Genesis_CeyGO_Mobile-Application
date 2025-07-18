import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class SearchedPlaceScreen extends StatefulWidget {
  final String placeName;
  final String placeImage;

  SearchedPlaceScreen({required this.placeName, required this.placeImage});

  @override
  _SearchedPlaceScreenState createState() => _SearchedPlaceScreenState();
}

class _SearchedPlaceScreenState extends State<SearchedPlaceScreen> {
  String? placeImage;
  List<Map<String, String>> recommendedPlaces = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    placeImage = widget.placeImage; // Initialize the header image
    fetchRecommendedPlaces(
        widget.placeName.toLowerCase()); // Fetch recommended places
  }

  Future<void> fetchRecommendedPlaces(String name) async {
    try {
      final response = await http
          .get(Uri.parse('http://43.203.243.209/handle_get?name=$name'));
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        final places = jsonResponse['similar_places'] as List;

        List<Map<String, String>> placesWithImages = [];
        for (var placeName in places) {
          final imageUrl = await fetchPlaceImage(placeName);
          placesWithImages.add({
            'name': placeName,
            'image': imageUrl ?? 'https://via.placeholder.com/150',
          });
        }

        setState(() {
          recommendedPlaces = placesWithImages;
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load recommended places');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching data: $e')),
      );
    }
  }

  Future<String?> fetchPlaceImage(String placeName) async {
    try {
      final apiKey = ''; // Replace with your API key
      final response = await http.get(Uri.parse(
          'https://maps.googleapis.com/maps/api/place/findplacefromtext/json?input=$placeName&inputtype=textquery&fields=photos&key=$apiKey'));

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        final places = jsonResponse['candidates'] as List;
        if (places.isNotEmpty) {
          final photoReference = places[0]['photos'] != null
              ? places[0]['photos'][0]['photo_reference']
              : null;

          if (photoReference != null) {
            final photoUrl =
                'https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photoreference=$photoReference&key=$apiKey';
            return photoUrl;
          }
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(), // Header with main image
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'To get your best places, CeyGO AI assistant\nHere for You.',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Recommended Places in ${widget.placeName}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 16),
                  isLoading
                      ? Center(
                          child:
                              CircularProgressIndicator()) // Show a loader while loading
                      : _buildCards(), // Display recommended places
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      child: Stack(
        children: [
          Image.network(
            placeImage!,
            width: double.infinity,
            height: 200,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.grey[300],
                child: Center(child: Text('Image not available')),
              );
            },
          ),
          Positioned(
            bottom: 0,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  widget.placeName,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCards() {
    return Column(
      children: recommendedPlaces.map((place) {
        return _buildCard(place['name']!, place['image']!);
      }).toList(),
    );
  }

  Widget _buildCard(String label, String image) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Image.network(
              image,
              width: double.infinity,
              height: 150,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[300],
                  child: Center(child: Text('Image not available')),
                );
              },
            ),
            Positioned(
              bottom: 10,
              left: 10,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  backgroundColor: Colors.black26,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
