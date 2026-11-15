import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_run_tracker_app/model/food_tracker.dart';
import 'package:image_picker/image_picker.dart';

import 'service/service.dart';

class AddFoodTrackerUi extends StatefulWidget {
  const AddFoodTrackerUi({super.key});

  @override
  State<AddFoodTrackerUi> createState() => _AddFoodTrackerUiState();
}

class _AddFoodTrackerUiState extends State<AddFoodTrackerUi> {
  static const _meals = ['เช้า', 'กลางวัน', 'เย็น', 'ว่าง'];

  final _foodNameController = TextEditingController();
  final _foodPriceController = TextEditingController();
  final _foodPersonController = TextEditingController();
  final _foodDateController = TextEditingController();
  final _supabaseService = SupabaseService();

  String _selectedMeal = 'เช้า';
  Uint8List? _imageBytes;
  XFile? _imageFile;
  bool _isSaving = false;

  Future<void> _selectImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('ถ่ายรูป'),
              onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('เลือกจากแกลเลอรี'),
              onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;

    final file = await ImagePicker().pickImage(
      source: source,
      imageQuality: 80,
    );
    if (file == null) return;

    final bytes = await file.readAsBytes();
    if (!mounted) return;

    setState(() {
      _imageFile = file;
      _imageBytes = bytes;
    });
  }

  Future<void> _selectFoodDate() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate:
          DateTime.tryParse(_foodDateController.text) ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (selectedDate == null || !mounted) return;

    setState(() {
      _foodDateController.text =
          '${selectedDate.year.toString().padLeft(4, '0')}-'
          '${selectedDate.month.toString().padLeft(2, '0')}-'
          '${selectedDate.day.toString().padLeft(2, '0')}';
    });
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  Future<void> _saveFood() async {
    final name = _foodNameController.text.trim();
    final price = double.tryParse(_foodPriceController.text.trim());
    final personCount = int.tryParse(_foodPersonController.text.trim());
    final date = _foodDateController.text.trim();

    if (name.isEmpty || date.isEmpty || price == null || personCount == null) {
      _showMessage('กรุณากรอกข้อมูลให้ครบถ้วนและถูกต้อง', isError: true);
      return;
    }
    if (!price.isFinite || personCount < 1) {
      _showMessage('กรุณาตรวจสอบราคาและจำนวนคน', isError: true);
      return;
    }

    setState(() => _isSaving = true);
    try {
      final imageUrl = _imageFile == null
          ? null
          : await _supabaseService.uploadImageFile(_imageFile!);
      final food = FoodTracker(
        foodDate: date,
        foodMeal: _selectedMeal,
        foodName: name,
        foodPrice: price,
        foodPerson: personCount,
        foodImageUrl: imageUrl,
      );
      await _supabaseService.insertFood(food);

      if (!mounted) return;
      _showMessage('บันทึกข้อมูลเรียบร้อยแล้ว');
      Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        _showMessage('บันทึกข้อมูลไม่สำเร็จ: $error', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  InputDecoration _inputDecoration({
    String? hintText,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(fontSize: 11, color: Color(0xFF777777)),
      suffixIcon: suffixIcon,
      isDense: true,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(5),
        borderSide: const BorderSide(color: Color(0xFFBDBDBD)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(5),
        borderSide: const BorderSide(color: Color(0xFFBDBDBD)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(5),
        borderSide: const BorderSide(color: Color(0xFF4CAF50)),
      ),
    );
  }

  ButtonStyle _actionButtonStyle(Color color) {
    return ElevatedButton.styleFrom(
      backgroundColor: color,
      foregroundColor: Colors.white,
      padding: EdgeInsets.zero,
      minimumSize: const Size.fromHeight(30),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      textStyle: const TextStyle(fontSize: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    );
  }

  Widget _fieldLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 3),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            text,
            style: const TextStyle(fontSize: 11),
          ),
        ),
      );

  @override
  void dispose() {
    _foodNameController.dispose();
    _foodPriceController.dispose();
    _foodPersonController.dispose();
    _foodDateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF83E33),
        foregroundColor: Colors.white,
        title: const Text('Food Tracker (เพิ่ม)'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 22, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 160,
              child: Center(
                child: InkWell(
                  onTap: _selectImage,
                  child: _imageBytes == null
                      ? const Icon(
                          Icons.add_a_photo_outlined,
                          size: 150,
                          color: Color(0xFF9E9E9E),
                        )
                      : Image.memory(
                          _imageBytes!,
                          width: 72,
                          height: 72,
                          fit: BoxFit.cover,
                        ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            _fieldLabel('กินอะไร'),
            TextField(
              controller: _foodNameController,
              style: const TextStyle(fontSize: 11),
              decoration: _inputDecoration(hintText: 'เช่น KFC, Pizza'),
            ),
            const SizedBox(height: 10),
            _fieldLabel('กินมื้อไหน'),
            Wrap(
              spacing: 5,
              runSpacing: 4,
              children: _meals.map((meal) {
                final selected = _selectedMeal == meal;
                return ChoiceChip(
                  label: Text(meal),
                  selected: selected,
                  showCheckmark: false,
                  selectedColor: const Color(0xFF4CAF50),
                  backgroundColor: const Color(0xFF9E9E9E),
                  labelStyle: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                  ),
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  side: BorderSide.none,
                  onSelected: (_) => setState(() => _selectedMeal = meal),
                );
              }).toList(),
            ),
            const SizedBox(height: 10),
            _fieldLabel('กินไปเท่าไหร่'),
            TextField(
              controller: _foodPriceController,
              style: const TextStyle(fontSize: 11),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: _inputDecoration(hintText: 'เช่น 299.50'),
            ),
            const SizedBox(height: 10),
            _fieldLabel('กินกับกี่คน'),
            TextField(
              controller: _foodPersonController,
              style: const TextStyle(fontSize: 11),
              keyboardType: TextInputType.number,
              decoration: _inputDecoration(hintText: 'เช่น 3'),
            ),
            const SizedBox(height: 10),
            _fieldLabel('กินไปวันไหน'),
            TextField(
              controller: _foodDateController,
              style: const TextStyle(fontSize: 11),
              readOnly: true,
              onTap: _selectFoodDate,
              decoration: _inputDecoration(
                hintText: 'เช่น 2020-01-31',
                suffixIcon: IconButton(
                  onPressed: _selectFoodDate,
                  icon: const Icon(Icons.calendar_today_outlined, size: 16),
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  padding: EdgeInsets.zero,
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 30,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveFood,
                style: _actionButtonStyle(const Color(0xFF4CAF50)),
                child: Text(_isSaving ? 'กำลังบันทึก...' : 'บันทึก'),
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 30,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: _actionButtonStyle(const Color(0xFFF83E33)),
                child: const Text('ยกเลิก'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
