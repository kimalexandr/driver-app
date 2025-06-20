import 'package:flutter/material.dart';
import 'package:phone_auth_app/screens/loading_screen.dart';

class RequestDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> request;
  final void Function(Map<String, dynamic>)? onArchive;

  const RequestDetailsScreen({
    super.key,
    required this.request,
    this.onArchive,
  });

  @override
  State<RequestDetailsScreen> createState() => _RequestDetailsScreenState();
}

class _RequestDetailsScreenState extends State<RequestDetailsScreen> {
  final bool _isLoading = false;

  Future<void> _openYandexMaps(String address) async {
    // Здесь будет логика открытия Яндекс Карт
  }

  void _handleButtonPress() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            LoadingScreen(request: widget.request, onArchive: widget.onArchive),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text('Заявка №${widget.request['number']}'),
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
                      content: widget.request['loading_address'],
                      onTap: () =>
                          _openYandexMaps(widget.request['loading_address']),
                    ),
                    _buildInfoRow(
                      icon: Icons.calendar_today,
                      title: 'Дата и время',
                      content:
                          '${widget.request['loading_date']} ${widget.request['loading_time']}',
                    ),
                    _buildInfoRow(
                      icon: Icons.business,
                      title: 'Компания',
                      content: widget.request['loading_company'],
                    ),
                    _buildInfoRow(
                      icon: Icons.scale,
                      title: 'Масса',
                      content: '${widget.request['loading_weight']} кг',
                    ),
                    _buildInfoRow(
                      icon: Icons.calculate,
                      title: 'Объем',
                      content: '${widget.request['loading_volume']} м³',
                    ),
                    _buildInfoRow(
                      icon: Icons.comment,
                      title: 'Комментарий',
                      content: widget.request['loading_comment'],
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
                      content: widget.request['unloading_address'],
                      onTap: () =>
                          _openYandexMaps(widget.request['unloading_address']),
                    ),
                    _buildInfoRow(
                      icon: Icons.calendar_today,
                      title: 'Дата и время',
                      content:
                          '${widget.request['unloading_date']} ${widget.request['unloading_time']}',
                    ),
                    _buildInfoRow(
                      icon: Icons.business,
                      title: 'Компания получатель',
                      content: widget.request['unloading_company'],
                    ),
                    _buildInfoRow(
                      icon: Icons.scale,
                      title: 'Масса',
                      content: '${widget.request['unloading_weight']} кг',
                    ),
                    _buildInfoRow(
                      icon: Icons.calculate,
                      title: 'Объем',
                      content: '${widget.request['unloading_volume']} м³',
                    ),
                    _buildInfoRow(
                      icon: Icons.comment,
                      title: 'Комментарий',
                      content: widget.request['unloading_comment'],
                    ),
                  ],
                ),
              ),
              // Кнопка "В путь на погрузку" или "Прибыл на погрузку"
              Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _handleButtonPress,
                  icon: const Icon(Icons.directions_car),
                  label: Text(
                      _isLoading ? 'Прибыл на погрузку' : 'В путь на погрузку'),
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
