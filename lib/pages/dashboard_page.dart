import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

import '../models/service.dart';
import '../widgets/gradient_header.dart';

/// Exibe estatísticas consolidadas dos serviços realizados e valores associados.
class DashboardPage extends StatelessWidget {
  final List<Service> services;
  const DashboardPage({Key? key, required this.services}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = services.length;
    final realized = services.where((s) => s.realized).length;
    final notRealized = total - realized;
    final received = services.where((s) => s.received).length;
    final notReceived = total - received;
    
    final totalValue = services.fold<double>(0.0, (sum, s) => sum + s.value);
    final receivedValue = services
        .where((s) => s.received)
        .fold<double>(0.0, (sum, s) => sum + s.value);
    final toReceiveValue = totalValue - receivedValue;

    final morningServices = services.where((s) => s.period == 'manhã').length;
    final afternoonServices = services.where((s) => s.period == 'tarde').length;
    final nightServices = services.where((s) => s.period == 'noite').length;

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
                Text('Estatísticas Gerais', style: theme.textTheme.titleLarge),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _InfoCard(
                      title: 'Total de Serviços',
                      value: total.toString(),
                      color: theme.colorScheme.primary,
                      icon: Icons.event,
                    ),
                    _InfoCard(
                      title: 'Realizados',
                      value: realized.toString(),
                      color: Colors.green.shade700,
                      icon: Icons.check_circle,
                    ),
                    _InfoCard(
                      title: 'Não Realizados',
                      value: notRealized.toString(),
                      color: Colors.orange.shade700,
                      icon: Icons.pending,
                    ),
                    _InfoCard(
                      title: 'Recebidos',
                      value: received.toString(),
                      color: Colors.blue.shade700,
                      icon: Icons.payments,
                    ),
                    _InfoCard(
                      title: 'Não Recebidos',
                      value: notReceived.toString(),
                      color: theme.colorScheme.error,
                      icon: Icons.hourglass_empty,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text('Valores', style: theme.textTheme.titleLarge),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _InfoCard(
                        title: 'Valor Total',
                        value: 'R\$ ${totalValue.toStringAsFixed(2)}',
                        color: const Color(0xFF1565C0),
                        icon: Icons.attach_money,
                        compact: false,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _InfoCard(
                        title: 'Valor Recebido',
                        value: 'R\$ ${receivedValue.toStringAsFixed(2)}',
                        color: const Color(0xFF2E7D32),
                        icon: Icons.check_circle_outline,
                        compact: false,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _InfoCard(
                        title: 'Valor a Receber',
                        value: 'R\$ ${toReceiveValue.toStringAsFixed(2)}',
                        color: const Color(0xFFE65100),
                        icon: Icons.schedule,
                        compact: false,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text('Serviços por Período', style: theme.textTheme.titleLarge),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _InfoCard(
                        title: 'Manhã',
                        value: morningServices.toString(),
                        color: Colors.amber.shade800,
                        icon: Icons.wb_sunny,
                        compact: false,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _InfoCard(
                        title: 'Tarde',
                        value: afternoonServices.toString(),
                        color: Colors.orange.shade800,
                        icon: Icons.sunny,
                        compact: false,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _InfoCard(
                        title: 'Noite',
                        value: nightServices.toString(),
                        color: Colors.indigo.shade700,
                        icon: Icons.nightlight,
                        compact: false,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text('Serviços Realizados por Mês', style: theme.textTheme.titleLarge),
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
  final IconData icon;
  final bool compact;
  
  const _InfoCard({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
    this.compact = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.of(context).size.width;
    
    return Container(
      width: compact ? (width - 56) / 2 : null,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color.withOpacity(0.9),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}