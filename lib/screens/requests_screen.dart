import 'package:flutter/material.dart';
import 'driver_profile_screen.dart';
import 'request_details_screen.dart';

class RequestsScreen extends StatefulWidget {
  final String companyName;

  const RequestsScreen({
    super.key,
    required this.companyName,
  });

  @override
  State<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends State<RequestsScreen> {
  List<Map<String, dynamic>> activeRequests = [
    {
      'number': '001',
      'loading_city': 'Москва',
      'loading_date': '15.03.2024',
      'loading_time': '10:00',
      'unloading_city': 'Санкт-Петербург',
      'unloading_date': '16.03.2024',
      'unloading_time': '14:00',
      'loading_address': 'г. Москва, ул. Ленина, д. 1',
      'loading_company': 'ООО "Грузовик"',
      'loading_weight': 1000,
      'loading_volume': 5,
      'loading_comment': 'Вход со стороны двора',
      'loading_gates': 'Ворота №1',
      'loading_time_from': '09:00',
      'loading_time_to': '11:00',
      'loading_dispatcher': 'Иванов Иван Иванович',
      'loading_dispatcher_phone': '+7 (999) 123-45-67',
      'unloading_address': 'г. Санкт-Петербург, пр. Невский, д. 1',
      'unloading_company': 'ООО "Получатель"',
      'unloading_weight': 1000,
      'unloading_volume': 5,
      'unloading_comment': 'Разгрузка на складе №2',
    },
    {
      'number': '002',
      'loading_city': 'Казань',
      'loading_date': '17.03.2024',
      'loading_time': '09:00',
      'unloading_city': 'Екатеринбург',
      'unloading_date': '18.03.2024',
      'unloading_time': '15:00',
      'loading_address': 'г. Казань, ул. Баумана, д. 1',
      'loading_company': 'ООО "Грузовик"',
      'loading_weight': 2000,
      'loading_volume': 8,
      'loading_comment': 'Погрузка на складе №1',
      'loading_gates': 'Ворота №2',
      'loading_time_from': '08:00',
      'loading_time_to': '10:00',
      'loading_dispatcher': 'Петров Петр Петрович',
      'loading_dispatcher_phone': '+7 (999) 765-43-21',
      'unloading_address': 'г. Екатеринбург, ул. Ленина, д. 1',
      'unloading_company': 'ООО "Получатель"',
      'unloading_weight': 2000,
      'unloading_volume': 8,
      'unloading_comment': 'Вход через главные ворота',
    },
  ];
  List<Map<String, dynamic>> archivedRequests = [];

  int _tabIndex = 0;

  void archiveRequest(Map<String, dynamic> request) {
    setState(() {
      activeRequests.removeWhere((r) => r['number'] == request['number']);
      archivedRequests.add({...request, 'status': 'Завершена'});
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      initialIndex: _tabIndex,
      child: SafeArea(
        child: Scaffold(
          appBar: AppBar(
            title: Text(widget.companyName),
            actions: [
              IconButton(
                icon: const Icon(Icons.person),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DriverProfileScreen(),
                    ),
                  );
                },
              ),
            ],
            bottom: TabBar(
              onTap: (index) => setState(() => _tabIndex = index),
              tabs: const [
                Tab(text: 'Активные'),
                Tab(text: 'Архивные'),
              ],
            ),
          ),
          body: TabBarView(
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildRequestsList(activeRequests, false),
              _buildRequestsList(archivedRequests, true),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRequestsList(
      List<Map<String, dynamic>> requests, bool isArchive) {
    if (requests.isEmpty) {
      return const Center(child: Text('Нет заявок'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: requests.length,
      itemBuilder: (context, index) {
        final request = requests[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: InkWell(
            onTap: isArchive
                ? null
                : () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RequestDetailsScreen(
                            request: request, onArchive: archiveRequest),
                      ),
                    );
                    if (result == 'archived') setState(() {});
                  },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Заявка №${request['number']}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (isArchive)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text('Статус: ${request['status'] ?? 'Завершена'}',
                          style: const TextStyle(color: Colors.green)),
                    ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          request['loading_city'],
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const Icon(Icons.arrow_forward, color: Colors.blue),
                      Expanded(
                        child: Text(
                          request['unloading_city'],
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.end,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${request['loading_date']} ${request['loading_time']}',
                        style: const TextStyle(color: Colors.grey),
                      ),
                      Text(
                        '${request['unloading_date']} ${request['unloading_time']}',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
