import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AddEditScheduleScreen extends StatefulWidget {
  final String? docId;
  final String? currentSubject;
  final String? currentDate;
  final String? currentTime;

  AddEditScheduleScreen({this.docId, this.currentSubject, this.currentDate, this.currentTime});

  @override
  _AddEditScheduleScreenState createState() => _AddEditScheduleScreenState();
}

class _AddEditScheduleScreenState extends State<AddEditScheduleScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for text fields
  late TextEditingController _subjectController;
  late TextEditingController _dateController;
  late TextEditingController _timeController;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();

    // Initialize the text controllers with the provided values or empty if creating new
    _subjectController = TextEditingController(text: widget.currentSubject ?? '');
    _dateController = TextEditingController(text: widget.currentDate ?? '');
    _timeController = TextEditingController(text: widget.currentTime ?? '');
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final String subject = _subjectController.text;
      final String date = _dateController.text;
      final String time = _timeController.text;

      if (widget.docId == null) {
        // Add new schedule
        await _firestore.collection('schedules').add({
          'subject': subject,
          'date': date,
          'time': time,
        });
      } else {
        // Edit existing schedule
        await _firestore.collection('schedules').doc(widget.docId).update({
          'subject': subject,
          'date': date,
          'time': time,
        });
      }

      Navigator.of(context).pop();
    }
  }

  Future<void> _pickDate() async {
    FocusScope.of(context).requestFocus(FocusNode());

    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _dateController.text.isNotEmpty
          ? DateFormat('yyyy-MM-dd').parse(_dateController.text)
          : DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2025),
    );

    if (pickedDate != null) {
      setState(() {
        _dateController.text = DateFormat('yyyy-MM-dd').format(pickedDate);
      });
    }
  }

  Future<void> _pickTime() async {
    FocusScope.of(context).requestFocus(FocusNode());

    TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: _timeController.text.isNotEmpty
          ? TimeOfDay.fromDateTime(DateFormat.jm().parse(_timeController.text))
          : TimeOfDay.now(),
    );

    if (pickedTime != null) {
      setState(() {
        _timeController.text = pickedTime.format(context);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.docId == null ? 'Add Schedule' : 'Edit Schedule'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _subjectController,
                decoration: InputDecoration(labelText: 'Subject'),
                validator: (value) => value!.isEmpty ? 'Please enter a subject' : null,
              ),
              TextFormField(
                controller: _dateController,
                decoration: InputDecoration(labelText: 'Date'),
                validator: (value) => value!.isEmpty ? 'Please enter a date' : null,
                onTap: _pickDate,
                readOnly: true,
              ),
              TextFormField(
                controller: _timeController,
                decoration: InputDecoration(labelText: 'Time'),
                validator: (value) => value!.isEmpty ? 'Please enter a time' : null,
                onTap: _pickTime,
                readOnly: true,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitForm,
                child: Text(widget.docId == null ? 'Add Schedule' : 'Update Schedule'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
