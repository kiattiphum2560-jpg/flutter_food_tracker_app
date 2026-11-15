import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_run_tracker_app/model/food_tracker.dart';
import 'package:image_picker/image_picker.dart';

import 'service/service.dart';

class UpdateDeleteFoodTrackerUi extends StatefulWidget {
  const UpdateDeleteFoodTrackerUi({super.key, required this.food});

  final FoodTracker food;

  @override
  State<UpdateDeleteFoodTrackerUi> createState() =>
      _UpdateDeleteFoodTrackerUiState();
}

class _UpdateDeleteFoodTrackerUiState extends State<UpdateDeleteFoodTrackerUi> {
  static const _meals = ['เช้า', 'กลางวัน', 'เย็น', 'ว่าง'];

  final _foodNameController = TextEditingController();
  final _foodPriceController = TextEditingController();
  final _foodPersonController = TextEditingController();
  final _foodDateController = TextEditingController();
  final _supabaseService = SupabaseService();

  String _selectedMeal = 'เช้า';
  Uint8List? _imageBytes;
  XFile? _imageFile;
  String? _storedImageUrl;
  String? _imageUrl;
  bool _isLoadingImage = false;
  bool _isSaving = false;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _foodNameController.text = widget.food.foodName;
    _foodPriceController.text = widget.food.foodPrice.toString();
    _foodPersonController.text = widget.food.foodPerson.toString();
    _foodDateController.text = widget.food.foodDate;
    _selectedMeal = widget.food.foodMeal;
    final storedImageUrl = widget.food.foodImageUrl?.trim();
    if (storedImageUrl != null && storedImageUrl.isNotEmpty) {
      _storedImageUrl = storedImageUrl;
      _isLoadingImage = true;
      _loadSavedImage(storedImageUrl);
    }
  }

  Future<void> _loadSavedImage(String storedImageUrl) async {
    try {
      final displayUrl =
          await _supabaseService.getDisplayImageUrl(storedImageUrl);
      if (!mounted) return;
      setState(() => _imageUrl = displayUrl);
    } catch (error) {
      if (!mounted) return;
      _showMessage('โหลดรูปจาก Supabase ไม่สำเร็จ: $error', isError: true);
    } finally {
      if (mounted) setState(() => _isLoadingImage = false);
    }
  }

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
    final id = widget.food.id;
    if (id == null) {
      _showMessage('ไม่พบรหัสรายการอาหาร', isError: true);
      return;
    }

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
      var imageUrl = _storedImageUrl;
      if (_imageFile != null) {
        imageUrl = await _supabaseService.uploadImageFile(_imageFile!);
      }

      final food = FoodTracker(
        id: widget.food.id,
        createdAt: widget.food.createdAt,
        foodDate: date,
        foodMeal: _selectedMeal,
        foodName: name,
        foodPrice: price,
        foodPerson: personCount,
        foodImageUrl: imageUrl,
      );
      await _supabaseService.updateFood(food, id);

      if (!mounted) return;
      _showMessage('แก้ไขข้อมูลเรียบร้อยแล้ว');
      Navigator.pop(context, true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _deleteFood() async {
    final id = widget.food.id;
    if (id == null) {
      _showMessage('ไม่พบรหัสรายการอาหาร', isError: true);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('ลบข้อมูล'),
        content: const Text('ต้องการลบรายการอาหารนี้หรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('ลบ'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _isDeleting = true);
    try {
      await _supabaseService.deleteFood(id);
      if (!mounted) return;
      _showMessage('ลบข้อมูลเรียบร้อยแล้ว');
      Navigator.pop(context, true);
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  InputDecoration _inputDecoration({
    String? hintText,
    Widget? suffixIcon,
    bool compact = false,
  }) {
    return InputDecoration(
      hintText: hintText,
      suffixIcon: suffixIcon,
      isDense: compact,
      contentPadding: EdgeInsets.symmetric(
        horizontal: compact ? 12 : 14,
        vertical: compact ? 7 : 12,
      ),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
    );
  }

  ButtonStyle _greenActionButtonStyle({bool compact = false}) {
    return ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF4CAF50),
      foregroundColor: Colors.white,
      padding: EdgeInsets.zero,
      minimumSize: Size.fromHeight(compact ? 30 : 34),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      textStyle: TextStyle(fontSize: compact ? 10 : 11),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    );
  }

  ButtonStyle _redActionButtonStyle({bool compact = false}) {
    return ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFFF83E33),
      foregroundColor: Colors.white,
      padding: EdgeInsets.zero,
      minimumSize: Size.fromHeight(compact ? 30 : 34),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      textStyle: TextStyle(fontSize: compact ? 10 : 11),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    );
  }

  Widget _fieldLabel(String text, {bool compact = false}) => Padding(
        padding: EdgeInsets.only(bottom: compact ? 2 : 4),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            text,
            style: TextStyle(fontSize: compact ? 12 : null),
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
        title: const Text('Food Tracker (แก้ไข/ลบ)'),
        centerTitle: true,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final compact =
              constraints.maxHeight < 640 || constraints.maxWidth < 360;
          final fieldGap = compact ? 8.0 : 14.0;
          final imageSize = compact ? 130.0 : 150.0;
          final imageWidth = compact ? 150.0 : 170.0;
          final actionHeight = compact ? 30.0 : 34.0;

          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              15,
              compact ? 12 : 32,
              15,
              compact ? 12 : 24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: InkWell(
                    onTap: _selectImage,
                    child: _imageBytes != null
                        ? Image.memory(
                            _imageBytes!,
                            width: imageWidth,
                            height: imageSize,
                            fit: BoxFit.cover,
                          )
                        : _isLoadingImage
                            ? SizedBox(
                                width: compact ? 28 : 36,
                                height: compact ? 28 : 36,
                                child: const CircularProgressIndicator(
                                  strokeWidth: 3,
                                ),
                              )
                            : _imageUrl != null
                                ? Image.network(
                                    _imageUrl!,
                                    width: imageWidth,
                                    height: imageSize,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Icon(
                                      Icons.add_photo_alternate_outlined,
                                      size: compact ? 120 : 140,
                                      color: Colors.grey,
                                    ),
                                  )
                                : Icon(
                                    Icons.add_photo_alternate_outlined,
                                    size: compact ? 120 : 140,
                                    color: Colors.grey,
                                  ),
                  ),
                ),
                SizedBox(height: compact ? 8 : 12),
                _fieldLabel('กินอะไร', compact: compact),
                TextField(
                  controller: _foodNameController,
                  style: TextStyle(fontSize: compact ? 12 : null),
                  decoration: _inputDecoration(
                    hintText: 'เช่น KFC',
                    compact: compact,
                  ),
                ),
                SizedBox(height: fieldGap),
                _fieldLabel('กินมื้อไหน', compact: compact),
                Wrap(
                  spacing: compact ? 4 : 8,
                  runSpacing: compact ? 4 : 8,
                  children: _meals.map((meal) {
                    final selected = _selectedMeal == meal;
                    return ChoiceChip(
                      label: Text(meal),
                      selected: selected,
                      showCheckmark: true,
                      checkmarkColor: Colors.white,
                      selectedColor: const Color(0xFF4CAF50),
                      backgroundColor: Colors.grey,
                      labelStyle: TextStyle(
                        color: Colors.white,
                        fontSize: compact ? 11 : null,
                      ),
                      visualDensity: compact
                          ? VisualDensity.compact
                          : VisualDensity.standard,
                      side: BorderSide.none,
                      onSelected: (_) => setState(() => _selectedMeal = meal),
                    );
                  }).toList(),
                ),
                SizedBox(height: fieldGap),
                _fieldLabel('กินไปเท่าไหร่', compact: compact),
                TextField(
                  controller: _foodPriceController,
                  style: TextStyle(fontSize: compact ? 12 : null),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: _inputDecoration(
                    hintText: 'เช่น 234.75',
                    compact: compact,
                  ),
                ),
                SizedBox(height: fieldGap),
                _fieldLabel('กินกี่คน', compact: compact),
                TextField(
                  controller: _foodPersonController,
                  style: TextStyle(fontSize: compact ? 12 : null),
                  keyboardType: TextInputType.number,
                  decoration: _inputDecoration(
                    hintText: 'เช่น 2',
                    compact: compact,
                  ),
                ),
                SizedBox(height: fieldGap),
                _fieldLabel('กินวันไหน', compact: compact),
                TextField(
                  controller: _foodDateController,
                  style: TextStyle(fontSize: compact ? 12 : null),
                  readOnly: true,
                  onTap: _selectFoodDate,
                  decoration: _inputDecoration(
                    hintText: 'เลือกวันที่',
                    compact: compact,
                    suffixIcon: IconButton(
                      onPressed: _selectFoodDate,
                      icon: Icon(
                        Icons.calendar_month_outlined,
                        size: compact ? 18 : 24,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: compact ? 10 : 16),
                SizedBox(
                  height: actionHeight,
                  child: ElevatedButton(
                    onPressed: _isSaving || _isDeleting ? null : _saveFood,
                    style: _greenActionButtonStyle(compact: compact),
                    child: Text(
                      _isSaving ? 'กำลังบันทึก...' : 'บันทึกแก้ไข',
                    ),
                  ),
                ),
                SizedBox(height: compact ? 4 : 6),
                SizedBox(
                  height: actionHeight,
                  child: ElevatedButton(
                    onPressed: _isSaving || _isDeleting ? null : _deleteFood,
                    style: _redActionButtonStyle(compact: compact),
                    child: Text(_isDeleting ? 'กำลังลบ...' : 'ลบข้อมูล'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
