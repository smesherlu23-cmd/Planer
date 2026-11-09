/// Набор иконок для привычек, трекеров, копилок, категорий и блюд.
///
/// В базе хранится короткий ключ ('bedtime', 'code'), здесь он превращается
/// в иконку со своим цветом. Цвет задаёт иконка, поэтому списки выглядят
/// живыми без лишних настроек.
library;

import 'package:flutter/material.dart';

import '../data/icon_keys.dart';

class AppIcon {
  const AppIcon(this.key, this.icon, this.color);
  final String key;
  final IconData icon;
  final Color color;
}

// Палитра иконок.
const _red = Color(0xFFEF4444);
const _orange = Color(0xFFF97316);
const _amber = Color(0xFFF59E0B);
const _yellow = Color(0xFFEAB308);
const _lime = Color(0xFF84CC16);
const _green = Color(0xFF22C55E);
const _emerald = Color(0xFF10B981);
const _teal = Color(0xFF14B8A6);
const _cyan = Color(0xFF06B6D4);
const _sky = Color(0xFF0EA5E9);
const _blue = Color(0xFF3B82F6);
const _indigo = Color(0xFF6366F1);
const _violet = Color(0xFF8B5CF6);
const _purple = Color(0xFFA855F7);
const _pink = Color(0xFFEC4899);
const _rose = Color(0xFFF43F5E);
const _slate = Color(0xFF64748B);
const _brown = Color(0xFFB45309);

const iconGroups = <(String, List<AppIcon>)>[
  (
    'Здоровье и сон',
    [
      AppIcon('bedtime', Icons.bedtime_rounded, _indigo),
      AppIcon('sleep', Icons.hotel_rounded, _violet),
      AppIcon('alarm', Icons.alarm_rounded, _orange),
      AppIcon('water', Icons.water_drop_rounded, _sky),
      AppIcon('heart', Icons.favorite_rounded, _rose),
      AppIcon('health', Icons.health_and_safety_rounded, _green),
      AppIcon('meds', Icons.medication_rounded, _teal),
      AppIcon('yoga', Icons.self_improvement_rounded, _teal),
      AppIcon('posture', Icons.accessibility_new_rounded, _cyan),
      AppIcon('mood', Icons.mood_rounded, _amber),
      AppIcon('brain', Icons.psychology_rounded, _purple),
      AppIcon('sun', Icons.wb_sunny_rounded, _amber),
      AppIcon('walk', Icons.directions_walk_rounded, _green),
      AppIcon('no_phone', Icons.phonelink_erase_rounded, _slate),
      AppIcon('soap', Icons.soap_rounded, _cyan),
    ],
  ),
  (
    'Спорт и тело',
    [
      AppIcon('fitness', Icons.fitness_center_rounded, _orange),
      AppIcon('gymnastics', Icons.sports_gymnastics_rounded, _orange),
      AppIcon('run', Icons.directions_run_rounded, _red),
      AppIcon('bike', Icons.directions_bike_rounded, _lime),
      AppIcon('pool', Icons.pool_rounded, _sky),
      AppIcon('hiking', Icons.hiking_rounded, _emerald),
      AppIcon('martial', Icons.sports_martial_arts_rounded, _red),
      AppIcon('football', Icons.sports_soccer_rounded, _green),
      AppIcon('scale', Icons.monitor_weight_rounded, _blue),
      AppIcon('timer', Icons.timer_rounded, _blue),
      AppIcon('fire', Icons.local_fire_department_rounded, _orange),
    ],
  ),
  (
    'Учёба и работа',
    [
      AppIcon('code', Icons.code_rounded, _indigo),
      AppIcon('terminal', Icons.terminal_rounded, _slate),
      AppIcon('laptop', Icons.laptop_rounded, _slate),
      AppIcon('book', Icons.menu_book_rounded, _blue),
      AppIcon('school', Icons.school_rounded, _violet),
      AppIcon('language', Icons.translate_rounded, _cyan),
      AppIcon('work', Icons.work_rounded, _brown),
      AppIcon('idea', Icons.lightbulb_rounded, _yellow),
      AppIcon('note', Icons.edit_note_rounded, _pink),
      AppIcon('target', Icons.track_changes_rounded, _red),
      AppIcon('rocket', Icons.rocket_launch_rounded, _indigo),
    ],
  ),
  (
    'Игры и отдых',
    [
      AppIcon('game', Icons.sports_esports_rounded, _purple),
      AppIcon('music', Icons.music_note_rounded, _pink),
      AppIcon('headphones', Icons.headphones_rounded, _violet),
      AppIcon('movie', Icons.movie_rounded, _red),
      AppIcon('camera', Icons.photo_camera_rounded, _slate),
      AppIcon('palette', Icons.palette_rounded, _pink),
      AppIcon('park', Icons.park_rounded, _green),
      AppIcon('trophy', Icons.emoji_events_rounded, _amber),
      AppIcon('star', Icons.star_rounded, _yellow),
      AppIcon('people', Icons.group_rounded, _teal),
      AppIcon('family', Icons.family_restroom_rounded, _pink),
      AppIcon('chat', Icons.chat_rounded, _sky),
    ],
  ),
  (
    'Еда',
    [
      AppIcon('restaurant', Icons.restaurant_rounded, _orange),
      AppIcon('breakfast', Icons.breakfast_dining_rounded, _amber),
      AppIcon('lunch', Icons.lunch_dining_rounded, _orange),
      AppIcon('dinner', Icons.dinner_dining_rounded, _red),
      AppIcon('ramen', Icons.ramen_dining_rounded, _orange),
      AppIcon('bakery', Icons.bakery_dining_rounded, _brown),
      AppIcon('egg', Icons.egg_rounded, _yellow),
      AppIcon('fruit', Icons.eco_rounded, _lime),
      AppIcon('milk', Icons.local_drink_rounded, _sky),
      AppIcon('blender', Icons.blender_rounded, _violet),
      AppIcon('coffee', Icons.coffee_rounded, _brown),
      AppIcon('cake', Icons.cake_rounded, _pink),
      AppIcon('icecream', Icons.icecream_rounded, _pink),
      AppIcon('fastfood', Icons.fastfood_rounded, _red),
      AppIcon('pizza', Icons.local_pizza_rounded, _orange),
    ],
  ),
  (
    'Деньги и покупки',
    [
      AppIcon('savings', Icons.savings_rounded, _pink),
      AppIcon('wallet', Icons.account_balance_wallet_rounded, _amber),
      AppIcon('bank', Icons.account_balance_rounded, _slate),
      AppIcon('card', Icons.credit_card_rounded, _indigo),
      AppIcon('payments', Icons.payments_rounded, _emerald),
      AppIcon('salary', Icons.work_history_rounded, _green),
      AppIcon('cart', Icons.shopping_cart_rounded, _orange),
      AppIcon('bag', Icons.shopping_bag_rounded, _amber),
      AppIcon('gift', Icons.card_giftcard_rounded, _rose),
      AppIcon('receipt', Icons.receipt_long_rounded, _slate),
      AppIcon('clothes', Icons.checkroom_rounded, _violet),
      AppIcon('phone', Icons.smartphone_rounded, _blue),
      AppIcon('subscriptions', Icons.subscriptions_rounded, _red),
      AppIcon('house', Icons.home_rounded, _teal),
      AppIcon('bolt', Icons.bolt_rounded, _yellow),
      AppIcon('pets', Icons.pets_rounded, _brown),
      AppIcon('diamond', Icons.diamond_rounded, _cyan),
    ],
  ),
  (
    'Транспорт',
    [
      AppIcon('car', Icons.directions_car_rounded, _red),
      AppIcon('moto', Icons.two_wheeler_rounded, _orange),
      AppIcon('bus', Icons.directions_bus_rounded, _blue),
      AppIcon('train', Icons.train_rounded, _indigo),
      AppIcon('taxi', Icons.local_taxi_rounded, _yellow),
      AppIcon('fuel', Icons.local_gas_station_rounded, _orange),
      AppIcon('license', Icons.badge_rounded, _cyan),
      AppIcon('repair', Icons.build_rounded, _slate),
      AppIcon('flight', Icons.flight_rounded, _sky),
    ],
  ),
  (
    'Разное',
    [
      AppIcon('check', Icons.check_circle_rounded, _green),
      AppIcon('chart', Icons.show_chart_rounded, _blue),
      AppIcon('flag', Icons.flag_rounded, _purple),
      AppIcon('calendar', Icons.calendar_month_rounded, _indigo),
      AppIcon('clock', Icons.schedule_rounded, _slate),
      AppIcon('leaf', Icons.spa_rounded, _emerald),
      AppIcon('pin', Icons.push_pin_rounded, _red),
      AppIcon('bell', Icons.notifications_rounded, _amber),
    ],
  ),
];

final Map<String, AppIcon> _byKey = {
  for (final (_, list) in iconGroups)
    for (final i in list) i.key: i,
};

/// Иконка по значению из базы. Старые эмодзи переводятся, неизвестное значение даёт [fallback].
AppIcon appIcon(String? value, {String fallback = 'check'}) => _byKey[iconKeyFor(value)] ?? _byKey[fallback]!;

/// Иконка в скруглённом квадрате с бледной подложкой своего цвета.
class ItemIcon extends StatelessWidget {
  const ItemIcon(this.value, {super.key, this.size = 44, this.fallback = 'check'});
  final String? value;
  final double size;
  final String fallback;

  @override
  Widget build(BuildContext context) {
    final i = appIcon(value, fallback: fallback);
    return ColorIcon(i.icon, color: i.color, size: size);
  }
}

/// Цветная иконка на бледной подложке того же цвета.
class ColorIcon extends StatelessWidget {
  const ColorIcon(this.icon, {super.key, required this.color, this.size = 44});
  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Color.alphaBlend(color.withValues(alpha: dark ? 0.2 : 0.14), Theme.of(context).colorScheme.surfaceContainer),
        borderRadius: BorderRadius.circular(size * 0.32),
      ),
      child: Icon(icon, color: color, size: size * 0.54),
    );
  }
}

/// Поле выбора иконки: показывает текущую, по нажатию открывает список.
class IconField extends StatelessWidget {
  const IconField({super.key, required this.value, required this.onChanged, this.fallback = 'check'});
  final String? value;
  final ValueChanged<String> onChanged;
  final String fallback;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Выбрать иконку',
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () async {
          final picked = await pickIcon(context, current: iconKeyFor(value) ?? fallback);
          if (picked != null) onChanged(picked);
        },
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            ItemIcon(value, size: 56, fallback: fallback),
            Positioned(
              right: -4,
              bottom: -4,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, shape: BoxShape.circle),
                child: Icon(Icons.edit_rounded, size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Нижний лист со всеми иконками по группам. Возвращает ключ выбранной.
Future<String?> pickIcon(BuildContext context, {String? current}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      builder: (context, scroll) => ListView(
        controller: scroll,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
            child: Text('Иконка', style: Theme.of(context).textTheme.titleLarge),
          ),
          for (final (title, list) in iconGroups) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 14, 4, 8),
              child: Text(
                title,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            ),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final i in list)
                  InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => Navigator.pop(context, i.key),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(17),
                        border: Border.all(color: i.key == current ? i.color : Colors.transparent, width: 2.5),
                      ),
                      padding: const EdgeInsets.all(2),
                      child: ColorIcon(i.icon, color: i.color, size: 48),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    ),
  );
}
