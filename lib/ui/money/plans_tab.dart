import 'package:flutter/material.dart';

import '../money_plan_screen.dart';
import 'recurring.dart';

/// Регулярные платежи и планы по долгам и копилкам.
class MoneyPlansTab extends StatelessWidget {
  const MoneyPlansTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const MoneyPlanView(leading: [RecurringSection()], bottomPadding: 110);
  }
}
