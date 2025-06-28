import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import '../pages/Profile.dart';
import '../login.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  bool showForm = false;
  final TextEditingController _postController = TextEditingController();
  File? _pickedImage;
  final Map<String, TextEditingController> _commentControllers = {};

  void toggleLike(String postId, List<String> likedBy) async {
    final currentUserEmail = FirebaseAuth.instance.currentUser!.email;
    final postRef = FirebaseFirestore.instance.collection('posts').doc(postId);

    if (likedBy.contains(currentUserEmail)) {
      await postRef.update({
        'likedBy': FieldValue.arrayRemove([currentUserEmail]),
      });
    } else {
      await postRef.update({
        'likedBy': FieldValue.arrayUnion([currentUserEmail]),
      });
    }
  }

  Future<String> uploadImageToImgbb(File imageFile) async {
    final apiKey = "b051efdbdbd2cdcbd51b7050a1be35ad";
    final url = Uri.parse("https://api.imgbb.com/1/upload?key=$apiKey");

    final base64Image = base64Encode(imageFile.readAsBytesSync());
    final response = await http.post(url, body: {"image": base64Image});

    final responseData = json.decode(response.body);

    if (response.statusCode == 200 && responseData["status"] == 200) {
      return responseData["data"]["url"];
    } else {
      throw Exception("Failed to upload image to ImgBB");
    }
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      setState(() {
        _pickedImage = File(picked.path);
      });
    }
  }

  Future<void> addPost() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (_postController.text.trim().isEmpty || currentUser == null) return;

    String imageUrl = '';

    try {
      if (_pickedImage != null) {
        imageUrl = await uploadImageToImgbb(_pickedImage!);
      }

      await FirebaseFirestore.instance.collection("posts").add({
        "text": _postController.text.trim(),
        "imageUrl": imageUrl,
        "userEmail": currentUser.email,
        "displayName": currentUser.email!.split("@")[0],
        "timestamp": FieldValue.serverTimestamp(),
        "likedBy": [],
        "commentCount": 0,
      });

      setState(() {
        showForm = false;
        _postController.clear();
        _pickedImage = null;
      });
    } catch (e) {
      print(" Error while adding post: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Something went wrong while posting")),
      );
    }
  }

  void showSearchDelegate() {
    showSearch(
      context: context,
      delegate: PostSearchDelegate(onToggleLike: toggleLike),
    );
  }

  Future<void> addComment(String postId) async {
    final commentText = _commentControllers[postId]?.text.trim();
    if (commentText == null || commentText.isEmpty) return;

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final commentRef = FirebaseFirestore.instance
        .collection("posts")
        .doc(postId)
        .collection("comments");
    await commentRef.add({
      "text": commentText,
      "user": currentUser.email,
      "timestamp": FieldValue.serverTimestamp(),
    });

    await FirebaseFirestore.instance.collection("posts").doc(postId).update({
      "commentCount": FieldValue.increment(1),
    });

    _commentControllers[postId]?.clear();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final displayName = currentUser?.email?.split("@")[0] ?? "User";

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Home",
          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 61, 83, 209),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Color.fromARGB(255, 61, 83, 209),
              ),
              child: Text(
                "Welcome $displayName",
                style: const TextStyle(color: Colors.white, fontSize: 20),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text("Profile"),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const Profile()),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text("Logout"),
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                try {
                  await GoogleSignIn().signOut();
                } catch (e) {
                  print("Google signOut error: $e");
                }
                try {
                  await FacebookAuth.instance.logOut();
                } catch (e) {
                  print("Facebook signOut error: $e");
                }
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const Login()),
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color.fromARGB(255, 61, 83, 209),
        shape: const CircleBorder(),
        onPressed: () {
          setState(() {
            showForm = !showForm;
          });
        },
        child: Icon(Icons.add, size: 35, color: Colors.white),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                const Text(
                  "Posts",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                Spacer(),
                IconButton(
                  icon: Icon(Icons.search),
                  onPressed: showSearchDelegate,
                ),
              ],
            ),
          ),
          if (showForm)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  TextField(
                    controller: _postController,
                    decoration: const InputDecoration(
                      labelText: "What's on your mind?",
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: pickImage,
                        icon: const Icon(Icons.image),
                        label: const Text("Pick Image"),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: addPost,
                        child: const Text("Add Post"),
                      ),
                    ],
                  ),
                  if (_pickedImage != null)
                    Image.file(_pickedImage!, width: 100, height: 100),
                ],
              ),
            ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("posts")
                  .orderBy("timestamp", descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data!.docs;

                if (docs.isEmpty) {
                  return const Center(child: Text("No posts found."));
                }

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final post = docs[index];
                    final text = post["text"] ?? "";
                    final imageUrl = post["imageUrl"] ?? "";
                    final displayName =
                        post.data().toString().contains("displayName")
                        ? post["displayName"]
                        : "User";
                    final likedBy = List<String>.from(post["likedBy"] ?? []);
                    final commentCount = post["commentCount"] ?? 0;
                    final isLiked = likedBy.contains(currentUser?.email);
                    final postId = post.id;

                    _commentControllers.putIfAbsent(
                      postId,
                      () => TextEditingController(),
                    );

                    return Card(
                      margin: const EdgeInsets.all(10),
                      elevation: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ListTile(
                            title: Text(displayName),
                            subtitle: Text(text),
                          ),
                          if (imageUrl.isNotEmpty)
                            Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              height: 200,
                              width: double.infinity,
                            ),
                          Row(
                            children: [
                              IconButton(
                                icon: Icon(
                                  isLiked
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color: isLiked ? Colors.red : Colors.grey,
                                ),
                                onPressed: () => toggleLike(postId, likedBy),
                              ),
                              Text("$commentCount comments"),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _commentControllers[postId],
                                    decoration: const InputDecoration(
                                      hintText: "Write a comment...",
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.send),
                                  onPressed: () => addComment(postId),
                                ),
                              ],
                            ),
                          ),
                          StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection("posts")
                                .doc(postId)
                                .collection("comments")
                                .orderBy("timestamp", descending: true)
                                .snapshots(),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) return Container();
                              final comments = snapshot.data!.docs;
                              return ListView.builder(
                                shrinkWrap: true,
                                physics: NeverScrollableScrollPhysics(),
                                itemCount: comments.length,
                                itemBuilder: (context, index) {
                                  final comment = comments[index];
                                  final commentData =
                                      comment.data() as Map<String, dynamic>;
                                  final user = commentData.containsKey("user")
                                      ? commentData["user"]
                                      : "User";
                                  final text = commentData.containsKey("text")
                                      ? commentData["text"]
                                      : "";
                                  return ListTile(
                                    title: Text(user),
                                    subtitle: Text(text),
                                  );
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class PostSearchDelegate extends SearchDelegate {
  final Function(String postId, List<String> likedBy)? onToggleLike;
  PostSearchDelegate({this.onToggleLike});

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [IconButton(icon: Icon(Icons.clear), onPressed: () => query = '')];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final currentUserEmail = FirebaseAuth.instance.currentUser?.email ?? "";
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection("posts").snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        final results = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data["text"].toString().toLowerCase().contains(
                query.toLowerCase(),
              ) ||
              data["displayName"].toString().toLowerCase().contains(
                query.toLowerCase(),
              );
        }).toList();

        return ListView(
          children: results.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final isLiked = List<String>.from(
              data["likedBy"] ?? [],
            ).contains(currentUserEmail);
            return ListTile(
              title: Text(data["displayName"] ?? "User"),
              subtitle: Text(data["text"] ?? ""),
              trailing: IconButton(
                icon: Icon(
                  isLiked ? Icons.favorite : Icons.favorite_border,
                  color: isLiked ? Colors.red : Colors.grey,
                ),
                onPressed: () => onToggleLike?.call(
                  doc.id,
                  List<String>.from(data["likedBy"] ?? []),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return buildResults(context);
  }
}
