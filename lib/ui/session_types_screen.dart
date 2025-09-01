import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:myapp/ui/widgets/session_type_form.dart';
import 'package:myapp/ui/widgets/session_type_list_view.dart';

class SessionTypesScreen extends StatelessWidget {
  const SessionTypesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Session Types')),
      body: const SessionTypeListView(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showTypeForm(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showTypeForm(BuildContext context, {DocumentSnapshot? type}) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(child: SessionTypeForm(type: type));
      },
    );
  }
}
