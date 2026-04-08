/*
* A crowdsourced platform for real-time fuel price monitoring in Norway
* Copyright (C) 2026  Tsotne Karchava & Contributors
*
* This program is free software: you can redistribute it and/or modify
* it under the terms of the GNU General Public License as published by
* the Free Software Foundation, either version 3 of the License, or
* (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
* GNU General Public License for more details.
*
* You should have received a copy of the GNU General Public License
* along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';

/// Thrown when the backend returns a non-2xx response.
class ApiException implements Exception {
  const ApiException(this.statusCode, this.message);

  final int statusCode;
  final String message;

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class BackendApiClient {
  Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body,
  ) async {
    final response = await http.post(
      _uri(path),
      headers: await _authHeaders(),
      body: jsonEncode(body),
    );
    return _decode(response);
  }

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? queryParams,
  }) async {
    final response = await http.get(
      _uri(path, queryParams: queryParams),
      headers: await _authHeaders(),
    );
    return _decode(response);
  }

  Uri _uri(String path, {Map<String, String>? queryParams}) {
    final base = BackendConfig.baseUrl;
    final uri = Uri.parse('$base$path');
    if (queryParams != null && queryParams.isNotEmpty) {
      return uri.replace(queryParameters: queryParams);
    }
    return uri;
  }

  Future<Map<String, String>> _authHeaders() async {
    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (token == null) throw const ApiException(401, 'User not signed in');
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Map<String, dynamic> _decode(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw ApiException(
      response.statusCode,
      response.reasonPhrase ?? 'Unknown error',
    );
  }
}
