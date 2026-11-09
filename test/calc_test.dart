import 'package:flutter_test/flutter_test.dart';
import 'package:planer/data/dates.dart';
import 'package:planer/logic/calc.dart';

void main() {
  test('ключи дат', () {
    expect(addDays(20261231, 1), 20270101);
    expect(addDays(20270301, -1), 20270228);
    expect(daysBetween(20261108, 20261208), 30);
    expect(weekStart(20261108), 20261102); // 8 ноября 2026 воскресенье
    expect(maskHasDay(weekdaysOnly, 20261108), isFalse);
    expect(maskLabel(maskFromWeekdays([1, 3, 5])), 'Пн, Ср, Пт');
  });

  test('серия не рвётся, пока сегодня не закончилось', () {
    final done = {20261105, 20261106, 20261107};
    expect(currentStreak(daysMask: everyDay, doneDays: done, today: 20261108), 3);
    expect(currentStreak(daysMask: everyDay, doneDays: {...done, 20261108}, today: 20261108), 4);
    expect(currentStreak(daysMask: everyDay, doneDays: {20261105, 20261106}, today: 20261108), 0);
  });

  test('серия пропускает дни вне расписания', () {
    // Пн 2, Ср 4, Пт 6 ноября; сегодня вс 8.
    final mask = maskFromWeekdays([1, 3, 5]);
    expect(currentStreak(daysMask: mask, doneDays: {20261102, 20261104, 20261106}, today: 20261108), 3);
  });

  test('выполнение за период', () {
    final r = habitCompletion(daysMask: weekdaysOnly, doneDays: {20261102, 20261103}, from: 20261102, to: 20261108);
    expect(r.planned, 5);
    expect(r.done, 2);
  });

  test('прогноз цели', () {
    final g = goalProgress(start: 67, target: 73, current: 68, startDay: 20261101, today: 20261201);
    expect(g.reached, isFalse);
    expect(g.fraction, closeTo(1 / 6, 1e-9));
    // 1 кг за 30 дней, осталось 5 кг -> 150 дней.
    expect(g.forecastDay, addDays(20261201, 150));

    final debt = goalProgress(start: 120000, target: 0, current: 60000, startDay: 20261101, today: 20261201);
    expect(debt.fraction, 0.5);
    expect(debt.forecastDay, addDays(20261201, 30));

    final wrongWay = goalProgress(start: 67, target: 73, current: 66, startDay: 20261101, today: 20261201);
    expect(wrongWay.forecastDay, isNull);
  });

  test('выплата долга', () {
    expect(monthsToPayOff(balance: 120000, monthlyPayment: 12000), 10);
    expect(monthsToPayOff(balance: 120000, monthlyPayment: 1000, annualRatePercent: 20), isNull);
    final withRate = monthsToPayOff(balance: 120000, monthlyPayment: 12000, annualRatePercent: 20)!;
    expect(withRate, 12); // 11 полных платежей и маленький последний
    expect(monthsToSave(balance: 0, target: 300000, monthly: 43000), 7);
    expect(addMonths(20260131, 1), 20260228);
  });

  test('подсказка прогрессии', () {
    expect(readyToProgress(plannedSets: 3, repsMax: 12, lastReps: [12, 12, 12]), isTrue);
    expect(readyToProgress(plannedSets: 3, repsMax: 12, lastReps: [12, 11, 12]), isFalse);
    expect(readyToProgress(plannedSets: 3, repsMax: 12, lastReps: [12, 12]), isFalse);
  });

  test('форматирование', () {
    expect(formatMoney(120000), '120\u00a0000\u00a0₽');
    expect(formatMoney(-1500), '−1\u00a0500\u00a0₽');
    expect(formatNumber(67.0), '67');
    expect(formatNumber(67.25), '67,3');
    expect(parseNumber(' 67,5 '), 67.5);
    expect(formatDuration(105), '1 ч 45 мин');
  });
}
