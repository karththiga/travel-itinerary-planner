import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/attraction.dart';

class AttractionService {
  static const String baseUrl = 'http://10.0.2.2:3000';

  static Future<List<Attraction>> getAttractions() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/attractions'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);

      return data
          .map((json) => Attraction.fromJson(json))
          .toList();
    } else {
      throw Exception('Failed to load attractions');
    }
  }
}