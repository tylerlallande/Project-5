import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'tailgate_draft.dart';

class TailgateApiException implements Exception {
  TailgateApiException(this.message, {this.code = 'error'});
  final String message;
  final String code;
  @override
  String toString() => message;
}

abstract class TailgateRepository {
  static TailgateRepository Function() create = () =>
      ServerTailgateRepository();
  Future<List<TailgateEntry>> list();
  Future<TailgateEntry> createTailgate(TailgateDraft draft);
  Future<TailgateEntry> lookup(String code);
  Future<TailgateEntry> join(TailgateEntry entry);
  Future<bool> leave(TailgateEntry entry, {bool confirmDelete = false});
}

class ServerTailgateRepository implements TailgateRepository {
  ServerTailgateRepository({
    this.baseUrl = const String.fromEnvironment(
      'TAILGATE_API_URL',
      defaultValue: 'http://127.0.0.1:8080',
    ),
  });
  final String baseUrl;
  String? _token;
  Future<void>? _initializing;

  Future<void> _initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'bayou.device-session.$baseUrl';
    _token = prefs.getString(key);
    if (_token == null) {
      final response = await http
          .post(
            Uri.parse('$baseUrl/sessions'),
            headers: {'Content-Type': 'application/json'},
            body: '{}',
          )
          .timeout(const Duration(seconds: 10));
      final data = _decode(response) as Map<String, dynamic>;
      _token = data['token'] as String;
      if (!await prefs.setString(key, _token!)) {
        throw TailgateApiException(
          'Unable to save this device session. Enable browser storage and retry.',
        );
      }
    }
  }

  dynamic _decode(http.Response response) {
    final data = jsonDecode(response.body);
    if (response.statusCode >= 400) {
      throw TailgateApiException(
        data['message'] as String? ?? 'Request failed',
        code: data['code'] as String? ?? 'error',
      );
    }
    return data;
  }

  Future<dynamic> _request(String path, [Map<String, dynamic>? body]) async {
    try {
      await (_initializing ??= _initialize());
      final headers = {
        'Authorization': 'Bearer $_token',
        'Content-Type': 'application/json',
      };
      final response =
          await (body == null
                  ? http.get(Uri.parse('$baseUrl$path'), headers: headers)
                  : http.post(
                      Uri.parse('$baseUrl$path'),
                      headers: headers,
                      body: jsonEncode(body),
                    ))
              .timeout(const Duration(seconds: 10));
      return _decode(response);
    } on TailgateApiException {
      rethrow;
    } catch (_) {
      if (_token == null) _initializing = null;
      throw TailgateApiException(
        'Cannot reach the tailgate server. Check the connection and retry.',
      );
    }
  }

  @override
  Future<List<TailgateEntry>> list() async =>
      (await _request('/tailgates') as List)
          .map((data) => TailgateEntry.fromJson(data as Map<String, dynamic>))
          .toList();
  @override
  Future<TailgateEntry> createTailgate(TailgateDraft draft) async =>
      TailgateEntry.fromJson(
        await _request('/tailgates', {'draft': draft.toJson()})
            as Map<String, dynamic>,
      );
  @override
  Future<TailgateEntry> lookup(String code) async => TailgateEntry.fromJson(
    await _request('/tailgates/lookup', {'code': code}) as Map<String, dynamic>,
  );
  @override
  Future<TailgateEntry> join(TailgateEntry entry) async =>
      TailgateEntry.fromJson(
        await _request('/tailgates/${entry.id}/join', {'code': entry.code})
            as Map<String, dynamic>,
      );
  @override
  Future<bool> leave(TailgateEntry entry, {bool confirmDelete = false}) async =>
      (await _request('/tailgates/${entry.id}/leave', {
            'confirmDelete': confirmDelete,
          }) as Map<String, dynamic>)['deleted']
          as bool;
}
