import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../models/cnic_data.dart';
import '../../../ui/theme/color_palette.dart';
import '../../../ui/theme/spacing.dart';
import '../../../ui/theme/typography.dart';
import 'cnic_scan_screen.dart';

/// Screen showing CNIC data confirmation after scan
class CnicConfirmationScreen extends StatefulWidget {
  final CnicData cnicData;

  const CnicConfirmationScreen({super.key, required this.cnicData});

  @override
  State<CnicConfirmationScreen> createState() => _CnicConfirmationScreenState();
}

class _CnicConfirmationScreenState extends State<CnicConfirmationScreen> {
  late TextEditingController _cnicController;
  late TextEditingController _nameController;
  late TextEditingController _fatherNameController;
  late DateTime? _dateOfBirth;

  @override
  void initState() {
    super.initState();
    _cnicController = TextEditingController(text: widget.cnicData.cnicNumber);
    _nameController = TextEditingController(text: widget.cnicData.name);
    _fatherNameController = TextEditingController(
      text: widget.cnicData.fatherName,
    );
    _dateOfBirth = widget.cnicData.dateOfBirth;
  }

  @override
  void dispose() {
    _cnicController.dispose();
    _nameController.dispose();
    _fatherNameController.dispose();
    super.dispose();
  }

  void _confirmAndProceed() {
    // Create updated CNIC data
    final confirmedData = widget.cnicData.copyWith(
      cnicNumber: _cnicController.text,
      name: _nameController.text,
      fatherName: _fatherNameController.text,
      dateOfBirth: _dateOfBirth,
    );

    // Validate
    if (!confirmedData.isValidFormat) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid CNIC format. Use: XXXXX-XXXXXXX-X'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Navigate to face verification with CNIC data
    context.push('/verification/face', extra: confirmedData);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirm CNIC Details'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(Spacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Success icon
              Container(
                padding: const EdgeInsets.all(Spacing.lg),
                decoration: const BoxDecoration(
                  gradient: AppColors.secondaryGradient,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_outline,
                  size: 60,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: Spacing.lg),

              Text(
                'CNIC Scanned Successfully',
                style: AppTypography.headline(context),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: Spacing.sm),

              Text(
                'Please verify the details below',
                style: AppTypography.body(context),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: Spacing.xxl),

              // CNIC Number
              TextField(
                controller: _cnicController,
                decoration: const InputDecoration(
                  labelText: 'CNIC Number',
                  hintText: '12345-1234567-1',
                  prefixIcon: Icon(Icons.credit_card),
                ),
                keyboardType: TextInputType.number,
              ),

              const SizedBox(height: Spacing.lg),

              // Name
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  prefixIcon: Icon(Icons.person),
                ),
                textCapitalization: TextCapitalization.words,
              ),

              const SizedBox(height: Spacing.lg),

              // Father's Name
              TextField(
                controller: _fatherNameController,
                decoration: const InputDecoration(
                  labelText: "Father's Name",
                  prefixIcon: Icon(Icons.family_restroom),
                ),
                textCapitalization: TextCapitalization.words,
              ),

              const SizedBox(height: Spacing.lg),

              // Date of Birth
              ListTile(
                leading: const Icon(Icons.cake),
                title: const Text('Date of Birth'),
                subtitle: Text(
                  _dateOfBirth != null
                      ? '${_dateOfBirth!.day}/${_dateOfBirth!.month}/${_dateOfBirth!.year}'
                      : 'Not detected',
                ),
                trailing: const Icon(Icons.edit),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _dateOfBirth ?? DateTime(2000),
                    firstDate: DateTime(1950),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setState(() {
                      _dateOfBirth = picked;
                    });
                  }
                },
              ),

              const SizedBox(height: Spacing.xxl),

              // Confirm Button
              ElevatedButton(
                onPressed: _confirmAndProceed,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: Spacing.lg),
                  backgroundColor: AppColors.primaryDark,
                ),
                child: const Text(
                  'Confirm & Continue',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),

              const SizedBox(height: Spacing.md),

              // Rescan Button
              TextButton.icon(
                onPressed: () async {
                  final result = await Navigator.push<CnicData>(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CnicScanScreen(),
                    ),
                  );

                  if (result != null && mounted) {
                    setState(() {
                      _cnicController.text = result.cnicNumber;
                      _nameController.text = result.name;
                      _fatherNameController.text = result.fatherName;
                      _dateOfBirth = result.dateOfBirth;
                    });
                  }
                },
                icon: const Icon(Icons.camera_alt),
                label: const Text('Rescan CNIC'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
