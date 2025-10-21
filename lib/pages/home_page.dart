import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;

import '../models/service.dart';
import '../providers/service_provider.dart';
import '../providers/user_provider.dart';
import '../providers/theme_provider.dart';
import '../services/notification_service.dart';
import '../widgets/gradient_header.dart';
import 'calendar_page.dart';
import 'dashboard_page.dart';
import 'profile_page.dart';
import 'service_form_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    final userProvider = context.read<UserProvider>();
    final serviceProvider = context.read<ServiceProvider>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<UserProvider>().user;
      if (user != null) {
        context.read<ServiceProvider>().loadServices(user.id!);
        _checkTrialStatus();
      }
    });
  }

  void _checkTrialStatus() {
    final user = context.read<UserProvider>().user;
    if (user != null && !user.isTrialActive && !user.isPremium) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showTrialExpiredDialog();
      });
    } else if (user != null && !user.isPremium && user.remainingTrialDays <= 3) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showTrialWarning(user.remainingTrialDays);
      });
    }
  }

  void _showTrialExpiredDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Período de Teste Expirado'),
        content: const Text(
          'Seu período de teste de 10 dias expirou. Para continuar usando o DERSO, ative a versão premium.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<UserProvider>().logout();
            },
            child: const Text('Sair'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showPremiumActivation();
            },
            child: const Text('Ativar Premium'),
          ),
        ],
      ),
    );
  }

  void _showTrialWarning(int remainingDays) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Restam $remainingDays dias do seu período de teste'),
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Ativar Premium',
          onPressed: _showPremiumActivation,
        ),
      ),
    );
  }

  void _showPremiumActivation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ativar Versão Premium'),
        content: const Text(
          'Entre em contato com o suporte para ativar sua versão premium.\n\nEmail: suporte@derso.com\nTelefone: (69) 9999-9999',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
          ElevatedButton(
            onPressed: () async {
              await context.read<UserProvider>().activatePremium();
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Premium ativado com sucesso!')),
                );
              }
            },
            child: const Text('Ativar (Demo)'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final serviceProvider = context.watch<ServiceProvider>();
    final userProvider = context.watch<UserProvider>();
    final themeProvider = context.watch<ThemeProvider>();

    final firstName = userProvider.user?.name.split(' ').first ?? 'Usuário';

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('DERSO'),
            if (userProvider.user != null && !userProvider.user!.isPremium) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Trial: ${userProvider.user!.remainingTrialDays}d',
                  style: const TextStyle(fontSize: 10, color: Colors.white),
                ),
              ),
            ],
            const Spacer(),
            Text('Olá! $firstName'),
          ],
        ),
        toolbarHeight: 48,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _addNewService(context),
            tooltip: 'Novo serviço',
          ),
          IconButton(
            icon: Icon(themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: () {
              themeProvider.toggleTheme();
            },
            tooltip: 'Alternar tema',
          ),
        ],
      ),
      body: userProvider.user == null
        ? const Center(child: CircularProgressIndicator())
        : IndexedStack(
            index: _currentIndex,
            children: [
              _HomeTab(services: serviceProvider.services),
              const CalendarPage(),
              DashboardPage(services: serviceProvider.services),
              ProfilePage(user: userProvider.user!),
            ],
          ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Início'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: 'Calendário'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    );
  }

  Future<void> _addNewService(BuildContext context) async {
    final newService = await Navigator.of(context).push<Service?>(
      MaterialPageRoute(builder: (_) => const ServiceFormPage()),
    );

    if (newService != null) {
      final serviceProvider = context.read<ServiceProvider>();
      final serviceId = await serviceProvider.addService(newService);

      final notifService = NotificationService();
      final notifTime = _calculateNotificationTime(
        newService.date,
        newService.startTime,
        newService.notificationPreference,
      );
      
      if (notifTime.isAfter(DateTime.now())) {
        await notifService.scheduleNotification(
          id: serviceId,
          scheduledDate: tz.TZDateTime.from(notifTime, tz.local),
          title: 'Serviço DERSO',
          body: 'Você possui um serviço ${newService.period} em ${DateFormat('dd/MM/yyyy').format(newService.date)} às ${newService.startTime}.',
        );
      }
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

class _HomeTab extends StatefulWidget {
  final List<Service> services;
  const _HomeTab({required this.services});

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  String _filterType = 'hoje';
  DateTime _selectedDate = DateTime.now();
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filteredServices = _getFilteredServices();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const GradientHeader(title: 'Início'),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFilterButtons(theme),
                const SizedBox(height: 12),
                if (_filterType == 'periodo') _buildPeriodSelector(theme),
                const SizedBox(height: 12),
                Text(_getFilterTitle(), style: theme.textTheme.titleMedium),
                const SizedBox(height: 12),
                if (filteredServices.isEmpty)
                  Text('Nenhum serviço para este período.', style: theme.textTheme.bodyMedium)
                else
                  ...filteredServices.map((service) => _ServiceCard(service: service)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButtons(ThemeData theme) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip('Hoje', 'hoje', theme),
          const SizedBox(width: 8),
          _buildFilterChip('Semana', 'semana', theme),
          const SizedBox(width: 8),
          _buildFilterChip('Mês', 'mes', theme),
          const SizedBox(width: 8),
          _buildFilterChip('Ano', 'ano', theme),
          const SizedBox(width: 8),
          _buildFilterChip('Período', 'periodo', theme),
        ],
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
      onSelected: (selected) {
        setState(() {
          _filterType = value;
          if (value == 'periodo') {
            _startDate = null;
            _endDate = null;
          }
        });
      },
      selectedColor: theme.colorScheme.primary,
      backgroundColor: theme.colorScheme.surfaceVariant,
    );
  }

  Widget _buildPeriodSelector(ThemeData theme) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Selecione o período', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _startDate ?? DateTime.now(),
                        firstDate: DateTime(2024, 1, 1),
                        lastDate: DateTime(2030, 12, 31),
                      );
                      if (date != null) {
                        setState(() {
                          _startDate = date;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _startDate != null
                            ? DateFormat('dd/MM/yyyy').format(_startDate!)
                            : 'Data inicial',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _endDate ?? DateTime.now(),
                        firstDate: DateTime(2024, 1, 1),
                        lastDate: DateTime(2030, 12, 31),
                      );
                      if (date != null) {
                        setState(() {
                          _endDate = date;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _endDate != null
                            ? DateFormat('dd/MM/yyyy').format(_endDate!)
                            : 'Data final',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Service> _getFilteredServices() {
    switch (_filterType) {
      case 'hoje':
        return widget.services.where((service) {
          return DateUtils.isSameDay(service.date, _selectedDate);
        }).toList();
      case 'semana':
        final weekStart = _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));
        final weekEnd = weekStart.add(const Duration(days: 6));
        return widget.services.where((service) {
          return service.date.isAfter(weekStart.subtract(const Duration(days: 1))) &&
              service.date.isBefore(weekEnd.add(const Duration(days: 1)));
        }).toList();
      case 'mes':
        return widget.services.where((service) {
          return service.date.year == _selectedDate.year &&
              service.date.month == _selectedDate.month;
        }).toList();
      case 'ano':
        return widget.services.where((service) {
          return service.date.year == _selectedDate.year;
        }).toList();
      case 'periodo':
        if (_startDate == null || _endDate == null) {
          return [];
        }
        return widget.services.where((service) {
          return service.date.isAfter(_startDate!.subtract(const Duration(days: 1))) &&
              service.date.isBefore(_endDate!.add(const Duration(days: 1)));
        }).toList();
      default:
        return widget.services;
    }
  }

  String _getFilterTitle() {
    switch (_filterType) {
      case 'hoje':
        return 'Serviços de hoje (${DateFormat('dd/MM/yyyy').format(_selectedDate)})';
      case 'semana':
        final weekStart = _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));
        final weekEnd = weekStart.add(const Duration(days: 6));
        return 'Serviços de ${DateFormat('dd/MM').format(weekStart)} a ${DateFormat('dd/MM/yyyy').format(weekEnd)}';
      case 'mes':
        return 'Serviços de ${DateFormat('MMMM yyyy', 'pt_BR').format(_selectedDate)}';
      case 'ano':
        return 'Serviços de ${_selectedDate.year}';
      case 'periodo':
        if (_startDate == null || _endDate == null) {
          return 'Selecione o período';
        }
        return 'Serviços de ${DateFormat('dd/MM/yyyy').format(_startDate!)} a ${DateFormat('dd/MM/yyyy').format(_endDate!)}';
      default:
        return 'Serviços';
    }
  }
}

class _ServiceCard extends StatelessWidget {
  final Service service;
  const _ServiceCard({required this.service});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final serviceProvider = context.read<ServiceProvider>();

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.access_time, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('dd/MM/yyyy').format(service.date),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.secondary,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                      Text('${service.startTime} - ${service.endTime}',
                          style: theme.textTheme.titleMedium),
                      Text(service.period.capitalize(),
                          style: theme.textTheme.bodyMedium),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  enabled: !service.received,
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

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }
}