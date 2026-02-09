import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io'; 
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:fl_chart/fl_chart.dart'; 
import 'package:fitness_tracker_app/providers/profile_provider.dart';

import '../providers/nutrition_provider.dart';
import '../models/nutrition_model.dart';
import '../utils/theme.dart';
import '../widgets/nutri_score_card.dart';
import '../widgets/meal_card.dart';
import '../widgets/nutrition_summary_card.dart';
import 'package:permission_handler/permission_handler.dart';

class NutritionScreen extends StatefulWidget {
  const NutritionScreen({super.key});

  @override
  State<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends State<NutritionScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  XFile? _imageFile;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final nutritionProvider = context.read<NutritionProvider>();
      final profileProvider = context.read<ProfileProvider>();

      if (profileProvider.user != null) {
        nutritionProvider.setUserId(profileProvider.user!.uid);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source, Function(XFile) onImageSelected) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source, imageQuality: 80);
    if (pickedFile != null) {
      onImageSelected(pickedFile);
    }
  }

  Future<void> _scanBarcode(BuildContext context, Function(NutritionModel) onScanned) async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Camera permission is required to scan barcodes.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text('Scan Barcode'),
            backgroundColor: AppTheme.appBarBackground,
          ),
          body: MobileScanner(
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty) {
                final code = barcodes.first.rawValue;
                if (code != null) {
                  Navigator.pop(context, code);
                }
              }
            },
          ),
        ),
      ),
    );

    if (result != null && result is String) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Fetching nutrition data...'),
          backgroundColor: AppColors.info,
        ),
      );
      
      final provider = context.read<NutritionProvider>();
      final meal = await provider.fetchNutritionFromBarcode(result);
      
      if (meal != null) {
        onScanned(meal);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product not found or error occurred.')),
        );
      }
    }
  }

  void _showAddMealBottomSheet(BuildContext context, {String? category, NutritionModel? meal}) {
    final isEditing = meal != null;
    final nutritionProvider = context.read<NutritionProvider>();

    final nameController = TextEditingController(text: isEditing ? meal.name : '');
    final caloriesController = TextEditingController(text: isEditing ? meal.calories.toStringAsFixed(0) : '');
    final proteinController = TextEditingController(text: isEditing ? meal.protein.toStringAsFixed(1) : '');
    final carbsController = TextEditingController(text: isEditing ? meal.carbs.toStringAsFixed(1) : '');
    final fatController = TextEditingController(text: isEditing ? meal.fat.toStringAsFixed(1) : '');
    final fiberController = TextEditingController(text: isEditing ? meal.fiber.toStringAsFixed(1) : '');
    
    String selectedCategory = category ?? (isEditing ? meal.category : 'Breakfast');
    _imageFile = null;

    void updateCalories() {
      final p = double.tryParse(proteinController.text) ?? 0;
      final c = double.tryParse(carbsController.text) ?? 0;
      final f = double.tryParse(fatController.text) ?? 0;
      final cal = (p * 4) + (c * 4) + (f * 9);
      if (cal > 0) {
        caloriesController.text = cal.toStringAsFixed(0);
      }
    }

    proteinController.addListener(updateCalories);
    carbsController.addListener(updateCalories);
    fatController.addListener(updateCalories);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (stfContext, stfSetState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.9,
              decoration: BoxDecoration(
                color: AppTheme.cardBg,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppRadius.xl),
                  topRight: Radius.circular(AppRadius.xl),
                ),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isEditing ? 'Edit Meal' : 'Add New Meal',
                        style: AppText.headlineMedium.copyWith(color: AppColors.textPrimary),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(sheetContext),
                        icon: Icon(Icons.close, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  Center(
                    child: GestureDetector(
                      onTap: () {
                        _pickImage(ImageSource.gallery, (file) {
                          stfSetState(() {
                            _imageFile = file;
                          });
                        });
                      },
                      child: Container(
                        height: 150,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          image: _imageFile != null
                              ? (kIsWeb 
                                  ? DecorationImage(image: NetworkImage(_imageFile!.path), fit: BoxFit.cover) 
                                  : DecorationImage(image: FileImage(File(_imageFile!.path)), fit: BoxFit.cover))
                              : (isEditing && meal.imageUrl != null && meal.imageUrl!.isNotEmpty
                                  ? DecorationImage(image: NetworkImage(meal.imageUrl!), fit: BoxFit.cover)
                                  : null),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: _imageFile == null && (meal?.imageUrl == null || meal!.imageUrl!.isEmpty)
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.camera_alt, color: AppColors.primary, size: 40),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Tap to add photo',
                                    style: AppText.body.copyWith(color: AppColors.textSecondary),
                                  ),
                                ],
                              )
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (!isEditing)
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: Icon(Icons.qr_code_scanner, color: AppColors.primary),
                        label: Text('Scan Barcode', style: AppText.button.copyWith(color: AppColors.primary)),
                        onPressed: () {
                          _scanBarcode(context, (scannedMeal) {
                            stfSetState(() {
                              nameController.text = scannedMeal.name;
                              caloriesController.text = scannedMeal.calories.toStringAsFixed(0);
                              proteinController.text = scannedMeal.protein.toStringAsFixed(1);
                              carbsController.text = scannedMeal.carbs.toStringAsFixed(1);
                              fatController.text = scannedMeal.fat.toStringAsFixed(1);
                              fiberController.text = scannedMeal.fiber.toStringAsFixed(1);
                            });
                          });
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(color: AppColors.primary),
                          foregroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),

                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          TextField(
                            controller: nameController,
                            decoration: InputDecoration(
                              labelText: 'Meal Name',
                              prefixIcon: Icon(Icons.restaurant, color: AppColors.textSecondary),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppRadius.md),
                              ),
                            ),
                            style: AppText.body.copyWith(color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: caloriesController,
                                  decoration: InputDecoration(
                                    labelText: 'Calories',
                                    suffixText: 'kcal',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(AppRadius.md),
                                    ),
                                  ),
                                  keyboardType: TextInputType.number,
                                  style: AppText.body.copyWith(color: AppColors.textPrimary),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  initialValue: selectedCategory,
                                  decoration: InputDecoration(
                                    labelText: 'Category',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(AppRadius.md),
                                    ),
                                  ),
                                  dropdownColor: AppColors.surface,
                                  style: AppText.body.copyWith(color: AppColors.textPrimary),
                                  items: ['Breakfast', 'Lunch', 'Dinner', 'Snacks']
                                      .map((cat) => DropdownMenuItem(
                                            value: cat,
                                            child: Text(cat, style: AppText.body),
                                          ))
                                      .toList(),
                                  onChanged: (val) {
                                    if (val != null) stfSetState(() => selectedCategory = val);
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Macronutrients',
                            style: AppText.titleMedium.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: _buildCompactField(proteinController, 'Protein', 'g', AppColors.proteinColor),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildCompactField(carbsController, 'Carbs', 'g', AppColors.carbColor),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildCompactField(fatController, 'Fat', 'g', AppColors.fatColor),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () async {
                        final newMeal = NutritionModel(
                          id: isEditing ? meal.id : null,
                          name: nameController.text.isNotEmpty ? nameController.text : 'Unnamed Meal',
                          calories: double.tryParse(caloriesController.text) ?? 0,
                          protein: double.tryParse(proteinController.text) ?? 0,
                          carbs: double.tryParse(carbsController.text) ?? 0,
                          fat: double.tryParse(fatController.text) ?? 0,
                          fiber: double.tryParse(fiberController.text) ?? 0,
                          category: selectedCategory,
                          timestamp: isEditing ? meal.timestamp : DateTime.now(),
                          imageUrl: isEditing ? meal.imageUrl : null,
                        );

                        if (isEditing) {
                          await nutritionProvider.updateMeal(meal.id!, newMeal, newImageFile: _imageFile);
                        } else {
                          await nutritionProvider.addMeal(newMeal, imageFile: _imageFile);
                        }
                        if (context.mounted) Navigator.pop(sheetContext);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.nutrition,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                      ),
                      child: Text(
                        'Save Meal',
                        style: AppText.button.copyWith(color: AppColors.white),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCompactField(TextEditingController controller, String label, String suffix, Color color) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffix,
        isDense: true,
        labelStyle: AppText.label.copyWith(color: AppColors.textSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: color),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: color.withOpacity(0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: color, width: 2),
        ),
      ),
      style: AppText.body.copyWith(color: AppColors.textPrimary),
    );
  }

  void _showSetCustomGoalDialog(BuildContext context, NutritionProvider provider) {
    final controller = TextEditingController(text: provider.dailyGoals['Calories']?.toStringAsFixed(0));
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Set Daily Calorie Goal',
          style: AppText.title.copyWith(color: AppColors.textPrimary),
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Calorie Target (kcal)',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
          ),
          style: AppText.body.copyWith(color: AppColors.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: AppText.button.copyWith(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final val = double.tryParse(controller.text);
              if (val != null && val > 0) {
                provider.setGoal(provider.selectedGoal, customCalories: val);
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: Text(
              'Save',
              style: AppText.button.copyWith(color: AppColors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NutritionProvider>(
      builder: (context, nutritionProvider, child) {
        if (nutritionProvider.isLoading) {
          return Scaffold(
            backgroundColor: AppTheme.scaffoldBackground,
            body: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }

        return Scaffold(
          backgroundColor: AppTheme.scaffoldBackground,
          appBar: AppBar(
            title: Text(
              'Nutrition Tracker',
              style: AppText.headlineMedium.copyWith(color: AppColors.textPrimary),
            ),
            backgroundColor: AppTheme.appBarBackground,
            elevation: 0,
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: AppColors.textPrimary,
              indicatorWeight: 3,
              labelColor: AppColors.textPrimary,
              unselectedLabelColor: AppColors.textSecondary,
              labelStyle: AppText.titleSmall.copyWith(fontWeight: FontWeight.w800),
              unselectedLabelStyle: AppText.body,
              tabs: const [
                Tab(text: 'Today'),
                Tab(text: 'Diet Plan'),
                Tab(text: 'History'),
              ],
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.track_changes, color: AppColors.textPrimary), 
                onPressed: () => _showSetCustomGoalDialog(context, nutritionProvider),
                tooltip: 'Set Custom Goal',
              ),
            ],
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildTodayView(nutritionProvider),
              _buildDietPlanView(nutritionProvider),
              _buildHistoryView(nutritionProvider),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showAddMealBottomSheet(context),
            backgroundColor: AppColors.nutrition,
            icon: Icon(Icons.add, color: AppColors.white),
            label: Text(
              'Log Meal',
              style: AppText.button.copyWith(color: AppColors.white),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTodayView(NutritionProvider nutritionProvider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          NutriScoreCard(
            score: nutritionProvider.nutriScore,
            goal: nutritionProvider.selectedGoal,
            color: AppColors.nutrition,
          ),
          const SizedBox(height: 20),
          NutritionSummaryCard(
            totalCalories: nutritionProvider.totalCalories,
            totalProtein: nutritionProvider.totalProtein,
            totalCarbs: nutritionProvider.totalCarbs,
            totalFat: nutritionProvider.totalFat,
            totalFiber: nutritionProvider.totalFiber,
            dailyGoals: nutritionProvider.dailyGoals,
            goal: nutritionProvider.selectedGoal,
          ),
          const SizedBox(height: 24),
          _buildMealSection('Breakfast', Icons.breakfast_dining, nutritionProvider),
          _buildMealSection('Lunch', Icons.lunch_dining, nutritionProvider),
          _buildMealSection('Dinner', Icons.dinner_dining, nutritionProvider),
          _buildMealSection('Snacks', Icons.cookie, nutritionProvider),
        ],
      ),
    );
  }

  Widget _buildMealSection(String category, IconData icon, NutritionProvider nutritionProvider) {
    final meals = nutritionProvider.getMealsByCategory(category);
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      color: AppTheme.cardBg,
      child: ExpansionTile(
        initiallyExpanded: meals.isNotEmpty,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.nutrition.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.nutrition, size: 20),
        ),
        title: Text(category, style: AppText.titleMedium.copyWith(color: AppColors.textPrimary)),
        subtitle: Text(
          '${meals.fold<double>(0, (sum, item) => sum + item.calories).toStringAsFixed(0)} kcal',
          style: AppText.bodySmall.copyWith(color: AppColors.textSecondary),
        ),
        trailing: IconButton(
          icon: Icon(Icons.add_circle_outline, color: AppColors.primary),
          onPressed: () => _showAddMealBottomSheet(context, category: category),
        ),
        children: meals.isEmpty
            ? [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'No meals logged.',
                    style: AppText.body.copyWith(color: AppColors.textSecondary),
                  ),
                )
              ]
            : meals.map((meal) => MealCard(
                  meal: meal,
                  goalColor: AppColors.nutrition,
                  onEdit: () => _showAddMealBottomSheet(context, meal: meal),
                  onDelete: () => nutritionProvider.deleteMeal(meal.id!),
                )).toList(),
      ),
    );
  }

  Widget _buildDietPlanView(NutritionProvider provider) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.nutrition.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.nutrition.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.lightbulb, color: AppColors.nutrition),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recommended Plan',
                      style: AppText.title.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Based on your goal: ${provider.selectedGoal.replaceAll('_', ' ').toUpperCase()}', 
                      style: AppText.body.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _buildPlanCategory('Breakfast', provider),
        _buildPlanCategory('Lunch', provider),
        _buildPlanCategory('Dinner', provider),
        _buildPlanCategory('Snacks', provider),
      ],
    );
  }

  Widget _buildPlanCategory(String category, NutritionProvider provider) {
    final recommendations = provider.getRecommendedMeals(category);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            category,
            style: AppText.headlineSmall.copyWith(color: AppColors.textPrimary),
          ),
        ),
        SizedBox(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: recommendations.length,
            itemBuilder: (context, index) {
              final mealData = recommendations[index];
              return Container(
                width: 180,
                margin: const EdgeInsets.only(right: 16),
                decoration: BoxDecoration(
                  color: AppTheme.cardBg,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  boxShadow: AppTheme.cardShadow,
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
                          image: DecorationImage(
                            image: AssetImage(mealData['imageUrl']),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              mealData['name'],
                              style: AppText.titleSmall.copyWith(
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${mealData['calories']} kcal',
                                  style: AppText.caption.copyWith(color: AppColors.textSecondary),
                                ),
                                InkWell(
                                  onTap: () {
                                    final meal = NutritionModel(
                                      name: mealData['name'],
                                      category: category,
                                      calories: (mealData['calories'] as num).toDouble(),
                                      protein: (mealData['protein'] as num).toDouble(),
                                      carbs: (mealData['carbs'] as num).toDouble(),
                                      fat: (mealData['fat'] as num).toDouble(),
                                      fiber: (mealData['fiber'] as num).toDouble(),
                                      timestamp: DateTime.now(),
                                    );
                                    provider.addMeal(meal);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: const Text('Meal Added!'),
                                        backgroundColor: AppColors.success,
                                      ),
                                    );
                                  },
                                  child: Icon(Icons.add_circle, color: AppColors.primary),
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildHistoryView(NutritionProvider provider) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Weekly Progress',
          style: AppText.headlineMedium.copyWith(color: AppColors.textPrimary),
        ),
        const SizedBox(height: 16),
        Container(
          height: 200,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.cardBg,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            boxShadow: AppTheme.cardShadow,
            border: Border.all(color: AppColors.border),
          ),
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: 3500,
              barTouchData: BarTouchData(enabled: false),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (double value, TitleMeta meta) {
                      return Text(
                        'D${value.toInt()}',
                        style: AppText.caption.copyWith(color: AppColors.textSecondary),
                      );
                    },
                  ),
                ),
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              barGroups: provider.weeklyHistory.asMap().entries.map((e) {
                return BarChartGroupData(
                  x: e.key,
                  barRods: [
                    BarChartRodData(
                      toY: (e.value['calories'] as num?)?.toDouble() ?? 0,
                      color: AppColors.nutrition,
                      width: 12,
                      borderRadius: BorderRadius.circular(AppRadius.xs),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Monthly Summary',
          style: AppText.headlineMedium.copyWith(color: AppColors.textPrimary),
        ),
        ...provider.monthlyHistory.map((h) => Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          elevation: 0,
          color: AppTheme.cardBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: ListTile(
            title: Text(
              h['date'] ?? '',
              style: AppText.titleMedium.copyWith(color: AppColors.textPrimary),
            ),
            trailing: Text(
              '${h['calories']?.toStringAsFixed(0) ?? '0'} kcal',
              style: AppText.headlineSmall.copyWith(color: AppColors.nutrition),
            ),
          ),
        )),
      ],
    );
  }
}