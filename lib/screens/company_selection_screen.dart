import 'package:flutter/material.dart';
import 'requests_screen.dart';

class CompanySelectionScreen extends StatefulWidget {
  const CompanySelectionScreen({super.key});

  @override
  State<CompanySelectionScreen> createState() => _CompanySelectionScreenState();
}

class _CompanySelectionScreenState extends State<CompanySelectionScreen> {
  String? _selectedCompany;

  final List<String> _companies = [
    'Компания 1',
    'Компания 2',
    'Компания 3',
    'Компания 4',
    'Компания 5',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Выбор компании')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Выберите вашу компанию:',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ...List.generate(
              _companies.length,
              (index) => RadioListTile<String>(
                title: Text(_companies[index]),
                value: _companies[index],
                groupValue: _selectedCompany,
                onChanged: (String? value) {
                  setState(() {
                    _selectedCompany = value;
                  });
                },
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed:
                  _selectedCompany == null
                      ? null
                      : () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => RequestsScreen(
                                  companyName: _selectedCompany!,
                                ),
                          ),
                        );
                      },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('Подтвердить'),
            ),
          ],
        ),
      ),
    );
  }
}
