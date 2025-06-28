import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}


class _ProfileState extends State<Profile> with SingleTickerProviderStateMixin {
  String email = "";
  String name = "";
  String job = "";
  String address = "";
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    loadUserData();
  }

  void loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection("users").doc(user.uid).get();
      if (doc.exists) {
        setState(() {
          email = user.email ?? "";
          name = doc.data()!.containsKey("name") ? doc["name"] : "";
          job = doc.data()!.containsKey("job") ? doc["job"] : "";
          address = doc.data()!.containsKey("address") ? doc["address"] : "";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
        backgroundColor:  const Color.fromARGB(255, 96, 117, 234),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "My Posts"),
            Tab(text: "Favorites"),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor:  const Color.fromARGB(255, 61, 83, 209),
                      child: const Icon(Icons.person, size: 40, color: Colors.white),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          profileText("Name", name),
                          profileText("Email", email),
                          profileText("Job", job),
                          profileText("Address", address),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                buildMyPosts(),
                buildFavorites(),
              ],
            ),
          )
        ],
      ),
    );
  }}

  Widget profileText(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: RichText(
        text: TextSpan(
          text: "$label: ",
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          children: [TextSpan(text: value, style: const TextStyle(fontWeight: FontWeight.normal))],
        ),
      ),
    );
  }

 Widget buildMyPosts() {
  final currentUser = FirebaseAuth.instance.currentUser;
  return StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance
        .collection("posts")
        .where("userEmail", isEqualTo: currentUser?.email)
        .snapshots(),
    builder: (context, snapshot) {
      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
      final docs = snapshot.data!.docs;
      if (docs.isEmpty) return const Center(child: Text("No posts yet."));
      return ListView(
        children: docs.map((doc) {
          final imageUrl = doc["imageUrl"] ?? "";
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(doc["text"] ?? "", style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 8),
                  if (imageUrl.isNotEmpty)
                    Image.network(
                      imageUrl,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  const SizedBox(height: 8),
                  Text(doc["timestamp"]?.toDate().toString() ?? "",
                      style: const TextStyle(fontSize: 12, color: Color.fromARGB(255, 27, 26, 26))),
                  const SizedBox(height: 8),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection("posts")
                        .doc(doc.id)
                        .collection("comments")
                        .snapshots(),
                    builder: (context, commentSnapshot) {
                      if (!commentSnapshot.hasData) return const Text("Loading comments...");
                      final comments = commentSnapshot.data!.docs;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: comments.map((comment) {
                          final data = comment.data() as Map<String, dynamic>;
                          final user = data["user"] ?? "User";
                          final text = data["text"] ?? "";
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Text("$user: $text", style: const TextStyle(fontSize: 14)),
                          );
                        }).toList(),
                      );
                    },
                  )
                ],
              ),
            ),
          );
        }).toList(),
      );
    },
  );
}


 Widget buildFavorites() {
  final currentUser = FirebaseAuth.instance.currentUser;
  return StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance.collection("posts").snapshots(),
    builder: (context, snapshot) {
      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
      final likedPosts = snapshot.data!.docs.where((doc) {
        final likedBy = List<String>.from(doc["likedBy"] ?? []);
        return likedBy.contains(currentUser?.email);
      }).toList();

      if (likedPosts.isEmpty) return const Center(child: Text("No favorite posts."));
      return ListView(
        children: likedPosts.map((doc) {
          final imageUrl = doc["imageUrl"] ?? "";
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(doc["text"] ?? "", style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 8),
                  if (imageUrl.isNotEmpty)
                    Image.network(
                      imageUrl,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  const SizedBox(height: 8),
                  Text(
                    doc["timestamp"]?.toDate().toString() ?? "",
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      );
    },
  );
}
