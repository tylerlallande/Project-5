import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'server_config.dart';
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
  Future<TailgateEntry> complete(TailgateEntry entry) =>
      throw UnsupportedError('Completing tailgates is not supported.');
  Future<TailgateEntry> archive(TailgateEntry entry) =>
      throw UnsupportedError('Archiving tailgates is not supported.');
  Future<bool> delete(TailgateEntry entry) =>
      throw UnsupportedError('Deleting tailgates is not supported.');
  Future<void> checkIn(TailgateEntry entry, bool checkedIn) =>
      throw UnsupportedError('Check-in is not supported.');
  Future<void> report(
    TailgateEntry entry,
    String reason, {
    bool block = false,
  }) => throw UnsupportedError('Reporting is not supported.');
  Future<TailgateEntry> approve(TailgateEntry entry, String memberId) =>
      throw UnsupportedError('Approving guests is not supported.');
  Future<TailgateEntry> reject(TailgateEntry entry, String memberId) =>
      throw UnsupportedError('Rejecting guests is not supported.');
  Future<List<TailgatePhoto>> listPhotos(TailgateEntry entry) =>
      throw UnsupportedError('Photo recaps are not supported.');
  Future<List<TailgatePhoto>> addPhoto(
    TailgateEntry entry,
    String url,
    String caption,
  ) => throw UnsupportedError('Photo recaps are not supported.');
}

class TailgatePhoto {
  const TailgatePhoto({
    required this.id,
    required this.url,
    required this.caption,
    required this.createdAt,
  });

  final String id;
  final String url;
  final String caption;
  final DateTime createdAt;

  factory TailgatePhoto.fromJson(Map<String, dynamic> data) => TailgatePhoto(
    id: data['id'] as String,
    url: data['url'] as String,
    caption: data['caption'] as String? ?? '',
    createdAt: DateTime.parse(data['createdAt'] as String),
  );
}

class ServerTailgateRepository extends TailgateRepository {
  ServerTailgateRepository({String? baseUrl})
    : baseUrl = baseUrl ?? tailgateApiUrl();
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

  Future<dynamic> _request(
    String path, [
    Map<String, dynamic>? body,
    String method = 'POST',
  ]) async {
    try {
      await (_initializing ??= _initialize());
      final headers = {
        'Authorization': 'Bearer $_token',
        'Content-Type': 'application/json',
      };
      final uri = Uri.parse('$baseUrl$path');
      final response =
          await (method == 'DELETE'
                  ? http.delete(uri, headers: headers)
                  : body == null
                  ? http.get(uri, headers: headers)
                  : http.post(uri, headers: headers, body: jsonEncode(body)))
              .timeout(const Duration(seconds: 10));
      return _decode(response);
    } on TailgateApiException {
      rethrow;
    } catch (_) {
      if (_token == null) _initializing = null;
      throw TailgateApiException(
        'Cannot reach the tailgate server at $baseUrl. '
        'Start the server or set TAILGATE_API_URL to its reachable address.',
      );
    }
  }

  @override
  Future<List<TailgateEntry>> list() async {
    final preferences = await SharedPreferences.getInstance();
    final cacheKey = 'bayou.tailgates.cache.$baseUrl';
    try {
      final raw = await _request('/tailgates') as List;
      await preferences.setString(cacheKey, jsonEncode(raw));
      return raw
          .map((data) => TailgateEntry.fromJson(data as Map<String, dynamic>))
          .toList();
    } on TailgateApiException {
      final cached = preferences.getString(cacheKey);
      if (cached == null) rethrow;
      return (jsonDecode(cached) as List)
          .map((data) => TailgateEntry.fromJson(data as Map<String, dynamic>))
          .toList();
    }
  }

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

  @override
  Future<TailgateEntry> complete(TailgateEntry entry) async =>
      TailgateEntry.fromJson(
        await _request('/tailgates/${entry.id}/complete', {})
            as Map<String, dynamic>,
      );

  @override
  Future<TailgateEntry> archive(TailgateEntry entry) async =>
      TailgateEntry.fromJson(
        await _request('/tailgates/${entry.id}/archive', {})
            as Map<String, dynamic>,
      );

  @override
  Future<bool> delete(TailgateEntry entry) async =>
      (await _request('/tailgates/${entry.id}', null, 'DELETE')
              as Map<String, dynamic>)['deleted']
          as bool;

  @override
  Future<void> checkIn(TailgateEntry entry, bool checkedIn) async {
    await _request('/tailgates/${entry.id}/check-in', {'checkedIn': checkedIn});
  }

  @override
  Future<void> report(
    TailgateEntry entry,
    String reason, {
    bool block = false,
  }) async {
    await _request('/tailgates/${entry.id}/report', {
      'reason': reason,
      'block': block,
    });
  }

  @override
  Future<TailgateEntry> approve(TailgateEntry entry, String memberId) async =>
      TailgateEntry.fromJson(
        await _request('/tailgates/${entry.id}/approve/$memberId', {})
            as Map<String, dynamic>,
      );

  @override
  Future<TailgateEntry> reject(TailgateEntry entry, String memberId) async =>
      TailgateEntry.fromJson(
        await _request('/tailgates/${entry.id}/reject/$memberId', {})
            as Map<String, dynamic>,
      );

  @override
  Future<List<TailgatePhoto>> listPhotos(TailgateEntry entry) async =>
      (await _request('/tailgates/${entry.id}/photos') as List)
          .map((item) => TailgatePhoto.fromJson(item as Map<String, dynamic>))
          .toList();

  @override
  Future<List<TailgatePhoto>> addPhoto(
    TailgateEntry entry,
    String url,
    String caption,
  ) async =>
      (await _request('/tailgates/${entry.id}/photos', {
            'url': url,
            'caption': caption,
          }) as List)
          .map((item) => TailgatePhoto.fromJson(item as Map<String, dynamic>))
          .toList();
}
