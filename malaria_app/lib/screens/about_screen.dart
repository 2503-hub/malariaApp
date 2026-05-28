import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About App')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: const [
            _AboutHeader(),
            SizedBox(height: 16),
            _InfoSection(
              title: 'What is Malaria?',
              body:
                  'Malaria is a life-threatening disease caused by Plasmodium parasites transmitted through infected female Anopheles mosquitoes. Early detection helps patients receive treatment quickly.',
              icon: Icons.coronavirus,
            ),
            _InfoSection(
              title: 'App Purpose',
              body:
                  'This application supports malaria screening by allowing users to upload or capture blood smear images and view a clear prediction result.',
              icon: Icons.assignment_turned_in,
            ),
            _InfoSection(
              title: 'AI/CNN Usage',
              body:
                  'The system is designed to use a convolutional neural network to classify cell images as parasitized or uninfected and display the model confidence.',
              icon: Icons.memory,
            ),
            _InfoSection(
              title: 'Developer Information',
              body:
                  'Developed as a malaria detection project for academic defense. The interface is prepared for screenshots, demonstrations, and future model integration.',
              icon: Icons.school,
            ),
          ],
        ),
      ),
    );
  }
}

class _AboutHeader extends StatelessWidget {
  const _AboutHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFE6FFFB),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        children: [
          Icon(Icons.biotech, color: Color(0xFF087F7A), size: 44),
          SizedBox(width: 14),
          Expanded(
            child: Text(
              'Malaria Detection System',
              style: TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 21,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  final String title;
  final String body;
  final IconData icon;

  const _InfoSection({
    required this.title,
    required this.body,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF087F7A), size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  body,
                  style: const TextStyle(
                    color: Color(0xFF475569),
                    height: 1.45,
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
