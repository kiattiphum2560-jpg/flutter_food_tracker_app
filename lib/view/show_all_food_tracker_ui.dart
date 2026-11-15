import 'package:flutter/material.dart';
import 'package:flutter_run_tracker_app/model/food_tracker.dart';

import 'add_food_tracker_ui.dart';
import 'update_delete_food_tracker_ui.dart';
import 'service/service.dart';

class ShowAllFoodTrackerUi extends StatefulWidget {
  const ShowAllFoodTrackerUi({super.key});

  @override
  State<ShowAllFoodTrackerUi> createState() => _ShowAllFoodTrackerUiState();
}

class _ShowAllFoodTrackerUiState extends State<ShowAllFoodTrackerUi> {
  final _supabaseService = SupabaseService();
  final Map<String, Future<String>> _imageUrlFutures = {};
  late Future<List<FoodTracker>> _foodsFuture;

  @override
  void initState() {
    super.initState();
    _foodsFuture = _supabaseService.getAllFoods();
  }

  Future<void> _openFoodForm({FoodTracker? food}) async {
    final page = food == null
        ? const AddFoodTrackerUi()
        : UpdateDeleteFoodTrackerUi(food: food);
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => page,
      ),
    );
    if (changed == true && mounted) {
      setState(() {
        _foodsFuture = _supabaseService.getAllFoods();
      });
    }
  }

  Widget _foodImage(FoodTracker food) {
    final storedImageUrl = food.foodImageUrl?.trim();
    if (storedImageUrl == null || storedImageUrl.isEmpty) {
      return const SizedBox(
        width: 48,
        height: 48,
        child: Icon(Icons.image_outlined, color: Colors.grey),
      );
    }

    final imageUrlFuture = _imageUrlFutures.putIfAbsent(
      storedImageUrl,
      () => _supabaseService.getDisplayImageUrl(storedImageUrl),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: FutureBuilder<String>(
        future: imageUrlFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox(
              width: 48,
              height: 48,
              child: Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return const SizedBox(
              width: 48,
              height: 48,
              child: Tooltip(
                message: 'โหลดรูปจาก Supabase ไม่สำเร็จ',
                child: Icon(Icons.broken_image_outlined, color: Colors.grey),
              ),
            );
          }

          return Image.network(
            snapshot.data!,
            width: 48,
            height: 48,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const SizedBox(
              width: 48,
              height: 48,
              child: Tooltip(
                message: 'โหลดรูปจาก Supabase ไม่สำเร็จ',
                child: Icon(Icons.broken_image_outlined, color: Colors.grey),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF83E33),
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text('Food Tracker'),
      ),
      body: Column(
        children: [
          const SizedBox(height: 40),
          Container(
            height: 190,
            width: double.infinity,
            color: const Color(0xFFFFF8F7),
            child: Center(
              child: Image.asset(
                'assets/icon/burger.png',
                width: 180,
                height: 180,
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 4),
              child: Container(
                width: double.infinity,
                color: const Color(0xFFF4F4F4),
                child: FutureBuilder<List<FoodTracker>>(
                  future: _foodsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Text('โหลดข้อมูลไม่สำเร็จ: ${snapshot.error}'),
                      );
                    }

                    final foods = snapshot.data ?? const <FoodTracker>[];
                    if (foods.isEmpty) {
                      return const Center(child: Text('ยังไม่มีรายการอาหาร'));
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.all(8),
                      itemCount: foods.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final food = foods[index];
                        return Card(
                          child: ListTile(
                            leading: _foodImage(food),
                            title: Text(food.foodName),
                            subtitle: Text(
                              '${food.foodMeal} • ${food.foodDate} • ${food.foodPerson} คน',
                            ),
                            trailing: Text(food.foodPrice.toStringAsFixed(2)),
                            onTap: () => _openFoodForm(food: food),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFF83E33),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        onPressed: () => _openFoodForm(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
