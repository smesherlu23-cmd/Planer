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
      padding: const EdgeInsets.fromLTRB(20, 22, 12, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          ),
          if (trailing != null)
            Theme(
              data: Theme.of(context).copyWith(visualDensity: VisualDensity.compact),
              child: trailing!,
            ),
        ],
      ),
    );
  }
}

/// Большой заголовок вкладки: мелкая подпись сверху, крупный заголовок, действия справа.
class PageHeader extends StatelessWidget {
  const PageHeader({super.key, required this.title, this.overline, this.actions = const []});
  final String title;
  final String? overline;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(20, MediaQuery.paddingOf(context).top + 20, 8, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (overline != null)
                  Text(
                    overline!.toUpperCase(),
                    style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant, letterSpacing: 0.8),
                  ),
                if (overline != null) const SizedBox(height: 4),
                Text(title, style: theme.textTheme.headlineMedium),
              ],
            ),
          ),
          ...actions,
        ],
      ),
    );
  }
}

class EmptyHint extends StatelessWidget {
  const EmptyHint(this.text, {super.key, this.action, this.icon});
  final String text;
  final Widget? action;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 40, color: scheme.onSurfaceVariant.withValues(alpha: 0.6)), const SizedBox(height: 12)],
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(color: scheme.onSurfaceVariant, height: 1.4),
          ),
          if (action != null) ...[const SizedBox(height: 16), action!],
        ],
      ),
    );
  }
}

/// Эмодзи в скруглённом квадрате с лёгкой подложкой цвета раздела.
class EmojiAvatar extends StatelessWidget {
  const EmojiAvatar(this.emoji, {super.key, this.size = 44, this.color});
  final String emoji;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tint = color ?? scheme.primary;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Color.alphaBlend(tint.withValues(alpha: 0.14), scheme.surfaceContainer),
        borderRadius: BorderRadius.circular(size * 0.32),
      ),
      child: Text(emoji, style: TextStyle(fontSize: size * 0.48, height: 1.15)),
    );
  }
}

/// Значок-иконка в цветном скруглённом квадрате, как в настройках телефона.
class IconBadge extends StatelessWidget {
  const IconBadge(this.icon, {super.key, required this.color, this.size = 40, this.soft = false});
  final IconData icon;
  final Color color;
  final double size;

  /// Бледная подложка и цветная иконка вместо яркой заливки.
  final bool soft;

  @override
  Widget build(BuildContext context) {
    final bg = soft ? Color.alphaBlend(color.withValues(alpha: 0.14), Theme.of(context).colorScheme.surfaceContainer) : color;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(size * 0.3)),
      child: Icon(icon, color: soft ? color : Colors.white, size: size * 0.55),
    );
  }
}

/// Номер в скруглённом квадрате: порядок упражнений и шагов.
class NumberBadge extends StatelessWidget {
  const NumberBadge(this.number, {super.key, required this.color, this.size = 36});
  final int number;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Color.alphaBlend(color.withValues(alpha: 0.14), Theme.of(context).colorScheme.surfaceContainer),
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: Text(
        '$number',
        style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: size * 0.42),
      ),
    );
  }
}

/// Толстая скруглённая полоса прогресса.
class ProgressLine extends StatelessWidget {
  const ProgressLine({super.key, required this.value, this.color, this.height = 10});
  final double value;
  final Color? color;
  final double height;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: value.clamp(0, 1).toDouble()),
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
        builder: (context, v, _) => LinearProgressIndicator(
          value: v,
          minHeight: height,
          color: color ?? scheme.primary,
          backgroundColor: (color ?? scheme.primary).withValues(alpha: 0.15),
        ),
      ),
    );
  }
}

/// Кольцо прогресса с текстом в центре.
class ProgressRing extends StatelessWidget {
  const ProgressRing({super.key, required this.value, this.size = 88, this.stroke = 10, this.color, this.trackColor, this.child});
  final double value;
  final double size;
  final double stroke;
  final Color? color;
  final Color? trackColor;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.primary;
    return SizedBox(
      width: size,
      height: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: value.clamp(0, 1).toDouble()),
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeOutCubic,
        builder: (context, v, child) => CustomPaint(
          painter: _RingPainter(value: v, color: c, track: trackColor ?? c.withValues(alpha: 0.18), stroke: stroke),
          child: Center(child: child),
        ),
        child: child,
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.value, required this.color, required this.track, required this.stroke});
  final double value;
  final Color color;
  final Color track;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final r = rect.deflate(stroke / 2);
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(r, 0, 6.2832, false, p..color = track);
    if (value > 0) canvas.drawArc(r, -1.5708, 6.2832 * value, false, p..color = color);
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.value != value || old.color != color || old.track != track;
}

/// Круглая отметка «сделано» с анимацией.
class CheckDot extends StatelessWidget {
  const CheckDot({super.key, required this.checked, this.color, this.size = 30, this.half = false});
  final bool checked;
  final Color? color;
  final double size;

  /// Засчитан минимум: заливка бледнее.
  final bool half;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final c = color ?? scheme.primary;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: checked ? (half ? c.withValues(alpha: 0.55) : c) : Colors.transparent,
        border: Border.all(color: checked ? Colors.transparent : scheme.outline, width: 2),
      ),
      child: AnimatedScale(
        scale: checked ? 1 : 0,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutBack,
        child: Icon(Icons.check_rounded, size: size * 0.66, color: Colors.white),
      ),
    );
  }
}

/// Маленькая плашка с текстом: «🔥 9», «минимум».
class Pill extends StatelessWidget {
  const Pill(this.text, {super.key, this.color});
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final c = color ?? scheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: c.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(color: c, fontWeight: FontWeight.w600),
      ),
    );
  }
}

/// Карточка со списком строк, разделённых тонкой линией.
class GroupCard extends StatelessWidget {
  const GroupCard({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[if (i > 0) const Divider(indent: 72, height: 1), children[i]],
        ],
      ),
    );
  }
}

/// Крупная цветная карточка для главной цифры экрана.
class HeroCard extends StatelessWidget {
  const HeroCard({super.key, required this.colors, required this.child, this.onTap});
  final List<Color> colors;
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Material(
        borderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.antiAlias,
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
          ),
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: DefaultTextStyle.merge(
                style: const TextStyle(color: Colors.white),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Цифра с подписью на полупрозрачной плашке внутри [HeroCard].
class HeroStat extends StatelessWidget {
  const HeroStat({super.key, required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

/// Круглая полупрозрачная кнопка-стрелка внутри [HeroCard].
class HeroArrow extends StatelessWidget {
  const HeroArrow(this.icon, {super.key, required this.onTap});
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, color: onTap == null ? Colors.white38 : Colors.white),
      style: IconButton.styleFrom(backgroundColor: Colors.white.withValues(alpha: 0.16), disabledBackgroundColor: Colors.white10),
      visualDensity: VisualDensity.compact,
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
