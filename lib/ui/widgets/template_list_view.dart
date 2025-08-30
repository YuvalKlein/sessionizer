import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myapp/ui/widgets/session_template_form.dart';

class TemplateListView extends StatelessWidget {
  const TemplateListView({super.key});

  Future<void> _deleteTemplate(BuildContext context, DocumentSnapshot template) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Template'),
        content: const Text('Are you sure you want to delete this template?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Delete')),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await template.reference.delete();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Template deleted successfully')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting template: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('sessionTemplates').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No templates found. Create one!'));
        }

        final templates = snapshot.data!.docs;

        return ListView.builder(
          itemCount: templates.length,
          itemBuilder: (context, index) {
            final template = templates[index];
            final entity = (template.data() as Map<String, dynamic>)['sessionEntity'] as Map<String, dynamic>? ?? {};
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: ListTile(
                title: Text(entity['title'] ?? 'No Title'),
                subtitle: Text(entity['category'] ?? 'No Category'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_note),
                      onPressed: () {
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => Scaffold(
                            appBar: AppBar(title: const Text('Edit Template')),
                            body: SessionTemplateForm(template: template),
                          ),
                        ));
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                      onPressed: () => _deleteTemplate(context, template),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
