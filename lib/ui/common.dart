import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/database.dart';
import '../data/dates.dart';
import '../logic/calc.dart';
import '../services/notifications.dart';

// ---------------------------------------------------------------------------
// Доступ к базе и сервисам из любого экрана
// ---------------------------------------------------------------------------

class AppScope extends InheritedWidget {
  const AppScope({super.key, required this.db, required this.notifications, required super.child});

  final AppDatabase db;
  final NotificationService notifications;

  // База и сервисы не меняются за время работы, поэтому подписка на изменения не нужна,
  // и так можно обращаться к ним даже из initState.
  static AppScope of(BuildContext context) => context.getInheritedWidgetOfExactType<AppScope>()!;

  @override
  bool updateShouldNotify(AppScope oldWidget) => db != oldWidget.db;
}

extension ScopeX on BuildContext {
  AppDatabase get db => AppScope.of(this).db;
  NotificationService get notifications => AppScope.of(this).notifications;
}

// ---------------------------------------------------------------------------
// Подписка на данные
// ---------------------------------------------------------------------------

/// Объединяет несколько потоков: выдаёт список последних значений,
/// когда каждый поток прислал хотя бы одно.
Stream<List<Object?>> combineStreams(List<Stream<Object?>> streams) {
  late StreamController<List<Object?>> controller;
  final subs = <StreamSubscription<Object?>>[];
  final values = List<Object?>.filled(streams.length, null);
  final has = List<bool>.filled(streams.length, false);
  controller = StreamController<List<Object?>>(
    onListen: () {
      for (var i = 0; i < streams.length; i++) {
        subs.add(
          streams[i].listen((v) {
            values[i] = v;
            has[i] = true;
            if (has.every((h) => h)) controller.add(List.of(values));
          }, onError: controller.addError),
        );
      }
    },
    onCancel: () async {
      for (final s in subs) {
        await s.cancel();
      }
    },
  );
  return controller.stream;
}

/// Подписывается на потоки один раз и пересоздаёт их, только когда меняются [deps].
class Watch extends StatefulWidget {
  const Watch({super.key, required this.streams, required this.builder, this.deps = const []});

  final List<Stream<Object?>> Function() streams;
  final Widget Function(BuildContext context, List<Object?> values) builder;
  final List<Object?> deps;

  @override
  State<Watch> createState() => _WatchState();
}

class _WatchState extends State<Watch> {
  late Stream<List<Object?>> _stream;

  @override
  void initState() {
    super.initState();
    _stream = combineStreams(widget.streams());
  }

  @override
  void didUpdateWidget(Watch old) {
    super.didUpdateWidget(old);
    if (!_sameDeps(old.deps, widget.deps)) _stream = combineStreams(widget.streams());
  }

  bool _sameDeps(List<Object?> a, List<Object?> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Object?>>(
      stream: _stream,
      builder: (context, snap) {
        if (snap.hasError) return Center(child: Text('Ошибка: ${snap.error}'));
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        return widget.builder(context, snap.data!);
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Мелкие элементы интерфейса
// ---------------------------------------------------------------------------

void showSnack(BuildContext context, String text) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));
}

Future<bool> confirm(BuildContext context, String title, {String? text, String ok = 'Да', bool danger = false}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: text == null ? null : Text(text),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Отмена')),
        FilledButton(
          style: danger ? FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error) : null,
          onPressed: () => Navigator.pop(context, true),
          child: Text(ok),
        ),
      ],
    ),
  );
  return result ?? false;
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.trailing});
  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 8, 6),
      child: Row(
        children: [
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Theme.of(context).colorScheme.primary)),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

class EmptyHint extends StatelessWidget {
  const EmptyHint(this.text, {super.key, this.action});
  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          if (action != null) ...[const SizedBox(height: 12), action!],
        ],
      ),
    );
  }
}

/// Значок-эмодзи в кружке.
class EmojiAvatar extends StatelessWidget {
  const EmojiAvatar(this.emoji, {super.key, this.size = 40});
  final String emoji;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest, shape: BoxShape.circle),
      child: Text(emoji, style: TextStyle(fontSize: size * 0.5)),
    );
  }
}

/// Прогресс-полоса с подписью.
class ProgressLine extends StatelessWidget {
  const ProgressLine({super.key, required this.value, this.color});
  final double value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(value: value.clamp(0, 1), minHeight: 8, color: color),
    );
  }
}

// ---------------------------------------------------------------------------
// Поля форм
// ---------------------------------------------------------------------------

/// Выбор дней недели.
class DaysPicker extends StatelessWidget {
  const DaysPicker({super.key, required this.mask, required this.onChanged});
  final int mask;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (var w = 1; w <= 7; w++)
          FilterChip(
            label: Text(weekdayShort[w - 1]),
            selected: maskHasWeekday(mask, w),
            showCheckmark: false,
            onSelected: (on) => onChanged(on ? mask | (1 << (w - 1)) : mask & ~(1 << (w - 1))),
          ),
        ActionChip(label: const Text('Все'), onPressed: () => onChanged(everyDay)),
        ActionChip(label: const Text('Будни'), onPressed: () => onChanged(weekdaysOnly)),
      ],
    );
  }
}

/// Строка «Напоминание: 18:45» с выбором времени и кнопкой сброса.
class ReminderTile extends StatelessWidget {
  const ReminderTile({super.key, required this.minutes, required this.onChanged, this.title = 'Напоминание'});
  final int? minutes;
  final ValueChanged<int?> onChanged;
  final String title;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.notifications_outlined),
      title: Text(title),
      subtitle: Text(minutes == null ? 'нет' : formatMinutes(minutes!)),
      trailing: minutes == null ? null : IconButton(icon: const Icon(Icons.close), onPressed: () => onChanged(null)),
      onTap: () async {
        final m = minutes ?? 20 * 60;
        final t = await showTimePicker(
          context: context,
          initialTime: TimeOfDay(hour: m ~/ 60, minute: m % 60),
        );
        if (t != null) onChanged(t.hour * 60 + t.minute);
      },
    );
  }
}

/// Строка с датой и выбором другой даты.
class DayTile extends StatelessWidget {
  const DayTile({super.key, required this.day, required this.onChanged, this.title = 'Дата', this.allowClear = false});
  final int? day;
  final ValueChanged<int?> onChanged;
  final String title;
  final bool allowClear;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.event_outlined),
      title: Text(title),
      subtitle: Text(day == null ? 'не задана' : dayLabel(day!)),
      trailing: allowClear && day != null ? IconButton(icon: const Icon(Icons.close), onPressed: () => onChanged(null)) : null,
      onTap: () async {
        final d = await showDatePicker(
          context: context,
          initialDate: dayFromKey(day ?? todayKey()),
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (d != null) onChanged(dayKey(d));
      },
    );
  }
}

/// «сегодня», «вчера» или дата.
String dayLabel(int day, {int? today}) {
  final t = today ?? todayKey();
  if (day == t) return 'сегодня';
  if (day == addDays(t, -1)) return 'вчера';
  if (day == addDays(t, 1)) return 'завтра';
  final sameYear = day ~/ 10000 == t ~/ 10000;
  return formatDay(day, withYear: !sameYear);
}

class NumberField extends StatelessWidget {
  const NumberField({
    super.key,
    required this.controller,
    required this.label,
    this.suffix,
    this.autofocus = false,
    this.allowNegative = false,
  });
  final TextEditingController controller;
  final String label;
  final String? suffix;
  final bool autofocus;
  final bool allowNegative;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      autofocus: autofocus,
      keyboardType: TextInputType.numberWithOptions(decimal: true, signed: allowNegative),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(allowNegative ? r'[-0-9.,\s]' : r'[0-9.,\s]'))],
      decoration: InputDecoration(labelText: label, suffixText: suffix),
    );
  }
}

/// Поле для одного эмодзи.
class EmojiField extends StatelessWidget {
  const EmojiField({super.key, required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      child: TextField(
        controller: controller,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 24),
        decoration: const InputDecoration(labelText: 'Значок'),
      ),
    );
  }
}

String? emptyToNull(String s) => s.trim().isEmpty ? null : s.trim();

String moneyOrDash(double? v) => v == null ? '—' : formatMoney(v);

/// Поднять клавиатуру и форму в нижнем листе.
Future<T?> showFormSheet<T>(BuildContext context, Widget Function(BuildContext) builder) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(20, 8, 20, 20), child: builder(context)),
    ),
  );
}
