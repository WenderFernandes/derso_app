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
                _buildEventList(events, serviceProvider.services),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Map<DateTime, List<Service>> _groupServicesByDate(List<Service> services) {
    final Map<DateTime, List<Service>> data = {};
    for (final service in services) {
      final date = DateTime(service.date.year, service.date.month, service.date.day);
      data.putIfAbsent(date, () => []);
      data[date]!.add(service);
    }
    return data;
  }

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

    filteredServices = events[DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day)] ?? [];
    title = 'Serviços em ${DateFormat('dd/MM/yyyy').format(_selectedDay!)}';

    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          if (filteredServices.isEmpty)
            Text(
              'Nenhum serviço para este dia.',
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
}

class _CalendarEventTile extends StatelessWidget {
  final Service service;
  const _CalendarEventTile({required this.service});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final serviceProvider = context.read<ServiceProvider>();
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.schedule, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${service.startTime} - ${service.endTime}',
                          style: theme.textTheme.titleMedium),
                      Text(service.period.capitalize(),
                          style: theme.textTheme.bodyMedium),
                      Text(
                        'R\$ ${service.value.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
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
            const Divider(),
            Row(
              children: [
                Expanded(
                  child: Text('Realizado', style: theme.textTheme.bodySmall),
                ),
                Switch(
                  value: service.realized,
                  onChanged: service.received
                      ? null
                      : (_) => serviceProvider.toggleRealized(service),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: Text('Recebido', style: theme.textTheme.bodySmall),
                ),
                Switch(
                  value: service.received,
                  onChanged: service.realized
                      ? (value) => _handleReceivedToggle(context, service, value)
                      : null,
                ),
              ],
            ),
            if (service.paymentDate != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Pago em: ${DateFormat('dd/MM/yyyy').format(service.paymentDate!)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
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
        
        final notifTime = _calculateNotificationTime(
          updated.date,
          updated.startTime,
          updated.notificationPreference,
        );
        
        if (notifTime.isAfter(DateTime.now())) {
          await notifService.scheduleNotification(
            id: updated.id!,
            scheduledDate: tz.TZDateTime.from(notifTime, tz.local),
            title: 'Serviço DERSO',
            body: 'Você possui um serviço ${updated.period} em ${DateFormat('dd/MM/yyyy').format(updated.date)} às ${updated.startTime}.',
          );
        }
        
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

  void _handleReceivedToggle(BuildContext context, Service service, bool value) async {
    final serviceProvider = context.read<ServiceProvider>();

    if (value) {
      final paymentDate = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(2024, 1, 1),
        lastDate: DateTime(2030, 12, 31),
      );

      if (paymentDate != null) {
        final success = await serviceProvider.markAsReceived(service, paymentDate);
        if (!success && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Marque o serviço como realizado primeiro')),
          );
        }
      }
    } else {
      await serviceProvider.unmarkAsReceived(service);
    }
  }

  DateTime _calculateNotificationTime(
    DateTime serviceDate,
    String startTime,
    NotificationPreference preference,
  ) {
    final timeParts = startTime.split(':');
    final serviceDateTime = DateTime(
      serviceDate.year,
      serviceDate.month,
      serviceDate.day,
      int.parse(timeParts[0]),
      int.parse(timeParts[1]),
    );

    if (preference == NotificationPreference.sameDay) {
      return DateTime(
        serviceDate.year,
        serviceDate.month,
        serviceDate.day,
        8,
        0,
      );
    }

    return serviceDateTime.subtract(preference.duration);
  }
}

extension on String {
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }
}