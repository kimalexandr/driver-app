import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'loading_screen.dart';

class RequestDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> request;

  const RequestDetailsScreen({
    super.key,
    required this.request,
  });

  Future<void> _openYandexMaps(String address) async {
    final url = Uri.parse(
      'https://yandex.ru/maps/?text=${Uri.encodeComponent(address)}',
    );
    if (await canLaunch(url.toString())) {
      await launchUrl(url);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Заявка №${request['number']}'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Секция погрузки
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.blue.shade50,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Погрузка',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow(
                    icon: Icons.location_on,
                    title: 'Адрес',
                    content: request['loading_address'],
                    onTap: () => _openYandexMaps(request['loading_address']),
                  ),
                  _buildInfoRow(
                    icon: Icons.calendar_today,
                    title: 'Дата и время',
                    content:
                        '${request['loading_date']} ${request['loading_time']}',
                  ),
                  _buildInfoRow(
                    icon: Icons.business,
                    title: 'Компания',
                    content: request['loading_company'],
                  ),
                  _buildInfoRow(
                    icon: Icons.scale,
                    title: 'Масса',
                    content: '${request['loading_weight']} кг',
                  ),
                  _buildInfoRow(
                    icon: Icons.calculate,
                    title: 'Объем',
                    content: '${request['loading_volume']} м³',
                  ),
                  _buildInfoRow(
                    icon: Icons.comment,
                    title: 'Комментарий',
                    content: request['loading_comment'],
                  ),
                ],
              ),
            ),
            // Секция разгрузки
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.green.shade50,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Разгрузка',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow(
                    icon: Icons.location_on,
                    title: 'Адрес',
                    content: request['unloading_address'],
                    onTap: () => _openYandexMaps(request['unloading_address']),
                  ),
                  _buildInfoRow(
                    icon: Icons.calendar_today,
                    title: 'Дата и время',
                    content:
                        '${request['unloading_date']} ${request['unloading_time']}',
                  ),
                  _buildInfoRow(
                    icon: Icons.business,
                    title: 'Компания получатель',
                    content: request['unloading_company'],
                  ),
                  _buildInfoRow(
                    icon: Icons.scale,
                    title: 'Масса',
                    content: '${request['unloading_weight']} кг',
                  ),
                  _buildInfoRow(
                    icon: Icons.calculate,
                    title: 'Объем',
                    content: '${request['unloading_volume']} м³',
                  ),
                  _buildInfoRow(
                    icon: Icons.comment,
                    title: 'Комментарий',
                    content: request['unloading_comment'],
                  ),
                ],
              ),
            ),
            // Кнопка "В путь на погрузку"
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LoadingScreen(request: request),
                    ),
                  );
                },
                icon: const Icon(Icons.directions_car),
                label: const Text('В путь на погрузку'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String content,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
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
    );
  }
}
