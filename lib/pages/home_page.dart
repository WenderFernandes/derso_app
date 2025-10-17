import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

import '../models/service.dart';
import '../providers/service_provider.dart';
import '../providers/user_provider.dart';
import '../services/notification_service.dart';
import '../widgets/gradient_header.dart';
import 'calendar_page.dart';
import 'dashboard_page.dart';
import 'profile_page.dart';
import 'service_form_page.dart';

/// Tela principal após o login. Possui navegação por abas para Início,
/// Calendário, Dashboard e Perfil. Um botão flutuante permite o cadastro de
/// novos serviços.
class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    // Carrega os serviços do usuário atual assim que o widget é criado.
    final userProvider = context.read<UserProvider>();
    final serviceProvider = context.read<ServiceProvider>();
    if (userProvider.user != null) {
      serviceProvider.loadServices(userProvider.user!.id!);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final serviceProvider = context.watch<ServiceProvider>();
    final userProvider = context.watch<UserProvider>();

    // Cria uma lista de serviços do dia atual para exibir no painel inicial.
    final today = DateTime.now();
    final todayServices = serviceProvider.services
        .where((s) => s.date.year == today.year &&
            s.date.month == today.month &&
            s.date.day == today.day)
        .toList();

    return Scaffold(
      appBar: null,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildHomeTab(context, todayServices),
          CalendarPage(),
          DashboardPage(services: serviceProvider.services),
          ProfilePage(user: userProvider.user!),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Abrir formulário para novo serviço
          final newService = await Navigator.of(context).push<Service?>(
            MaterialPageRoute(
              builder: (_) => ServiceFormPage(),
            ),
          );
          if (newService != null) {
            // Adiciona serviço e agenda notificação
            await serviceProvider.addService(newService);
            final notifService = NotificationService();
            await notifService.scheduleNotification(
              id: newService.id ?? DateTime.now().millisecondsSinceEpoch,
              scheduledDate: tz.TZDateTime.from(
                newService.date.subtract(
                  const Duration(hours: 1),
                ),
                tz.local,
              ),
              title: 'Serviço DERSO',
              body:
                  'Você possui um serviço ${newService.period} em ${DateFormat('dd/MM/yyyy').format(newService.date)} às ${newService.startTime}.',
            );
          }
        },
        tooltip: 'Novo serviço',
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Início',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month),
            label: 'Calendário',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }

  /// Constrói o painel inicial, exibindo um resumo dos serviços do dia e
  /// estatísticas rápidas.
  Widget _buildHomeTab(BuildContext context, List<Service> todayServices) {
    final theme = Theme.of(context);
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
                Text(
                  'Serviços de hoje',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                if (todayServices.isEmpty)
                  Text(
                    'Nenhum serviço agendado para hoje.',
                    style: theme.textTheme.bodyMedium,
                  )
                else
                  Column(
                    children: todayServices.map((service) {
                      return _ServiceCard(service: service);
                    }).toList(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Card para exibir informações básicas de um serviço na tela inicial.
class _ServiceCard extends StatelessWidget {
  final Service service;
  const _ServiceCard({required this.service});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Icon(
              Icons.access_time,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${service.startTime} - ${service.endTime}',
                    style: theme.textTheme.titleMedium,
                  ),
                  Text(
                    service.period.capitalize(),
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: service.realized
                    ? theme.colorScheme.primaryContainer
                    : theme.colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Text(
                service.realized ? 'Realizado' : 'Pendente',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: service.realized
                      ? theme.colorScheme.onPrimaryContainer
                      : theme.colorScheme.onSecondaryContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }
}