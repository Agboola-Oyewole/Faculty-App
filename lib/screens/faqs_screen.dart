import 'package:flutter/material.dart';

class FaqsScreen extends StatelessWidget {
  const FaqsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> faqs = [
      {
        'question': 'How do I sign in?',
        'answer':
            'Go to the Login screen and sign in using your Google account.'
      },
      {
        'question': 'How is my data stored?',
        'answer':
            'Your data is securely stored in Firebase Firestore with encryption and privacy controls.'
      },
      {
        'question': 'How do I mark attendance?',
        'answer':
            'Your location is used to verify attendance. Ensure GPS is turned on and permission is granted.'
      },
      {
        'question': 'How do I access course resources?',
        'answer':
            'Go to the Courses tab. Tap on a course to view or download its available resources.'
      },
      {
        'question': 'What if a course has no resources?',
        'answer':
            'We provide an alternative Google Drive link if no direct resources are available for that course.'
      },
      {
        'question': 'What does the brown checkmark badge mean?',
        'answer':
            'Brown badges represent verified student executives (Excos) within the faculty.'
      },
      {
        'question': 'How does the CGPA calculator work?',
        'answer':
            'Input your course grades for the semester and the app automatically calculates your CGPA.'
      },
      {
        'question': 'Can I use this app on iPhone?',
        'answer':
            'Yes! Open the app in Safari, then tap “Add to Home Screen” to install it like a native app.'
      },
      {
        'question': 'How do I update my profile?',
        'answer':
            'Go to the Profile tab and tap “Edit Info” to make changes to your details.'
      },
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text('FAQ',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: faqs.length,
        separatorBuilder: (_, __) => Divider(),
        itemBuilder: (context, index) {
          final faq = faqs[index];
          return ExpansionTile(
            title: Text(
              faq['question']!,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                child: Text(
                  faq['answer']!,
                  style: TextStyle(fontSize: 14, color: Colors.grey[800]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
