/// Future integration point only. Debt actions must not change savings balances.
abstract interface class SavingsBridge {
  Future<void> recordDebtPayment({required String debtId, required int amount});
}

/// Safe default while savings integration is out of scope.
class NoopSavingsBridge implements SavingsBridge {
  const NoopSavingsBridge();

  @override
  Future<void> recordDebtPayment({
    required String debtId,
    required int amount,
  }) async {}
}
