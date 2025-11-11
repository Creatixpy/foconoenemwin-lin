import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/analytics_service.dart';
import '../../../core/services/stripe_service.dart';

final doacaoRepositoryProvider = Provider<DoacaoRepository>((ref) {
  final stripe = ref.watch(stripeServiceProvider);
  final analytics = ref.watch(analyticsServiceProvider);
  return DoacaoRepository(stripeService: stripe, analyticsService: analytics);
});

class DoacaoRepository {
  DoacaoRepository({
    required this.stripeService,
    required this.analyticsService,
  });

  final StripeService stripeService;
  final AnalyticsService analyticsService;

  Future<Uri> criarCheckout({
    required int valorEmCentavos,
    String? mensagem,
  }) async {
    final checkoutUrl = await stripeService.createCheckout(
      amountInCents: valorEmCentavos,
      message: mensagem,
    );

    await analyticsService.track(
      'donation_checkout_created',
      metadata: {
        'valor_centavos': valorEmCentavos,
        if (mensagem != null) 'mensagem': mensagem,
      },
    );

    return checkoutUrl;
  }
}
