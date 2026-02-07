import 'package:flutter/material.dart';
import 'package:test/constants.dart';
import 'package:test/models/school.dart';

/// A widget that provides controls for selecting academic year, term, and class
/// for data analysis.
class AnalysisSelectionControls extends StatefulWidget {
  final School school;
  final Function(int year, String term, String? className) onSelectionChanged;
  final bool includeClassSelection;
  final String? initialClass;

  const AnalysisSelectionControls({
    super.key,
    required this.school,
    required this.onSelectionChanged,
    this.includeClassSelection = true,
    this.initialClass,
  });

  @override
  State<AnalysisSelectionControls> createState() =>
      _AnalysisSelectionControlsState();
}

class _AnalysisSelectionControlsState extends State<AnalysisSelectionControls> {
  late int _selectedYear;
  late String _selectedTerm;
  String? _selectedClass;

  @override
  void initState() {
    super.initState();
    // Use current year and first term as sensible defaults, as these are not
    // available on the School model.
    _selectedYear = DateTime.now().year;
    _selectedTerm = AppConstants.terms.first;
    _selectedClass = widget.initialClass;
  }

  void _notifyParent() {
    widget.onSelectionChanged(_selectedYear, _selectedTerm, _selectedClass);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  // Use initialValue instead of the deprecated value.
                  initialValue: _selectedYear,
                  decoration: const InputDecoration(
                    labelText: 'Academic Year',
                    border: OutlineInputBorder(),
                  ),
                  // Generate a list of recent years dynamically.
                  items: List.generate(5, (i) => DateTime.now().year - i)
                      .map((year) => DropdownMenuItem(
                            value: year,
                            child: Text(year.toString()),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedYear = value;
                      });
                      _notifyParent();
                    }
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<String>(
                  // Use initialValue instead of the deprecated value.
                  initialValue: _selectedTerm,
                  decoration: const InputDecoration(
                    labelText: 'Term',
                    border: OutlineInputBorder(),
                  ),
                  // Use the centrally defined list of terms.
                  items: AppConstants.terms
                      .map((term) => DropdownMenuItem(
                            value: term,
                            child: Text(term),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedTerm = value;
                      });
                      _notifyParent();
                    }
                  },
                ),
              ),
            ],
          ),
          if (widget.includeClassSelection) ...[
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedClass,
              decoration: const InputDecoration(
                labelText: 'Class',
                border: OutlineInputBorder(),
              ),
              // Use the school's list of classes.
              items: widget.school.allClassNamesWithStreams
                  .map((className) => DropdownMenuItem(
                        value: className,
                        child: Text(className),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedClass = value;
                });
                _notifyParent();
              },
              // Class can be optional, so no validator is needed unless required by the parent widget.
            ),
          ],
        ],
      ),
    );
  }
}
