import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

import '../models/service.dart';
import '../widgets/gradient_header.dart';

/// Exibe estatísticas consolidadas dos serviços realizados e valores associados.
/// Utiliza gráficos de barra para mostrar a quantidade de serviços realizados
/// por mês e cartões informativos para totais.
class DashboardPage extends StatelessWidget {
  final List<Service> services;
  const DashboardPage({Key? key, required this.services}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = services.length;
    final realized = services.where((s) => s.realized).length;
    final notRealized = total - realized;
    final paid = services.where((s) => s.paymentDate != null).length;
    final notPaid = total - paid;
    final totalValue = services.fold<double>(0.0, (sum, s) => sum + s.value);
    final receivedValue = services
        .where((s) => s.paymentDate != null)
        .fold<double>(0.0, (sum, s) => sum + s.value);
    final toReceiveValue = totalValue - receivedValue;

    final dataByMonth = _groupByMonth(services);

    return Column(
      children: [
        const GradientHeader(title: 'Dashboard'),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _InfoCard(
                      title: 'Total de Serviços',
                      value: total.toString(),
                      color: theme.colorScheme.primary,
                    ),
                    _InfoCard(
                      title: 'Realizados',
                      value: realized.toString(),
                      color: theme.colorScheme.secondary,
                    ),
                    _InfoCard(
                      title: 'Não Realizados',
                      value: notRealized.toString(),
                      color: theme.colorScheme.error,
                    ),
                    _InfoCard(
                      title: 'Pagos',
                      value: paid.toString(),
                      color: theme.colorScheme.tertiary ?? theme.colorScheme.primary,
                    ),
                    _InfoCard(
                      title: 'Pendentes',
                      value: notPaid.toString(),
                      color: theme.colorScheme.outlineVariant ?? theme.colorScheme.secondary,
                    ),
                    _InfoCard(
                      title: 'Valor Recebido',
                      value: 'R\$ ${receivedValue.toStringAsFixed(2)}',
                      color: theme.colorScheme.primaryContainer,
                    ),
                    _InfoCard(
                      title: 'Valor a Receber',
                      value: 'R\$ ${toReceiveValue.toStringAsFixed(2)}',
                      color: theme.colorScheme.secondaryContainer,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'Serviços Realizados por Mês',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                AspectRatio(
                  aspectRatio: 1.3,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      barTouchData: BarTouchData(enabled: true),
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 28,
                            getTitlesWidget: (double value, TitleMeta meta) {
                              final month = value.toInt();
                              return Text(
                                DateFormat('MMM', 'pt_BR').format(
                                  DateTime(2025, month),
                                ),
                                style: theme.textTheme.bodySmall,
                              );
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 32,
                            interval: 2,
                          ),
                        ),
                        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: dataByMonth
                          .map((month, count) => MapEntry(
                                month,
                                BarChartGroupData(
                                  x: month,
                                  barRods: [
                                    BarChartRodData(
                                      toY: count.toDouble(),
                                      color: theme.colorScheme.primary,
                                      width: 16,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ],
                                ),
                              ))
                          .values
                          .toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Agrupa o número de serviços realizados por mês (1–12).
  Map<int, int> _groupByMonth(List<Service> services) {
    final Map<int, int> counts = {for (var i = 1; i <= 12; i++) i: 0};
    for (final service in services) {
      final month = service.date.month;
      if (service.realized) {
        counts[month] = (counts[month] ?? 0) + 1;
      }
    }
    return counts;
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  const _InfoCard({
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: MediaQuery.of(context).size.width / 2 - 24,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}