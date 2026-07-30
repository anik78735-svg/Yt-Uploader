import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'prompt_detail_screen.dart';

class CategoryPromptsScreen extends StatelessWidget {
  final String category;
  const CategoryPromptsScreen({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: Text(category), backgroundColor: Colors.transparent, elevation: 0),
      body: StreamBuilder<DocumentSnapshot>(
        stream: currentUser != null
            ? FirebaseFirestore.instance.collection('users').doc(currentUser.uid).snapshots()
            : const Stream.empty(),
        builder: (context, userSnap) {
          bool isPremiumUser = false;
          if (userSnap.hasData && userSnap.data!.exists) {
            final data = userSnap.data!.data() as Map<String, dynamic>;
            final Timestamp? until = data['premiumUntil'];
            if (until != null && until.toDate().isAfter(DateTime.now())) {
              isPremiumUser = true;
            }
          }

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('prompts')
                .where('category', isEqualTo: category)
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Colors.green));
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text("No prompts in this category yet.", style: TextStyle(color: Colors.grey)));
              }

              final docs = snapshot.data!.docs;

              return GridView.builder(
                padding: const EdgeInsets.all(12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.75,
                ),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  var data = docs[index].data() as Map<String, dynamic>;
                  String imageUrl = data['imageUrl'] ?? '';
                  String promptText = data['prompt'] ?? '';
                  bool isPremiumPrompt = data['isPremium'] == true;
                  bool locked = isPremiumPrompt && !isPremiumUser;

                  return GestureDetector(
                    onTap: () {
                      if (locked) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("🔒 Claim a gift code to unlock premium prompts")),
                        );
                        return;
                      }
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PromptDetailScreen(imageUrl: imageUrl, promptText: promptText, category: category),
                        ),
                      );
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          locked
                              ? ColorFiltered(
                                  colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.55), BlendMode.darken),
                                  child: Image.network(imageUrl, fit: BoxFit.cover),
                                )
                              : Image.network(
                                  imageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Container(
                                    color: Colors.grey[300],
                                    child: const Center(child: Icon(Icons.broken_image, size: 40)),
                                  ),
                                ),
                          if (locked) const Center(child: Icon(Icons.lock, color: Colors.white, size: 32)),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
