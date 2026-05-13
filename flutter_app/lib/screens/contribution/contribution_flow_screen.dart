import 'package:flutter/material.dart';

import '../../app/tokens.dart';

class ContributionFlowScreen extends StatefulWidget {
  const ContributionFlowScreen({super.key, this.initialStep = 0});

  final int initialStep;

  @override
  State<ContributionFlowScreen> createState() => _ContributionFlowScreenState();
}

class _ContributionFlowScreenState extends State<ContributionFlowScreen> {
  late final PageController _controller;
  late int _step;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _brandController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _step = widget.initialStep.clamp(0, 2);
    _controller = PageController(initialPage: _step);
  }

  @override
  void dispose() {
    _controller.dispose();
    _nameController.dispose();
    _brandController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  void _next() {
    if (_step < 2) {
      setState(() => _step += 1);
      _controller.nextPage(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  void _back() {
    if (_step == 0) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _step -= 1);
    _controller.previousPage(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(title: const Text('Contribute Product')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: _StepHeader(step: _step),
            ),
            Expanded(
              child: PageView(
                controller: _controller,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _UploadStep(onPick: _showNotImplemented),
                  _DetailsStep(
                    nameController: _nameController,
                    brandController: _brandController,
                    categoryController: _categoryController,
                  ),
                  _ReviewStep(
                    nameController: _nameController,
                    brandController: _brandController,
                    categoryController: _categoryController,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _back,
                      child: Text(_step == 0 ? 'Close' : 'Back'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _next,
                      child: Text(_step == 2 ? 'Submit' : 'Next'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showNotImplemented() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Upload is mocked for now.')));
  }
}

class _StepHeader extends StatelessWidget {
  const _StepHeader({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Step ${step + 1} of 3',
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(color: AppColors.onSurfaceVariant),
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(value: (step + 1) / 3),
      ],
    );
  }
}

class _UploadStep extends StatelessWidget {
  const _UploadStep({required this.onPick});

  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        Text(
          'Upload Product Images',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(
          'Clear, well-lit photos help our system recognize the product.',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.onSurfaceVariant),
        ),
        const SizedBox(height: 18),
        _UploadCard(label: 'Front of package', onPick: onPick),
        const SizedBox(height: 12),
        _UploadCard(label: 'Nutrition label', onPick: onPick),
        const SizedBox(height: 12),
        _UploadCard(label: 'Ingredients list', onPick: onPick),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(AppColors.radiusMedium),
            border: Border.all(color: AppColors.outlineVariant),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: AppColors.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Tip: Clear, well-lit photos help our AI read labels accurately.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _UploadCard extends StatelessWidget {
  const _UploadCard({required this.label, required this.onPick});

  final String label;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPick,
      borderRadius: BorderRadius.circular(AppColors.radiusMedium),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppColors.radiusMedium),
          border: Border.all(color: AppColors.outlineVariant),
        ),
        child: Row(
          children: [
            const Icon(Icons.photo_camera_outlined, color: AppColors.primary),
            const SizedBox(width: 12),
            Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class _DetailsStep extends StatelessWidget {
  const _DetailsStep({
    required this.nameController,
    required this.brandController,
    required this.categoryController,
  });

  final TextEditingController nameController;
  final TextEditingController brandController;
  final TextEditingController categoryController;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        Text(
          'Product Details',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: 'Product name'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: brandController,
          decoration: const InputDecoration(labelText: 'Brand'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: categoryController,
          decoration: const InputDecoration(labelText: 'Category'),
        ),
      ],
    );
  }
}

class _ReviewStep extends StatelessWidget {
  const _ReviewStep({
    required this.nameController,
    required this.brandController,
    required this.categoryController,
  });

  final TextEditingController nameController;
  final TextEditingController brandController;
  final TextEditingController categoryController;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        Text(
          'Review & Submit',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        _ReviewRow(label: 'Name', value: nameController.text),
        _ReviewRow(label: 'Brand', value: brandController.text),
        _ReviewRow(label: 'Category', value: categoryController.text),
        const SizedBox(height: 18),
        Text(
          'Submitting will create a pending record for review.',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Flexible(
            child: Text(
              value.isEmpty ? 'Not provided' : value,
              textAlign: TextAlign.right,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
