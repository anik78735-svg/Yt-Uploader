import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/categories.dart';
import 'prompt_detail_screen.dart';
import 'video_preview_screen.dart';
import '../utils/video_helper.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _contentType = "image"; // image | ads | video
  String _selectedCategory = "All";
  String _searchQuery = "";

  void _openCategoryPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        final cats = promptCategories;
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Select Category", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Expanded(
                    child: GridView.builder(
                      controller: scrollController,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 2.6,
                      ),
                      itemCount: cats.length,
                      itemBuilder: (context, index) {
                        final cat = cats[index];
                        return InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () {
                            setState(() {
                              _contentType = "image";
                              _selectedCategory = cat;
                            });
                            Navigator.pop(context);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: cat == _selectedCategory ? Colors.green : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              cat,
                              style: TextStyle(
                                color: cat == _selectedCategory ? Colors.white : Colors.black87,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _typeChip(String label, IconData icon, VoidCallback onTap, bool selected) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 16, color: selected ? Colors.white : null), const SizedBox(width: 4), Text(label)]),
        selected: selected,
        selectedColor: Colors.green,
        labelStyle: TextStyle(color: selected ? Colors.white : null, fontWeight: FontWeight.w600),
        onSelected: (_) => onTap(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("🔥 10,000+ Viral Image", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            TextField(
              onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
              decoration: InputDecoration(
                hintText: "Search prompts..",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Theme.of(context).cardColor,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 10),

            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _typeChip("All", Icons.grid_view, () {
                    setState(() { _contentType = "image"; _selectedCategory = "All"; });
                    _openCategoryPicker();
                  }, _contentType == "image"),
                  _typeChip("Ads", Icons.campaign_outlined, () => setState(() => _contentType = "ads"), _contentType == "ads"),
                  _typeChip("Video", Icons.videocam_outlined, () => setState(() => _contentType = "video"), _contentType == "video"),
                  ...promptCategories.where((c) => c != "All").map((cat) => _typeChip(
                        cat,
                        Icons.label_outline,
                        () => setState(() { _contentType = "image"; _selectedCategory = cat; }),
                        _contentType == "image" && _selectedCategory == cat,
                      )),
                ],
              ),
            ),
            const SizedBox(height: 10),

            Expanded(
              child: StreamBuilder<DocumentSnapshot>(
                stream: currentUser != null
                    ? FirebaseFirestore.instance.collection('users').doc(currentUser.uid).snapshots()
                    : const Stream.empty(),
                builder: (context, userSnap) {
                  bool isPremiumUser = false;
                  if (userSnap.hasData && userSnap.data!.exists) {
                    final data = userSnap.data!.data() as Map<String, dynamic>;
                    final Timestamp? until = data['premiumUntil'];
                    if (until != null && until.toDate().isAfter(DateTime.now())) isPremiumUser = true;
                  }

                  return StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('prompts').orderBy('createdAt', descending: true).snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator(color: Colors.green));
                      }
                      if (!snapshot.hasData) return const SizedBox();

                      final docs = snapshot.data!.docs.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final String type = data['type'] ?? 'image';
                        if (type != _contentType) return false;

                        if (_contentType != "ads" && _selectedCategory != "All") {
                          if ((data['category'] ?? '') != _selectedCategory) return false;
                        }

                        if (_searchQuery.isNotEmpty) {
                          return (data['prompt'] ?? '').toString().toLowerCase().contains(_searchQuery);
                        }
                        return true;
                      }).toList();

                      if (docs.isEmpty) {
                        return Center(child: Text("No ${_contentType == 'image' ? 'prompts' : _contentType} available.", style: const TextStyle(color: Colors.grey)));
                      }

                      return GridView.builder(
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
                          String videoUrl = data['videoUrl'] ?? '';
                          String promptText = data['prompt'] ?? '';
                          String category = data['category'] ?? 'General';
                          bool isPremiumPrompt = data['isPremium'] == true;
                          bool locked = isPremiumPrompt && !isPremiumUser;

                          if (_contentType == "video") {
                            final thumbUrl = getVideoThumbnail(videoUrl);
                            return GestureDetector(
                              onTap: () {
                                if (locked) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("🔒 Claim a gift code to unlock premium videos")),
                                  );
                                  return;
                                }
                                Navigator.push(context, MaterialPageRoute(
                                  builder: (context) => VideoPreviewScreen(
                                    videoUrl: videoUrl,
                                    caption: promptText,
                                    category: category,
                                  ),
                                ));
                              },
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    locked
                                        ? ColorFiltered(
                                            colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.55), BlendMode.darken),
                                            child: Image.network(
                                              thumbUrl,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) => Container(
                                                decoration: const BoxDecoration(
                                                  gradient: LinearGradient(colors: [Color(0xFF0EA472), Color(0xFF065F46)]),
                                                ),
                                              ),
                                            ),
                                          )
                                        : Image.network(
                                            thumbUrl,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) => Container(
                                              decoration: const BoxDecoration(
                                                gradient: LinearGradient(colors: [Color(0xFF0EA472), Color(0xFF065F46)]),
                                              ),
                                            ),
                                          ),
                                    if (!locked) Container(color: Colors.black.withOpacity(0.15)),
                                    Center(
                                      child: Icon(
                                        locked ? Icons.lock : Icons.play_circle_fill,
                                        color: Colors.white,
                                        size: locked ? 32 : 48,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }

                          return GestureDetector(
                            onTap: () {
                              if (locked) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("🔒 Claim a gift code to unlock premium prompts")),
                                );
                                return;
                              }
                              Navigator.push(context, MaterialPageRoute(
                                builder: (context) => PromptDetailScreen(imageUrl: imageUrl, promptText: promptText, category: category),
                              ));
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
            ),
          ],
        ),
      ),
    );
  }
}