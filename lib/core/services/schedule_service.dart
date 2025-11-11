import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../config/app_config.dart';
import '../utils/operating_hours.dart';

final scheduleServiceProvider = Provider<ScheduleService>((ref) {
  final config = ref.watch(appConfigProvider);
  return ScheduleService(
    apiUrl: config.worldTimeApiUrl,
    rapidApiKey: config.rapidApiKey,
  );
});

class ScheduleService {
  ScheduleService({
    required this.apiUrl,
    this.rapidApiKey,
    http.Client? httpClient,
  }) : _client = httpClient ?? http.Client();

  final String apiUrl;
  final String? rapidApiKey;
  final http.Client _client;

  Future<DateTime> fetchBrasiliaTime() async {
    try {
      final response = await _client.get(Uri.parse(apiUrl));
      if (response.statusCode >= 400) {
        throw ScheduleException(
          'Falha ao consultar o horário (status ${response.statusCode}).',
        );
      }

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final dateTime = decoded['datetime'] as String?;
      if (dateTime == null) {
        throw ScheduleException('Resposta inválida da API de horário.');
      }

      return DateTime.parse(dateTime).toLocal();
    } on SocketException catch (error) {
      log('ScheduleService: worldtimeapi falhou: $error');
      return _fallbackOrLocal();
    } on ScheduleException catch (error) {
      log('ScheduleService: worldtimeapi respondeu erro: $error');
      return _fallbackOrLocal();
    } catch (error) {
      log('ScheduleService: erro inesperado no worldtimeapi: $error');
      return _fallbackOrLocal();
    }
  }

  Future<DateTime> _fallbackOrLocal() async {
    final key = rapidApiKey;
    if (key == null || key.isEmpty) {
      log('ScheduleService: sem RAPIDAPI_KEY, usando DateTime.now.');
      return DateTime.now();
    }

    try {
      return await _fallbackRapidApi(key);
    } catch (error) {
      log('ScheduleService: fallback RapidAPI falhou ($error). Usando DateTime.now.');
      return DateTime.now();
    }
  }

  Future<DateTime> _fallbackRapidApi(String apiKey) async {
    final uri = Uri.https(
      'world-time-by-api-ninjas.p.rapidapi.com',
      '/v1/worldtime',
      {'city': 'São Paulo', 'country': 'BR'},
    );

    final response = await _client.get(
      uri,
      headers: {
        'X-RapidAPI-Key': apiKey,
        'X-RapidAPI-Host': 'world-time-by-api-ninjas.p.rapidapi.com',
      },
    );
    if (response.statusCode >= 400) {
      throw ScheduleException(
        'Fallback RapidAPI falhou (status ${response.statusCode}).',
      );
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final dateString = decoded['datetime'] as String? ?? decoded['time'] as String?;
    if (dateString == null) {
      throw ScheduleException('Resposta inválida da RapidAPI.');
    }

    return DateTime.parse(dateString).toLocal();
  }

  Future<void> ensureOperatingHours() async {
    final now = await fetchBrasiliaTime();
    if (!OperatingHours.isOpen(now)) {
      final remaining = OperatingHours.timeUntilOpen(now);
      throw OutsideOperatingHoursException(remaining);
    }
  }
}

class ScheduleException implements Exception {
  ScheduleException(this.message);
  final String message;

  @override
  String toString() => 'ScheduleException: $message';
}

class OutsideOperatingHoursException implements Exception {
  OutsideOperatingHoursException(this.remaining);
  final Duration remaining;

  @override
  String toString() => 'Fora do horário de funcionamento. Próximo período começa em ${remaining.inMinutes} minutos.';
}
