import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../data/categories.dart';
import '../utils/video_helper.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Admin Dashboard"), backgroundColor: Colors.redAccent, centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: FutureBuilder<AggregateQuerySnapshot>(
                    future: _firestore.collection('users').count().get(),
                    builder: (context, snap) => _StatCard(icon: Icons.people_alt, label: "Total Users", value: snap.hasData ? "${snap.data!.count}" : "-", color: Colors.blue),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FutureBuilder<AggregateQuerySnapshot>(
                    future: _firestore.collection('prompts').count().get(),
                    builder: (context, snap) => _StatCard(icon: Icons.image, label: "Total Prompts", value: snap.hasData ? "${snap.data!.count}" : "-", color: Colors.green),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text("Quick Actions", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, minimumSize: const Size(double.infinity, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text("Add New Prompt", style: TextStyle(color: Colors.white, fontSize: 16)),
              onPressed: () => showDialog(context: context, barrierDismissible: false, builder: (_) => const AddPromptDialog()),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.amber.shade800, minimumSize: const Size(double.infinity, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              icon: const Icon(Icons.card_giftcard, color: Colors.white),
              label: const Text("Generate Gift Code", style: TextStyle(color: Colors.white, fontSize: 16)),
              onPressed: () => _showGenerateGiftDialog(context),
            ),
            const SizedBox(height: 20),
            const Text("Manage Prompts", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore.collection('prompts').orderBy('createdAt', descending: true).snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text("No Prompts Added Yet"));
                  final docs = snapshot.data!.docs;
                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      var data = docs[index].data() as Map<String, dynamic>;
                      String docId = docs[index].id;
                      bool isPremium = data['isPremium'] == true;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Image.network(
                                  (data['type'] == 'video') ? getVideoThumbnail(data['videoUrl'] ?? '') : (data['imageUrl'] ?? ''),
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Icon(data['type'] == 'video' ? Icons.videocam : Icons.image),
                                ),
                              ),
                              if (isPremium) const Positioned(top: 0, right: 0, child: Icon(Icons.lock, size: 14, color: Colors.amber)),
                              if (data['type'] == 'video') const Positioned(bottom: 0, right: 0, child: Icon(Icons.play_circle, size: 16, color: Colors.white)),
                            ],
                          ),
                          title: Text(data['category'] ?? 'General', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(data['prompt'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
                          trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () async => await _firestore.collection('prompts').doc(docId).delete()),
                        ),
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

  void _showGenerateGiftDialog(BuildContext context) {
    final TextEditingController daysController = TextEditingController(text: "30");
    showDialog(
      context: context,
      builder: (dialogContext) {
        bool isGenerating = false;
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Generate Gift Code"),
              content: TextField(
                controller: daysController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Premium Days (e.g. 30)", border: OutlineInputBorder()),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text("Cancel")),
                isGenerating
                    ? const Padding(padding: EdgeInsets.all(8.0), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
                    : ElevatedButton(
                        onPressed: () async {
                          setState(() => isGenerating = true);
                          try {
                            final int days = int.tryParse(daysController.text.trim()) ?? 30;
                            final String code = _generateCode();
                            await _firestore.collection('gifts').doc(code).set({
                              'code': code,
                              'premiumDays': days,
                              'used': false,
                              'usedBy': null,
                              'createdAt': FieldValue.serverTimestamp(),
                            });
                            if (dialogContext.mounted) {
                              Navigator.pop(dialogContext);
                              _showGeneratedCodeDialog(context, code);
                            }
                          } catch (e) {
                            setState(() => isGenerating = false);
                            if (dialogContext.mounted) {
                              ScaffoldMessenger.of(dialogContext).showSnackBar(
                                SnackBar(content: Text("Failed: $e")),
                              );
                            }
                          }
                        },
                        child: const Text("Generate"),
                      ),
              ],
            );
          },
        );
      },
    );
  }

  void _showGeneratedCodeDialog(BuildContext context, String code) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("🎁 Gift Code Ready"),
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(code, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 2)),
            IconButton(
              icon: const Icon(Icons.copy, color: Colors.green),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: code));
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Code copied!")));
              },
            ),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("Done"))],
      ),
    );
  }

  String _generateCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rand = Random.secure();
    final code = List.generate(8, (_) => chars[rand.nextInt(chars.length)]).join();
    return "PV$code";
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _StatCard({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }
}

// Represents one item inside a bulk upload batch — its own file + own prompt text
class _BulkItem {
  final File file;
  final TextEditingController promptController = TextEditingController();
  _BulkItem(this.file);
}

class AddPromptDialog extends StatefulWidget {
  const AddPromptDialog({super.key});

  @override
  State<AddPromptDialog> createState() => _AddPromptDialogState();
}

class _AddPromptDialogState extends State<AddPromptDialog> {
  final String cloudName = "promtverse";
  final String uploadPreset = "my_upload_preset";

  final TextEditingController _promptController = TextEditingController();
  final TextEditingController _imageUrlController = TextEditingController();

  String _contentType = "image"; // image | video | ads
  String _selectedCategory = promptCategories.firstWhere((c) => c != "All");
  bool _isPremium = false;
  File? _selectedImageFile;
  File? _selectedVideoFile;
  final TextEditingController _adLinkController = TextEditingController();
  bool _isUploading = false;
  String _statusText = "";
  final ImagePicker _picker = ImagePicker();

  // ---- Bulk upload state ----
  bool _bulkMode = false;
  final List<_BulkItem> _bulkItems = [];
  int _bulkDoneCount = 0;

  Future<void> _pickBulkImages() async {
    final List<XFile> picked = await _picker.pickMultiImage(imageQuality: 65);
    if (picked.isEmpty) return;
    setState(() {
      _bulkItems.addAll(picked.map((x) => _BulkItem(File(x.path))));
    });
  }

  // Native picker has no multi-video select, so user adds videos one by one
  Future<void> _addBulkVideo() async {
    final XFile? pickedFile = await _picker.pickVideo(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _bulkItems.add(_BulkItem(File(pickedFile.path))));
    }
  }

  void _removeBulkItem(int index) {
    setState(() => _bulkItems.removeAt(index));
  }

  Future<void> _uploadBulkAndSave() async {
    if (_bulkItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_contentType == "video" ? "Please add at least one video" : "Please pick at least one image")),
      );
      return;
    }

    setState(() { _isUploading = true; _bulkDoneCount = 0; _statusText = "Uploading 0/${_bulkItems.length}..."; });

    int successCount = 0;
    for (final item in _bulkItems) {
      try {
        String? url;
        if (_contentType == "video") {
          url = await _uploadVideoToCloudinary(item.file);
        } else {
          url = await _uploadToCloudinary(item.file);
        }
        if (url == null) continue;

        final Map<String, dynamic> docData = {
          'prompt': item.promptController.text.trim(),
          'type': _contentType,
          'category': _selectedCategory,
          'isPremium': _isPremium,
          'createdAt': FieldValue.serverTimestamp(),
        };
        if (_contentType == "video") {
          docData['videoUrl'] = url;
        } else {
          docData['imageUrl'] = url;
          if (_contentType == "ads") {
            docData['adLink'] = _adLinkController.text.trim();
          }
        }

        await FirebaseFirestore.instance.collection('prompts').add(docData);
        successCount++;
      } catch (e) {
        debugPrint("Bulk item failed: $e");
        // ek item fail hone se poora batch nahi rukta, aage badhte hain
      } finally {
        _bulkDoneCount++;
        if (mounted) setState(() => _statusText = "Uploading $_bulkDoneCount/${_bulkItems.length}...");
      }
    }

    await _sendPushNotification(_selectedCategory, _isPremium);

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("$successCount of ${_bulkItems.length} uploaded successfully!")),
      );
    }
    if (mounted) setState(() => _isUploading = false);
  }
  // ---- End bulk upload state ----

  Future<void> _pickVideo() async {
    final XFile? pickedFile = await _picker.pickVideo(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _selectedVideoFile = File(pickedFile.path));
    }
  }

  Future<String?> _uploadVideoToCloudinary(File videoFile) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/video/upload'));
      request.fields['upload_preset'] = uploadPreset;
      request.files.add(await http.MultipartFile.fromPath('file', videoFile.path));

      var response = await request.send().timeout(
        const Duration(seconds: 90),
        onTimeout: () => throw TimeoutException("Video upload timeout"),
      );
      var responseData = await response.stream.toBytes();
      var responseString = String.fromCharCodes(responseData);
      var jsonMap = jsonDecode(responseString);

      if (response.statusCode == 200) {
        return jsonMap['secure_url'];
      } else {
        throw Exception(jsonMap['error']?['message'] ?? 'Video upload failed');
      }
    } catch (e) {
      throw Exception("Video upload error: $e");
    }
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 65,
      maxWidth: 1280,
    );
    if (pickedFile != null) {
      setState(() {
        _selectedImageFile = File(pickedFile.path);
        _imageUrlController.clear();
      });
    }
  }

  Future<String?> _uploadToCloudinary(File imageFile) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload'));
      request.fields['upload_preset'] = uploadPreset;
      request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));

      var response = await request.send().timeout(
        const Duration(seconds: 40),
        onTimeout: () => throw TimeoutException("Upload timeout — check internet or Cloudinary settings"),
      );

      var responseData = await response.stream.toBytes();
      var responseString = String.fromCharCodes(responseData);
      var jsonMap = jsonDecode(responseString);

      if (response.statusCode == 200) {
        return jsonMap['secure_url'];
      } else {
        throw Exception(jsonMap['error']?['message'] ?? 'Upload failed (${response.statusCode})');
      }
    } on TimeoutException {
      rethrow;
    } catch (e) {
      throw Exception("Upload error: $e");
    }
  }


  static const String _oneSignalRestApiKey = "os_v2_app_atpzkm5i3nh7loaiwv3iiuuha4wazwnicyeeqofhsb5rrhgghyn77glzpt5p55k7vodlhm2d4le74wlkpcpm2fcqbcz65fkrqqs3dua";
  static const String _oneSignalAppId = "04df9533-a8db-4ff5-b808-b57684528707";

  Future<void> _sendPushNotification(String category, bool isPremium) async {
    try {
      final url = Uri.parse("https://onesignal.com/api/v1/notifications");
      final body = jsonEncode({
        "app_id": _oneSignalAppId,
        "included_segments": ["Subscribed Users"],
        "headings": {"en": "🔥 New Prompt Added!"},
        "contents": {
          "en": isPremium
              ? "A new premium \$category prompt just dropped — check it out!"
              : "A new \$category prompt is now live in PromptVerse!"
        },
      });

      await http.post(
        url,
        headers: {
          "Content-Type": "application/json; charset=utf-8",
          "Authorization": "Basic \$_oneSignalRestApiKey",
        },
        body: body,
      );
    } catch (e) {
      debugPrint("Push notification error: \$e");
    }
  }

  Future<void> _uploadAndSave() async {
    String promptText = _promptController.text.trim();
    String finalImageUrl = _imageUrlController.text.trim();

    if (_contentType == "video") {
      if (_selectedVideoFile == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please pick a video")));
        return;
      }
      setState(() { _isUploading = true; _statusText = "Uploading video... this may take a while"; });
      try {
        final videoUrl = await _uploadVideoToCloudinary(_selectedVideoFile!);
        await FirebaseFirestore.instance.collection('prompts').add({
          'videoUrl': videoUrl,
          'prompt': promptText,
          'type': 'video',
          'category': _selectedCategory,
          'isPremium': _isPremium,
          'createdAt': FieldValue.serverTimestamp(),
        });
        await _sendPushNotification(_selectedCategory, _isPremium);
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Video Added Successfully!")));
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$e")));
      } finally {
        if (mounted) setState(() => _isUploading = false);
      }
      return;
    }

    if (promptText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter prompt text")));
      return;
    }
    if (_selectedImageFile == null && finalImageUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please pick an image or enter an Image URL")));
      return;
    }

    setState(() { _isUploading = true; _statusText = "Uploading image..."; });

    try {
      if (_selectedImageFile != null) {
        finalImageUrl = (await _uploadToCloudinary(_selectedImageFile!)) ?? finalImageUrl;
      }

      setState(() => _statusText = "Saving to database...");

      final Map<String, dynamic> docData = {
        'imageUrl': finalImageUrl,
        'prompt': promptText,
        'type': _contentType,
        'createdAt': FieldValue.serverTimestamp(),
      };

      if (_contentType == "image") {
        docData['category'] = _selectedCategory;
        docData['isPremium'] = _isPremium;
      } else if (_contentType == "ads") {
        docData['adLink'] = _adLinkController.text.trim();
      }

      await FirebaseFirestore.instance.collection('prompts').add(docData);

      await _sendPushNotification(_contentType == "image" ? _selectedCategory : "Ads", _isPremium);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Added Successfully!")));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$e")));
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Widget _buildBulkUI() {
    final bool isVideoType = _contentType == "video";
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Shared settings for the whole batch
        DropdownButtonFormField<String>(
          value: _selectedCategory,
          isExpanded: true,
          decoration: const InputDecoration(labelText: "Category (applies to all)", border: OutlineInputBorder()),
          items: promptCategories.where((c) => c != "All").map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
          onChanged: (val) => setState(() => _selectedCategory = val ?? _selectedCategory),
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          activeColor: Colors.amber.shade800,
          title: const Text("Premium (Locked)", style: TextStyle(fontWeight: FontWeight.w600)),
          subtitle: const Text("Applies to all items in this batch", style: TextStyle(fontSize: 12)),
          value: _isPremium,
          onChanged: (val) => setState(() => _isPremium = val),
        ),
        if (_contentType == "ads") ...[
          const SizedBox(height: 8),
          TextField(controller: _adLinkController, decoration: const InputDecoration(labelText: "Ad Link (applies to all, optional)", border: OutlineInputBorder())),
        ],
        const SizedBox(height: 14),

        // Pick button
        OutlinedButton.icon(
          onPressed: _isUploading ? null : (isVideoType ? _addBulkVideo : _pickBulkImages),
          icon: Icon(isVideoType ? Icons.video_call_outlined : Icons.add_photo_alternate),
          label: Text(isVideoType ? "Add Video (one at a time)" : "Pick Images (multi-select, 10-50)"),
        ),
        const SizedBox(height: 10),

        Text("${_bulkItems.length} item(s) added", style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),

        // List of picked items, each with its own prompt field
        ...List.generate(_bulkItems.length, (index) {
          final item = _bulkItems[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: isVideoType
                        ? Container(
                            width: 60,
                            height: 60,
                            color: Colors.grey[300],
                            child: const Icon(Icons.videocam, color: Colors.grey),
                          )
                        : Image.file(item.file, width: 60, height: 60, fit: BoxFit.cover),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: item.promptController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: "Prompt for item ${index + 1} (optional)",
                        border: const OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
                    onPressed: _isUploading ? null : () => _removeBulkItem(index),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Add New Prompt"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(label: const Text("Image"), selected: _contentType == "image", onSelected: (_) => setState(() => _contentType = "image")),
                ChoiceChip(label: const Text("Video"), selected: _contentType == "video", onSelected: (_) => setState(() => _contentType = "video")),
                ChoiceChip(label: const Text("Ad"), selected: _contentType == "ads", onSelected: (_) => setState(() => _contentType = "ads")),
              ],
            ),
            const SizedBox(height: 10),
            // Single vs Bulk mode toggle — same for Image, Video, and Ads
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text("Single"), icon: Icon(Icons.filter_1)),
                ButtonSegment(value: true, label: Text("Bulk (10-50)"), icon: Icon(Icons.filter_9_plus)),
              ],
              selected: {_bulkMode},
              onSelectionChanged: _isUploading ? null : (val) => setState(() => _bulkMode = val.first),
            ),
            const SizedBox(height: 12),

            if (_bulkMode) ...[
              _buildBulkUI(),
            ] else if (_contentType == "video") ...[
              GestureDetector(
                onTap: _isUploading ? null : _pickVideo,
                child: Container(
                  height: 140,
                  width: double.infinity,
                  decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey)),
                  child: _selectedVideoFile != null
                      ? Stack(
                          fit: StackFit.expand,
                          children: [
                            const Center(child: Icon(Icons.videocam, color: Colors.grey, size: 40)),
                            const Positioned(
                              bottom: 8,
                              right: 8,
                              child: Icon(Icons.check_circle, color: Colors.green, size: 24),
                            ),
                          ],
                        )
                      : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.video_call_outlined, size: 40, color: Colors.grey),
                            SizedBox(height: 5),
                            Text("Tap to Pick Video from Gallery", style: TextStyle(color: Colors.grey, fontSize: 12)),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 12),
              // Prompt text ab required hai — video ke liye bhi Gemini prompt copy chahiye
              TextField(
                controller: _promptController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: "Prompt (shown & copyable on detail screen)", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              // Category selector — ab video bhi categorize hoga
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                isExpanded: true,
                decoration: const InputDecoration(labelText: "Category", border: OutlineInputBorder()),
                items: promptCategories.where((c) => c != "All").map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (val) => setState(() => _selectedCategory = val ?? _selectedCategory),
              ),
              const SizedBox(height: 8),
              // Lock/Premium toggle — ab video bhi lock ho sakta hai
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeColor: Colors.amber.shade800,
                title: const Text("Premium (Locked)", style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text("Only unlocked users can view", style: TextStyle(fontSize: 12)),
                value: _isPremium,
                onChanged: (val) => setState(() => _isPremium = val),
              ),
            ] else ...[
              GestureDetector(
                onTap: _isUploading ? null : _pickImage,
                child: Container(
                  height: 140,
                  width: double.infinity,
                  decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey)),
                  child: _selectedImageFile != null
                      ? ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.file(_selectedImageFile!, fit: BoxFit.cover))
                      : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate, size: 40, color: Colors.grey),
                            SizedBox(height: 5),
                            Text("Tap to Pick Image from Gallery", style: TextStyle(color: Colors.grey, fontSize: 12)),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 10),
              const Text("OR", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 10),
              TextField(controller: _imageUrlController, decoration: const InputDecoration(labelText: "Image URL (Optional)", border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: _promptController, maxLines: 3, decoration: const InputDecoration(labelText: "Prompt Description", border: OutlineInputBorder())),
              const SizedBox(height: 12),
              if (_contentType == "image") ...[
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: "Category", border: OutlineInputBorder()),
                  items: promptCategories.where((c) => c != "All").map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (val) => setState(() => _selectedCategory = val ?? _selectedCategory),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  activeColor: Colors.amber.shade800,
                  title: const Text("Premium (Locked)", style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text("Only unlocked users can view", style: TextStyle(fontSize: 12)),
                  value: _isPremium,
                  onChanged: (val) => setState(() => _isPremium = val),
                ),
              ],
              if (_contentType == "ads")
                TextField(controller: _adLinkController, decoration: const InputDecoration(labelText: "Ad Link (Optional)", border: OutlineInputBorder())),
            ],
          ],
        ),
      ),
      actions: [
        if (!_isUploading) TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
        if (_isUploading)
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 6),
              Text(_statusText, style: const TextStyle(fontSize: 12)),
            ],
          )
        else
          ElevatedButton(
            onPressed: _bulkMode ? _uploadBulkAndSave : _uploadAndSave,
            child: Text(_bulkMode ? "Upload & Save All (${_bulkItems.length})" : "Upload & Save"),
          ),
      ],
    );
  }
}