import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../config/app_config.dart';

final stripeServiceProvider = Provider<StripeService>((ref) {
  final config = ref.watch(appConfigProvider);
  return StripeService(
    secretKey: config.stripeSecretKey,
    siteUrl: config.apiBaseUrl,
  );
});

class StripeService {
  StripeService({
    required this.secretKey,
    required this.siteUrl,
    http.Client? httpClient,
  }) : _client = httpClient ?? http.Client();

  final String? secretKey;
  final String siteUrl;
  final http.Client _client;

  Future<Uri> createCheckout({
    required int amountInCents,
    String? message,
  }) async {
    final key = secretKey;
    if (key == null || key.isEmpty) {
      throw StateError('Stripe não configurado. Defina STRIPE_SECRET_KEY.');
    }
    if (amountInCents < 500) {
      throw StateError('O valor mínimo de doação é R\$5,00.');
    }

    final successUrl = '$siteUrl/doacao/sucesso?session_id={CHECKOUT_SESSION_ID}';
    final cancelUrl = '$siteUrl/doacao/cancelado';

    final body = {
      'mode': 'payment',
      'success_url': successUrl,
      'cancel_url': cancelUrl,
      'line_items[0][price_data][currency]': 'brl',
      'line_items[0][price_data][product_data][name]': 'Doação Foco no ENEM',
      'line_items[0][price_data][unit_amount]': amountInCents.toString(),
      'line_items[0][quantity]': '1',
      if (message != null && message.isNotEmpty)
        'metadata[mensagem]': message,
    };

    final response = await _client.post(
      Uri.parse('https://api.stripe.com/v1/checkout/sessions'),
      headers: {
        'Authorization': 'Bearer $key',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: body.entries
          .map(
            (entry) =>
                '${Uri.encodeQueryComponent(entry.key)}=${Uri.encodeQueryComponent(entry.value)}',
          )
          .join('&'),
    );

    if (response.statusCode >= 400) {
      throw StateError(
        'Stripe retornou erro ${response.statusCode}: ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final url = decoded['url'] as String?;
    if (url == null) {
      throw StateError('Stripe não retornou a URL do checkout.');
    }
    return Uri.parse(url);
  }
}
