import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/service.dart';
import '../widgets/gradient_header.dart';

class DashboardPage extends StatefulWidget {
  final List<Service> services;
  const DashboardPage({Key? key, required this.services}) : super(key: key);

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String _filterType = 'mes';
  DateTime _selectedDate = DateTime.now();
  int _selectedYear = DateTime.now().year;
  bool _showFilters = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filteredServices = _getFilteredServices();

    final total = filteredServices.length;
    final realized = filteredServices.where((s) => s.realized).length;
    final notRealized = total - realized;
    final received = filteredServices.where((s) => s.received).length;
    final notReceived = total - received;

    final totalValue = filteredServices.fold<double>(0.0, (sum, s) => sum + s.value);
    final receivedValue = filteredServices
        .where((s) => s.received)
        .fold<double>(0.0, (sum, s) => sum + s.value);
    final toReceiveValue = totalValue - receivedValue;

    final morningServices = filteredServices.where((s) => s.period == 'manhã').length;
    final afternoonServices = filteredServices.where((s) => s.period == 'tarde').length;
    final nightServices = filteredServices.where((s) => s.period == 'noite').length;

    final dataByMonth = _groupByMonth(filteredServices);

    // 🔹 Frase de legenda dinâmica
    final String filterDescription = _filterType == 'mes'
        ? 'Exibindo dados de ${DateFormat('MMMM yyyy', 'pt_BR').format(_selectedDate)}'
        : _filterType == 'ano'
            ? 'Exibindo dados do ano de $_selectedYear'
            : 'Exibindo dados gerais';

    return Column(
      children: [
        const GradientHeader(title: 'Dashboard'),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    onPressed: () => setState(() => _showFilters = !_showFilters),
                    icon: Icon(_showFilters ? Icons.filter_alt_off : Icons.filter_alt),
                    label: Text(_showFilters ? 'Ocultar Filtros' : 'Filtrar'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      textStyle: const TextStyle(fontSize: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (_showFilters) _buildFilterSection(theme),
                const SizedBox(height: 8),
                Text(
                  filterDescription,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 16),

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

                LayoutBuilder(
                  builder: (context, constraints) {
                    return Row(
                      children: [
                        Expanded(
                          child: _InfoCard(
                            title: 'Valor Total',
                            value: 'R\$ ${totalValue.toStringAsFixed(2)}',
                            color: const Color(0xFF1565C0),
                            icon: Icons.attach_money,
                            compact: false,
                            fitText: true,
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
                            fitText: true,
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
                            fitText: true,
                          ),
                        ),
                      ],
                    );
                  },
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

  Widget _buildFilterSection(ThemeData theme) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.filter_list, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text('Filtrar por:', style: theme.textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildFilterChip('Mensal', 'mes', theme),
                _buildFilterChip('Anual', 'ano', theme),
                _buildFilterChip('Geral', 'geral', theme),
              ],
            ),
            if (_filterType == 'mes') ...[
              const SizedBox(height: 12),
              InkWell(
                onTap: () async {
                  // 🔹 Apenas seleciona mês/ano — sem calendário completo
                  final now = DateTime.now();
                  final selected = await showDialog<DateTime>(
                    context: context,
                    builder: (context) {
                      int year = _selectedDate.year;
                      int month = _selectedDate.month;
                      return AlertDialog(
                        title: const Text('Selecione o mês e o ano'),
                        content: Row(
                          children: [
                            Expanded(
                              child: DropdownButton<int>(
                                value: month,
                                items: List.generate(
                                  12,
                                  (index) => DropdownMenuItem(
                                    value: index + 1,
                                    child: Text(
                                      DateFormat('MMMM', 'pt_BR').format(DateTime(0, index + 1)),
                                    ),
                                  ),
                                ),
                                onChanged: (value) => setState(() => month = value!),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: DropdownButton<int>(
                                value: year,
                                items: List.generate(7, (i) => now.year - 3 + i).map((y) {
                                  return DropdownMenuItem(value: y, child: Text(y.toString()));
                                }).toList(),
                                onChanged: (value) => setState(() => year = value!),
                              ),
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context, DateTime(year, month));
                            },
                            child: const Text('Confirmar'),
                          ),
                        ],
                      );
                    },
                  );

                  if (selected != null) {
                    setState(() {
                      _selectedDate = selected;
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  decoration: BoxDecoration(
                    border: Border.all(color: theme.colorScheme.outline.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.calendar_month, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat('MMMM yyyy', 'pt_BR').format(_selectedDate),
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
            ],
            if (_filterType == 'ano') ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                value: _selectedYear,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  prefixIcon: Icon(Icons.date_range, color: theme.colorScheme.primary),
                ),
                items: List.generate(7, (index) => 2024 + index).map((year) {
                  return DropdownMenuItem(
                    value: year,
                    child: Text(year.toString()),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedYear = value;
                    });
                  }
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, ThemeData theme) {
    final isSelected = _filterType == value;
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) => setState(() => _filterType = value),
      selectedColor: theme.colorScheme.primary,
      backgroundColor: theme.colorScheme.surfaceVariant,
    );
  }

  List<Service> _getFilteredServices() {
    switch (_filterType) {
      case 'mes':
        return widget.services.where((service) {
          return service.date.year == _selectedDate.year &&
              service.date.month == _selectedDate.month;
        }).toList();
      case 'ano':
        return widget.services.where((service) {
          return service.date.year == _selectedYear;
        }).toList();
      default:
        return widget.services;
    }
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
  final bool fitText;

  const _InfoCard({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
    this.compact = true,
    this.fitText = false,
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
          FittedBox(
            fit: fitText ? BoxFit.scaleDown : BoxFit.none,
            child: Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
