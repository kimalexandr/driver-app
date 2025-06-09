import 'package:flutter/material.dart';

class DriverProfileScreen extends StatelessWidget {
  const DriverProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Профиль водителя')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: CircleAvatar(
                radius: 50,
                child: Icon(Icons.person, size: 50),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Личные данные',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildInfoCard(
              title: 'ФИО',
              content: 'Иванов Иван Иванович',
              icon: Icons.person,
            ),
            _buildInfoCard(
              title: 'Телефон',
              content: '+7 (999) 123-45-67',
              icon: Icons.phone,
            ),
            const SizedBox(height: 24),
            const Text(
              'Водительское удостоверение',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildInfoCard(
              title: 'Серия и номер',
              content: '77 АА 123456',
              icon: Icons.drive_file_rename_outline,
            ),
            _buildInfoCard(
              title: 'Категории',
              content: 'B, C, D, E',
              icon: Icons.category,
            ),
            _buildInfoCard(
              title: 'Дата выдачи',
              content: '01.01.2020',
              icon: Icons.calendar_today,
            ),
            const SizedBox(height: 24),
            const Text(
              'Паспортные данные',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildInfoCard(
              title: 'Серия и номер',
              content: '1234 567890',
              icon: Icons.credit_card,
            ),
            _buildInfoCard(
              title: 'Дата выдачи',
              content: '01.01.2010',
              icon: Icons.calendar_today,
            ),
            _buildInfoCard(
              title: 'Кем выдан',
              content: 'ОВД Центрального района г. Москвы',
              icon: Icons.location_city,
            ),
            const SizedBox(height: 32),
            Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/phone',
                    (route) => false,
                  );
                },
                icon: const Icon(Icons.logout),
                label: const Text('Выйти'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(180, 48),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required String content,
    required IconData icon,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, size: 24, color: Colors.blue),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    content,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
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
