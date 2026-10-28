import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:tally/main.dart';

void main() {
  group('Debt status', () {
    test('derives open, partly paid, overdue and paid', () {
      final today = DateUtils.dateOnly(DateTime.now());
      expect(
        Debt(name: 'A', direction: Direction.iOwe, total: 100).status,
        DebtStatus.open,
      );
      final partly = Debt(
        name: 'B',
        direction: Direction.iOwe,
        total: 100,
        payments: [Payment(10, today)],
      );
      expect(partly.status, DebtStatus.partlyPaid);
      final late = Debt(
        name: 'C',
        direction: Direction.iOwe,
        total: 100,
        dueDate: today.subtract(const Duration(days: 1)),
        payments: [Payment(10, today)],
      );
      expect(late.status, DebtStatus.overdue);
      final paid = Debt(
        name: 'D',
        direction: Direction.iOwe,
        total: 100,
        payments: [Payment(100, today)],
      );
      expect(paid.status, DebtStatus.paid);
    });
  });

  test('rejects invalid payments and accepts payment up to balance', () {
    final debt = Debt(name: 'A', direction: Direction.iOwe, total: 100);
    expect(() => debt.record(101), throwsArgumentError);
    expect(() => debt.record(0), throwsArgumentError);
    debt.record(100);
    expect(debt.balance, 0);
  });

  test('payoff estimate uses weekly contributions', () {
    const balance = 120000;
    const weekly = 20000;
    expect((balance / weekly * 7).ceil(), 42);
  });
}
