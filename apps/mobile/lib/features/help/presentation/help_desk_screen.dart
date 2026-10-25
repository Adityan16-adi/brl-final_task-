import 'package:flutter/material.dart';

import '../../../../core/theme/clay_theme.dart';

class HelpDeskScreen extends StatefulWidget {
  const HelpDeskScreen({super.key});

  @override
  State<HelpDeskScreen> createState() => _HelpDeskScreenState();
}

class _HelpDeskScreenState extends State<HelpDeskScreen> {
  final _searchController = TextEditingController();
  String _search = '';

  final List<Map<String, String>> _faqs = [
    {
      'q': 'How do I join a classroom as a student?',
      'a':
          'From the Classrooms tab or dashboard, tap the Key icon ("Join Classroom with Code"). Enter the unique 6-character code provided by your teacher and tap Join. You will be instantly enrolled.',
    },
    {
      'q': 'How do teachers create classrooms and share join codes?',
      'a':
          'If you are signed in with a Teacher account, tap the "+" icon on the Classrooms tab or dashboard. Fill in the classroom name, subject, room, and weekly schedule. A unique join code will be generated for your students.',
    },
    {
      'q': 'How do I submit an assignment?',
      'a':
          'Navigate to the Assignments tab or the Study Planner / To-Do screen. Select the pending assignment, tap "Submit", enter your text submission or upload/paste a document link, and tap Submit Assignment.',
    },
    {
      'q': 'How do teachers review and grade student submissions?',
      'a':
          'Open the Classroom Detail view and select the assignment. You can inspect all submitted student works, enter marks/points, provide constructive feedback remarks, and finalize grades.',
    },
    {
      'q': 'How does the AI Mentor Assistant work?',
      'a':
          'Tap the AI Mentor icon anywhere in the app to open an interactive conversation with the integrated AI tutor. It answers academic questions, explains difficult concepts step-by-step, and helps with problem solving.',
    },
    {
      'q': 'What should I do if the server connection drops?',
      'a':
          'Open Settings & Preferences and tap "Test Backend Connection". Ensure the backend Node.js server (port 5000) and ML service (port 8001) are active on your local machine or network host.',
    },
  ];

  void _showTicketDialog() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Submit Support Request'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Subject',
                hintText: 'e.g. Issue joining classroom',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Describe the issue or feedback...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: ClayTokens.deepIndigo,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                      'Support ticket submitted successfully! Reference #TKT-8921'),
                  backgroundColor: ClayTokens.mintDark,
                ),
              );
            },
            child: const Text('Submit Ticket'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredFaqs = _faqs.where((f) {
      if (_search.isEmpty) return true;
      return f['q']!.toLowerCase().contains(_search) ||
          f['a']!.toLowerCase().contains(_search);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Help Desk & FAQ'),
        actions: [
          IconButton(
            tooltip: 'Submit Support Ticket',
            icon: const Icon(Icons.support_agent_rounded),
            onPressed: _showTicketDialog,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        children: [
          // Search Bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search help topics and FAQs...',
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              suffixIcon: _search.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _search = '');
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              filled: true,
            ),
            onChanged: (val) => setState(() => _search = val.trim().toLowerCase()),
          ),
          const SizedBox(height: 16),

          // FAQ Accordion
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Text(
              'FREQUENTLY ASKED QUESTIONS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: ClayTokens.secondaryText,
                letterSpacing: 0.8,
              ),
            ),
          ),
          ...filteredFaqs.map((faq) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: ClayCard(
                depth: 3,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                child: ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  title: Text(
                    faq['q']!,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(0, 0, 0, 14),
                      child: Text(
                        faq['a']!,
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color: ClayTokens.secondaryText,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 20),

          // Contact Support Card
          ClayCard(
            depth: 3,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.headset_mic_rounded,
                        color: ClayTokens.deepIndigo, size: 22),
                    SizedBox(width: 10),
                    Text(
                      'Still need help?',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Our virtual learning support team is available 24/7 to resolve technical issues and classroom inquiries.',
                  style: TextStyle(fontSize: 12, height: 1.3),
                ),
                const SizedBox(height: 14),
                ClayButton(
                  isFullWidth: true,
                  icon: Icons.confirmation_number_outlined,
                  onPressed: _showTicketDialog,
                  child: const Text('Open Support Ticket'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
