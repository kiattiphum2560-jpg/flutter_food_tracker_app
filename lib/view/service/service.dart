// ไฟล์นี้จะประกอบด้วยโค้ดคำสั่งการทำงานต่างๆ กับ Supabase
// เช่น อัปโหลดไฟล์, เพิ่ม ลบ แก้ไข ค้นหา/ตรวจสอบ/ดึง/ดู ข้อมูลในตาราง
import 'package:image_picker/image_picker.dart';
import 'package:flutter_run_tracker_app/model/food_tracker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  final supabase = Supabase.instance.client;
  static const _tableName = 'food_tracker_tb';
  static const _bucketName = 'food_tracker_tb';

  Future<String> uploadImageFile(XFile xfile) async {
    final newFileName = '${DateTime.now().millisecondsSinceEpoch}_${xfile.name}';

    await supabase.storage.from(_bucketName).uploadBinary(
      newFileName,
      await xfile.readAsBytes(),
      fileOptions: FileOptions(contentType: xfile.mimeType),
    );

    return supabase.storage.from(_bucketName).getPublicUrl(newFileName);
  }

  Future<String> getDisplayImageUrl(String storedImageUrl) async {
    final uri = Uri.tryParse(storedImageUrl);
    if (uri == null) return storedImageUrl;

    final bucketIndex = uri.pathSegments.indexOf(_bucketName);
    if (bucketIndex >= 0) {
      final objectPath = uri.pathSegments.skip(bucketIndex + 1).join('/');
      if (objectPath.isEmpty) {
        throw FormatException('Image URL does not include a storage object.');
      }
      return supabase.storage
          .from(_bucketName)
          .createSignedUrl(objectPath, 60 * 60);
    }

    if (uri.hasScheme) return storedImageUrl;
    return supabase.storage
        .from(_bucketName)
        .createSignedUrl(uri.path, 60 * 60);
  }

  Future<void> insertFood(FoodTracker food) async {
    await supabase.from(_tableName).insert(food.toJson());
  }

  Future<List<FoodTracker>> getAllFoods() async {
    final response = await supabase
        .from(_tableName)
        .select()
        .order('created_at', ascending: false);
    return response.map((row) => FoodTracker.fromJson(row)).toList();
  }

  Future<void> deleteImageFile(String fileName) async {
    await supabase.storage.from(_bucketName).remove([fileName]);
  }

  Future<void> updateFood(FoodTracker food, String id) async {
    await supabase.from(_tableName).update(food.toJson()).eq('id', id);
  }

  Future<void> deleteFood(String id) async {
    await supabase.from(_tableName).delete().eq('id', id);
  }
}