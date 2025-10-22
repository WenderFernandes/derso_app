import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/service.dart';
import '../providers/user_provider.dart';
import '../widgets/gradient_header.dart';

class ServiceFormPage extends StatefulWidget {
  final Service? existingService;
  final DateTime? preselectedDate; // ✅ novo parâmetro opcional

  const ServiceFormPage({
    Key? key,
    this.existingService,
    this.preselectedDate,
  }) : super(key: key);

  @override
  State<ServiceFormPage> createState() => _ServiceFormPageState();
}

class _ServiceFormPageState extends State<ServiceFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _valueController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _startTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 12, minute: 0);
  bool _realized = false;
  DateTime? _paymentDate;
  NotificationPreference _notificationPreference =
      NotificationPreference.oneHourBefore;

  @override
  void initState() {
    super.initState();

    final service = widget.existingService;

    if (service != null) {
      // 🔹 Edição de serviço existente
      _selectedDate = service.date;
      _startTime = _parseTime(service.startTime);
      _endTime = _parseTime(service.endTime);
      _realized = service.realized;
      _paymentDate = service.paymentDate;
      _valueController.text = service.value.toStringAsFixed(2);
      _notificationPreference = service.notificationPreference;
    } else {
      // 🔹 Novo serviço
      _selectedDate = widget.preselectedDate ?? DateTime.now(); // ✅ usa a data pré-selecionada
      _valueController.text = '289.25';
    }
  }

  @override
  void dispose() {
    _valueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.read<UserProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingService == null
            ? 'Novo Serviço'
            : 'Editar Serviço'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Data do serviço',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2024, 1, 1),
                      lastDate: DateTime(2030, 12, 31),
                    );
                    if (date != null) {
                      setState(() {
                        _selectedDate = date;
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 14),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today,
                            color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(DateFormat('dd/MM/yyyy').format(_selectedDate)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Horário inicial',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: _startTime,
                    );
                    if (time != null) {
                      setState(() {
                        _startTime = time;
                        if (_endTime.hour < time.hour ||
                            (_endTime.hour == time.hour &&
                                _endTime.minute <= time.minute)) {
                          _endTime = TimeOfDay(
                            hour: (time.hour + 4) % 24,
                            minute: time.minute,
                          );
                        }
                      });
                    }
                  },
                  child: _buildTimeField(_startTime),
                ),
                const SizedBox(height: 16),
                Text('Horário final',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: _endTime,
                    );
                    if (time != null) {
                      setState(() {
                        _endTime = time;
                      });
                    }
                  },
                  child: _buildTimeField(_endTime),
                ),
                const SizedBox(height: 16),
                Text('Valor do serviço',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _valueController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(r'^\d+\.?\d{0,2}')),
                  ],
                  decoration: InputDecoration(
                    prefixText: 'R\$ ',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    hintText: '289.25',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Informe o valor do serviço';
                    }
                    final doubleValue = double.tryParse(value);
                    if (doubleValue == null || doubleValue <= 0) {
                      return 'Informe um valor válido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Text('Notificar',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                DropdownButtonFormField<NotificationPreference>(
                  value: _notificationPreference,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.notifications_active),
                  ),
                  items: NotificationPreference.values.map((pref) {
                    return DropdownMenuItem(
                      value: pref,
                      child: Text(pref.label),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _notificationPreference = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Serviço realizado'),
                  value: _realized,
                  onChanged: (value) {
                    setState(() {
                      _realized = value;
                      if (!value) {
                        _paymentDate = null;
                      }
                    });
                  },
                ),
                if (_realized) ...[
                  const SizedBox(height: 8),
                  Text('Data de pagamento'),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _paymentDate ?? DateTime.now(),
                        firstDate: DateTime(2024, 1, 1),
                        lastDate: DateTime(2030, 12, 31),
                      );
                      if (date != null) {
                        setState(() {
                          _paymentDate = date;
                        });
                      }
                    },
                    child: _paymentDate != null
                        ? _buildDateDisplay(_paymentDate!)
                        : Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 14),
                            decoration: BoxDecoration(
                              border:
                                  Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text('Selecionar data'),
                          ),
                  ),
                ],
                const SizedBox(height: 32),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        final period = _getPeriod(_startTime);
                        final value = double.parse(_valueController.text);
                        final service = Service(
                          id: widget.existingService?.id,
                          date: _selectedDate,
                          startTime: _formatTime(_startTime),
                          endTime: _formatTime(_endTime),
                          period: period,
                          value: value,
                          realized: _realized,
                          received: widget.existingService?.received ?? false,
                          paymentDate: _paymentDate,
                          userId: userProvider.user!.id!,
                          notificationPreference: _notificationPreference,
                        );
                        Navigator.of(context).pop(service);
                      }
                    },
                    child: const Text('Salvar'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeField(TimeOfDay time) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.access_time,
              color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Text(_formatTime(time)),
        ],
      ),
    );
  }

  String _formatTime(TimeOfDay time) {
    final hours = time.hour.toString().padLeft(2, '0');
    final minutes = time.minute.toString().padLeft(2, '0');
    return '$hours:$minutes';
  }

  TimeOfDay _parseTime(String timeStr) {
    final parts = timeStr.split(':');
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }

  String _getPeriod(TimeOfDay time) {
    final hour = time.hour;
    if (hour >= 5 && hour < 12) {
      return 'manhã';
    } else if (hour >= 12 && hour < 18) {
      return 'tarde';
    } else {
      return 'noite';
    }
  }

  Widget _buildDateDisplay(DateTime date) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.payments,
              color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Text(DateFormat('dd/MM/yyyy').format(date)),
        ],
      ),
    );
  }
}
