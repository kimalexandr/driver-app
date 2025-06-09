import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class UnloadingScreen extends StatefulWidget {
  final Map<String, dynamic> request;

  const UnloadingScreen({
    super.key,
    required this.request,
  });

  @override
  State<UnloadingScreen> createState() => _UnloadingScreenState();
}

class _UnloadingScreenState extends State<UnloadingScreen> {
  bool _isArrived = false;

  Future<void> _openYandexMaps(String address) async {
    final url = Uri.parse(
      'https://yandex.ru/maps/?text=${Uri.encodeComponent(address)}',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Заявка №${widget.request['number']} - Разгрузка'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoCard(
              icon: Icons.location_on,
              title: 'Адрес',
              content: widget.request['unloading_address'],
              onTap: () => _openYandexMaps(widget.request['unloading_address']),
            ),
            _buildInfoCard(
              icon: Icons.calendar_today,
              title: 'Дата',
              content: widget.request['unloading_date'],
            ),
            _buildInfoCard(
              icon: Icons.business,
              title: 'Клиент',
              content: widget.request['unloading_company'],
            ),
            _buildInfoCard(
              icon: Icons.door_front_door,
              title: 'Ворота',
              content: widget.request['unloading_gates'],
            ),
            _buildInfoCard(
              icon: Icons.access_time,
              title: 'Время',
              content:
                  '${widget.request['unloading_time_from']} - ${widget.request['unloading_time_to']}',
            ),
            _buildInfoCard(
              icon: Icons.person,
              title: 'Диспетчер',
              content: widget.request['unloading_dispatcher'],
            ),
            _buildInfoCard(
              icon: Icons.phone,
              title: 'Телефон диспетчера',
              content: widget.request['unloading_dispatcher_phone'],
            ),
            _buildInfoCard(
              icon: Icons.comment,
              title: 'Комментарий',
              content: widget.request['unloading_comment'],
            ),
            const SizedBox(height: 24),
            Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _isArrived = true;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Отметка о прибытии сохранена'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                icon: Icon(_isArrived ? Icons.check_circle : Icons.location_on),
                label: Text(
                    _isArrived ? 'Прибыл на разгрузку' : 'В путь на разгрузку'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(200, 48),
                  backgroundColor: _isArrived ? Colors.green : Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            if (_isArrived) ...[
              const SizedBox(height: 16),
              Center(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Реализовать завершение заявки
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Заявка успешно завершена'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Завершить заявку'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(200, 48),
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String content,
    VoidCallback? onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 24, color: Colors.blue),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: onTap,
                    child: Text(
                      content,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: onTap != null ? Colors.blue : Colors.black,
                        decoration:
                            onTap != null ? TextDecoration.underline : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
