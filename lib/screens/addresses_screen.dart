import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../core/theme.dart';

class AddressesScreen extends StatefulWidget {
  const AddressesScreen({super.key});

  @override
  State<AddressesScreen> createState() => _AddressesScreenState();
}

class _AddressesScreenState extends State<AddressesScreen> {
  final User? user = FirebaseAuth.instance.currentUser;

  void _showAddAddressDialog(int currentCount) {
    if (currentCount >= 25) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Address limit reached (25). Please delete an old one.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final streetController = TextEditingController();
    final numberController = TextEditingController();
    final floorController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceContainer,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'New Delivery Address',
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _sheetTextField(streetController, 'Street Name (e.g., Ermou)'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _sheetTextField(numberController, 'Number')),
                const SizedBox(width: 12),
                Expanded(child: _sheetTextField(floorController, 'Floor / Apt')),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  if (streetController.text.isEmpty || numberController.text.isEmpty) return;
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(user!.uid)
                      .collection('addresses')
                      .add({
                    'street': streetController.text.trim(),
                    'number': numberController.text.trim(),
                    'floor': floorController.text.trim(),
                    'createdAt': FieldValue.serverTimestamp(),
                  });
                  if (context.mounted) context.pop();
                },
                child: const Text(
                  'Save Address',
                  style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _sheetTextField(TextEditingController controller, String hint) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38),
        filled: true,
        fillColor: AppColors.surfaceContainerLow,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Not authenticated')));
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text('My Addresses', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .collection('addresses')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          final docs = snapshot.data?.docs ?? [];

          return Column(
            children: [
              if (docs.isEmpty)
                const Expanded(
                  child: Center(
                    child: Text('No addresses saved yet.', style: TextStyle(color: Colors.white54)),
                  ),
                )
              else
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(24),
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;
                      final floor = data['floor'].toString();
                      final addressString = '${data['street']} ${data['number']}'
                          '${floor.isNotEmpty ? ', Floor: $floor' : ''}';

                      return ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        tileColor: AppColors.surfaceContainerLow,
                        leading: const Icon(LucideIcons.mapPin, color: AppColors.primary),
                        title: Text(
                          addressString,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        trailing: IconButton(
                          icon: const Icon(LucideIcons.trash2, color: Colors.redAccent),
                          onPressed: () => FirebaseFirestore.instance
                              .collection('users')
                              .doc(user!.uid)
                              .collection('addresses')
                              .doc(docs[index].id)
                              .delete(),
                        ),
                      );
                    },
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.surfaceContainerHigh,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    icon: const Icon(LucideIcons.plus, color: Colors.white),
                    label: const Text(
                      'Add New Address',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () => _showAddAddressDialog(docs.length),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
