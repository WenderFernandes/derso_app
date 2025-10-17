import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

import '../models/service.dart';
import '../providers/service_provider.dart';
import '../widgets/gradient_header.dart';

/// Tela com calendário interativo para visualizar e navegar pelos serviços
/// agendados. O pacote table_calendar permite carregar eventos para cada dia
/// através da propriedade eventLoader【365772808055763†L182-L199】.
class CalendarPage extends StatefulWidget {
  const CalendarPage({Key? key}) : super(key: key);

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    final serviceProvider = context.watch<ServiceProvider>();
    final events = _groupServicesByDate(serviceProvider.services);
    final theme = Theme.of(context);
    return Column(
      children: [
        const GradientHeader(title: 'Calendário'),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                TableCalendar<Service>(
                  firstDay: DateTime.utc(2024, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: _focusedDay,
                  selectedDayPredicate: (day) {
                    return isSameDay(_selectedDay, day);
                  },
                  calendarFormat: CalendarFormat.month,
                  eventLoader: (day) {
                    return events[DateTime(day.year, day.month, day.day)] ?? [];
                  },
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                  },
                  onPageChanged: (focusedDay) {
                    _focusedDay = focusedDay;
                  },
                  calendarStyle: CalendarStyle(
                    markerDecoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    todayDecoration: BoxDecoration(
                      color: theme.colorScheme.secondary,
                      shape: BoxShape.circle,
                    ),
                    selectedDecoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _buildEventList(events),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Agrupa os serviços por data para uso no eventLoader da TableCalendar.
  Map<DateTime, List<Service>> _groupServicesByDate(List<Service> services) {
    final Map<DateTime, List<Service>> data = {};
    for (final service in services) {
      final date = DateTime(service.date.year, service.date.month, service.date.day);
      data.putIfAbsent(date, () => []);
      data[date]!.add(service);
    }
    return data;
  }

  /// Lista os serviços do dia selecionado.
  Widget _buildEventList(Map<DateTime, List<Service>> events) {
    final selectedDate = _selectedDay;
    final services = selectedDate != null
        ? events[DateTime(selectedDate.year, selectedDate.month, selectedDate.day)] ?? []
        : [];
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            selectedDate != null
                ? 'Serviços em ${DateFormat('dd/MM/yyyy').format(selectedDate)}'
                : 'Selecione uma data',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          if (services.isEmpty)
            Text(
              'Nenhum serviço para esta data.',
              style: theme.textTheme.bodyMedium,
            )
          else
            Column(
              children: services
                  .map(
                    (service) => _CalendarEventTile(service: service),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }
}

class _CalendarEventTile extends StatelessWidget {
  final Service service;
  const _CalendarEventTile({required this.service});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 2,
      child: ListTile(
        leading: Icon(Icons.schedule, color: theme.colorScheme.primary),
        title: Text('${service.startTime} - ${service.endTime}'),
        subtitle: Text(service.period.capitalize()),
        trailing: Icon(
          service.realized ? Icons.check_circle : Icons.hourglass_bottom,
          color: service.realized
              ? theme.colorScheme.primary
              : theme.colorScheme.secondary,
        ),
      ),
    );
  }
}

extension on String {
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }
}