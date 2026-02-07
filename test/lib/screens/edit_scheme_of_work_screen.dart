import 'package:flutter/material.dart';
import 'package:test/models/scheme_of_work_model.dart';

class EditSchemeOfWorkScreen extends StatefulWidget {
  final SchemeOfWork? scheme;

  const EditSchemeOfWorkScreen({super.key, this.scheme});

  @override
  State<EditSchemeOfWorkScreen> createState() => _EditSchemeOfWorkScreenState();
}

class _EditSchemeOfWorkScreenState extends State<EditSchemeOfWorkScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.scheme == null ? 'Create Scheme of Work' : 'Edit Scheme of Work'),
      ),
      body: const Center(
        child: Text('Edit Scheme of Work Screen'),
      ),
    );
  }
}