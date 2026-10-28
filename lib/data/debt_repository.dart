import '../main.dart';

/// Storage abstraction to keep debt features independent from SQLite or a backend.
abstract interface class DebtRepository {
  Future<List<Debt>> getDebts();
  Future<void> saveDebt(Debt debt);
  Future<void> deleteDebt(String id);
}
