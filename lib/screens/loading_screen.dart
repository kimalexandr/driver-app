import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'unloading_screen.dart';

class LoadingScreen extends StatefulWidget {
  final Map<String, dynamic> request;
  final void Function(Map<String, dynamic>)? onArchive;

  const LoadingScreen({
    super.key,
    required this.request,
    this.onArchive,
  });

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  bool _isSigned = false;
  File? _ttnPhoto;

  int _loadingStep = 0; // 0 - Въезд, 1 - Погрузка, 2 - Выезд, 3 - В пути

  final List<String> _stepTitles = [
    'Въезд на территорию погрузки',
    'Погрузка на пункте',
    'Выезд с территории погрузки',
    'В пути к пункту выгрузки',
  ];

  final List<String> _buttonTitles = [
    'Подтвердить въезд',
    'Подтвердить погрузку',
    'Подтвердить выезд',
    'В путь к пункту выгрузки',
  ];

  Future<void> _openYandexMaps(String address) async {
    final url = Uri.parse(
      'https://yandex.ru/maps/?text=${Uri.encodeComponent(address)}',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  Future<void> _takePhoto() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        _ttnPhoto = File(pickedFile.path);
      });
    }
  }

  void _showSignatureDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Подпись'),
        content: const SizedBox(
          height: 200,
          child: Center(
            child: Text('Здесь будет поле для подписи'),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _isSigned = true;
              });
              Navigator.pop(context);
            },
            child: const Text('Подписать'),
          ),
        ],
      ),
    );
  }

  void _nextStep() {
    setState(() {
      if (_loadingStep < 3) {
        _loadingStep++;
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => UnloadingScreen(
                request: widget.request, onArchive: widget.onArchive),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text('Заявка №${widget.request['number']} - Погрузка'),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoCard(
                icon: Icons.location_on,
                title: 'Адрес',
                content: widget.request['loading_address'],
                onTap: () => _openYandexMaps(widget.request['loading_address']),
              ),
              _buildInfoCard(
                icon: Icons.calendar_today,
                title: 'Дата',
                content: widget.request['loading_date'],
              ),
              _buildInfoCard(
                icon: Icons.business,
                title: 'Клиент',
                content: widget.request['loading_company'],
              ),
              _buildInfoCard(
                icon: Icons.door_front_door,
                title: 'Ворота',
                content: widget.request['loading_gates'],
              ),
              _buildInfoCard(
                icon: Icons.access_time,
                title: 'Время',
                content:
                    '${widget.request['loading_time_from']} - ${widget.request['loading_time_to']}',
              ),
              _buildInfoCard(
                icon: Icons.person,
                title: 'Диспетчер',
                content: widget.request['loading_dispatcher'],
              ),
              _buildInfoCard(
                icon: Icons.phone,
                title: 'Телефон диспетчера',
                content: widget.request['loading_dispatcher_phone'],
              ),
              _buildInfoCard(
                icon: Icons.comment,
                title: 'Комментарий',
                content: widget.request['loading_comment'],
              ),
              const SizedBox(height: 24),
              const Text(
                'Фото ТТН',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _ttnPhoto == null
                    ? Center(
                        child: IconButton(
                          icon: const Icon(Icons.camera_alt, size: 48),
                          onPressed: _takePhoto,
                        ),
                      )
                    : Image.file(
                        _ttnPhoto!,
                        fit: BoxFit.cover,
                      ),
              ),
              const SizedBox(height: 24),
              Center(
                child: Column(
                  children: [
                    Text(
                      _stepTitles[_loadingStep],
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _nextStep,
                      icon: const Icon(Icons.check_circle),
                      label: Text(_buttonTitles[_loadingStep]),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(200, 48),
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
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
