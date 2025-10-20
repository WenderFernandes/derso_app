import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;

import '../models/service.dart';
import '../providers/service_provider.dart';
import '../widgets/gradient_header.dart';
import '../services/notification_service.dart';
import 'service_form_page.dart';

/// Tela com calendário interativo para visualizar e navegar pelos serviços
/// agendados. O pacote table_calendar permite carregar eventos para cada dia
/// através da propriedade eventLoader.
class CalendarPage extends StatefulWidget {
  const CalendarPage({Key? key}) : super(key: key);

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  String _filterType = 'dia'; // 'dia', 'semana', 'mes', 'ano'

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
                _buildFilterButtons(),
                const SizedBox(height: 12),
                _buildEventList(events, serviceProvider.services),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Botões de filtro para período, semana, mês e ano
  Widget _buildFilterButtons() {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildFilterChip('Dia', 'dia', theme),
          _buildFilterChip('Semana', 'semana', theme),
          _buildFilterChip('Mês', 'mes', theme),
          _buildFilterChip('Ano', 'ano', theme),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, ThemeData theme) {
    final isSelected = _filterType == value;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: FilterChip(
          label: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
            ),
          ),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              _filterType = value;
            });
          },
          selectedColor: theme.colorScheme.primary,
          backgroundColor: theme.colorScheme.surfaceVariant,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        ),
      ),
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

  /// Lista os serviços conforme o filtro selecionado
  Widget _buildEventList(Map<DateTime, List<Service>> events, List<Service> allServices) {
    List<Service> filteredServices = [];
    String title = '';

    if (_selectedDay == null) {
      return Container(
        padding: const EdgeInsets.all(12),
        child: Text(
          'Selecione uma data',
          style: Theme.of(context).textTheme.titleMedium,
        ),
      );
    }

    switch (_filterType) {
      case 'dia':
        filteredServices = events[DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day)] ?? [];
        title = 'Serviços em ${DateFormat('dd/MM/yyyy').format(_selectedDay!)}';
        break;
      case 'semana':
        filteredServices = _getServicesForWeek(_selectedDay!, allServices);
        final weekStart = _getWeekStart(_selectedDay!);
        final weekEnd = weekStart.add(const Duration(days: 6));
        title = 'Serviços de ${DateFormat('dd/MM').format(weekStart)} a ${DateFormat('dd/MM/yyyy').format(weekEnd)}';
        break;
      case 'mes':
        filteredServices = _getServicesForMonth(_selectedDay!, allServices);
        title = 'Serviços de ${DateFormat('MMMM yyyy', 'pt_BR').format(_selectedDay!)}';
        break;
      case 'ano':
        filteredServices = _getServicesForYear(_selectedDay!, allServices);
        title = 'Serviços de ${_selectedDay!.year}';
        break;
    }

    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          if (filteredServices.isEmpty)
            Text(
              'Nenhum serviço para este período.',
              style: theme.textTheme.bodyMedium,
            )
          else
            Column(
              children: filteredServices
                  .map((service) => _CalendarEventTile(service: service))
                  .toList(),
            ),
        ],
      ),
    );
  }

  DateTime _getWeekStart(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }

  List<Service> _getServicesForWeek(DateTime date, List<Service> services) {
    final weekStart = _getWeekStart(date);
    final weekEnd = weekStart.add(const Duration(days: 6));
    
    return services.where((service) {
      return service.date.isAfter(weekStart.subtract(const Duration(days: 1))) &&
             service.date.isBefore(weekEnd.add(const Duration(days: 1)));
    }).toList();
  }

  List<Service> _getServicesForMonth(DateTime date, List<Service> services) {
    return services.where((service) {
      return service.date.year == date.year && service.date.month == date.month;
    }).toList();
  }

  List<Service> _getServicesForYear(DateTime date, List<Service> services) {
    return services.where((service) {
      return service.date.year == date.year;
    }).toList();
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
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(service.period.capitalize()),
            Text(
              'R\$ ${service.value.toStringAsFixed(2)}',
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              service.realized ? Icons.check_circle : Icons.hourglass_bottom,
              color: service.realized
                  ? theme.colorScheme.primary
                  : theme.colorScheme.secondary,
            ),
            if (!service.received)
              PopupMenuButton<String>(
                onSelected: (value) => _handleMenuAction(context, value, service),
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'edit', child: Text('Editar')),
                  const PopupMenuItem(value: 'delete', child: Text('Excluir')),
                ],
              ),
          ],
        ),
      ),
    );
  }

  void _handleMenuAction(BuildContext context, String action, Service service) async {
    final serviceProvider = context.read<ServiceProvider>();
    final notifService = NotificationService();

    if (action == 'edit') {
      final updated = await Navigator.of(context).push<Service?>(
        MaterialPageRoute(
          builder: (_) => ServiceFormPage(existingService: service),
        ),
      );

      if (updated != null) {
        await serviceProvider.updateService(updated);
        await notifService.cancelNotification(service.id!);
        
        final notifTime = updated.date.subtract(const Duration(hours: 1));
        await notifService.scheduleNotification(
          id: updated.id!,
          scheduledDate: tz.TZDateTime.from(notifTime, tz.local),
          title: 'Serviço DERSO',
          body: 'Você possui um serviço ${updated.period} em ${DateFormat('dd/MM/yyyy').format(updated.date)} às ${updated.startTime}.',
        );
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Serviço atualizado com sucesso')),
          );
        }
      }
    } else if (action == 'delete') {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirmar exclusão'),
          content: const Text('Deseja realmente excluir este serviço?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Excluir'),
            ),
          ],
        ),
      );

      if (confirm == true) {
        final success = await serviceProvider.deleteService(service.id!);
        if (success) {
          await notifService.cancelNotification(service.id!);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Serviço excluído com sucesso')),
            );
          }
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Não é possível excluir serviço já recebido')),
            );
          }
        }
      }
    }
  }
}

extension on String {
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }
}