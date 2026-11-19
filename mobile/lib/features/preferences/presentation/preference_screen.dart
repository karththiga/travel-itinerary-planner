import 'package:flutter/material.dart';

class PreferenceScreen extends StatefulWidget {
  const PreferenceScreen({super.key});

  @override
  State<PreferenceScreen> createState() => _PreferenceScreenState();
}

class _PreferenceScreenState extends State<PreferenceScreen> {
  final List<String> interests = [
    'History',
    'Culture',
    'Nature',
    'Beach',
    'Wildlife',
    'Adventure',
    'Food',
    'Religious',
  ];

  final Set<String> selectedInterests = {};

  int tripDays = 1;

  final TextEditingController budgetController = TextEditingController();

  String? selectedGroupType;

  final List<String> groupTypes = [
    'Solo',
    'Couple',
    'Family',
    'Friends',
  ];

  String? selectedTransport;

  final List<String> transportOptions = [
    'Car',
    'Public Transport',
    'Motorbike',
    'Walking',
  ];

  @override
  void dispose() {
    budgetController.dispose();
    super.dispose();
  }

  void _generateItinerary() {
    // Validate interests
    if (selectedInterests.isEmpty) {
      _showMessage('Please select at least one interest.');
      return;
    }

    // Validate budget
    if (budgetController.text.trim().isEmpty) {
      _showMessage('Please enter your trip budget.');
      return;
    }

    final double? budget =
        double.tryParse(budgetController.text.trim());

    if (budget == null || budget <= 0) {
      _showMessage('Please enter a valid budget.');
      return;
    }

    // Validate group type
    if (selectedGroupType == null) {
      _showMessage('Please select who you are travelling with.');
      return;
    }

    // Validate transport
    if (selectedTransport == null) {
      _showMessage('Please select your preferred transport.');
      return;
    }

    // Show collected preference data
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Travel Preferences'),
          content: Text(
            'Interests: ${selectedInterests.join(', ')}\n\n'
            'Trip Days: $tripDays\n\n'
            'Budget: LKR ${budget.toStringAsFixed(2)}\n\n'
            'Group Type: $selectedGroupType\n\n'
            'Transport: $selectedTransport',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Travel Preferences'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tell us about your travel preferences',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 24),

            // Interests
            const Text(
              'What are you interested in?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 12),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: interests.map((interest) {
                final bool isSelected =
                    selectedInterests.contains(interest);

                return FilterChip(
                  label: Text(interest),
                  selected: isSelected,
                  onSelected: (bool selected) {
                    setState(() {
                      if (selected) {
                        selectedInterests.add(interest);
                      } else {
                        selectedInterests.remove(interest);
                      }
                    });
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: 30),

            // Trip duration
            const Text(
              'How many days is your trip?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                IconButton(
                  onPressed: tripDays > 1
                      ? () {
                          setState(() {
                            tripDays--;
                          });
                        }
                      : null,
                  icon: const Icon(
                    Icons.remove_circle_outline,
                  ),
                ),

                Text(
                  '$tripDays ${tripDays == 1 ? 'Day' : 'Days'}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                IconButton(
                  onPressed: () {
                    setState(() {
                      tripDays++;
                    });
                  },
                  icon: const Icon(
                    Icons.add_circle_outline,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            // Budget
            const Text(
              'What is your total trip budget?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: budgetController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Budget',
                hintText: 'Example: 50000',
                prefixText: 'LKR ',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 30),

            // Group type
            const Text(
              'Who are you travelling with?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 12),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: groupTypes.map((groupType) {
                return ChoiceChip(
                  label: Text(groupType),
                  selected: selectedGroupType == groupType,
                  onSelected: (bool selected) {
                    setState(() {
                      if (selected) {
                        selectedGroupType = groupType;
                      } else {
                        selectedGroupType = null;
                      }
                    });
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: 30),

            // Transport
            const Text(
              'How do you prefer to travel?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 12),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: transportOptions.map((transport) {
                return ChoiceChip(
                  label: Text(transport),
                  selected: selectedTransport == transport,
                  onSelected: (bool selected) {
                    setState(() {
                      if (selected) {
                        selectedTransport = transport;
                      } else {
                        selectedTransport = null;
                      }
                    });
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: 30),

            // Generate itinerary button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _generateItinerary,
                child: const Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: 14,
                  ),
                  child: Text(
                    'Generate Itinerary',
                    style: TextStyle(
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}