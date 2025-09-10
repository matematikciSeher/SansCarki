import '../models/task.dart';
import '../models/category.dart';
import '../data/task_data.dart';
import '../models/category.dart' as category_models;

class DailyTaskService {
  static const int _totalCategories = 12;
  static const int _tasksPerCategory = 1; // Her kategoride 1 görev
  static const int _totalDays = _totalCategories; // 12 gün

  /// Bugünün günlük görevini döndürür
  static DailyTask getDailyTask() {
    final today = DateTime.now();
    final startDate = DateTime(2024, 1, 1); // Başlangıç tarihi
    final daysSinceStart = today.difference(startDate).inDays;
    final currentDay = daysSinceStart % _totalDays;

    // 12 gün boyunca her kategori 1 sefer gelsin, sonra başa dönsün
    final categoryIndex = currentDay % _totalCategories;
    // Her kategoride farklı görev gelmesi için: görev = gün % 40
    final taskIndex = currentDay % 40; // 40 farklı görev seçeneği

    // Kategoriyi al
    final categories = category_models.CategoryData.getAllCategories();
    final selectedCategory = categories[categoryIndex];

    // O kategorideki görevleri al
    final categoryTasks = TaskData.getTasksByCategory(
      TaskCategory.values.firstWhere(
        (e) => e.toString().split('.').last == selectedCategory.id,
        orElse: () => TaskCategory.kitap,
      ),
    );

    // Eğer o kategoride yeterli görev yoksa, mevcut görevleri tekrarla
    final selectedTask = categoryTasks[taskIndex % categoryTasks.length];

    return DailyTask(
      date: today,
      category: selectedCategory,
      task: selectedTask,
      dayNumber: currentDay + 1,
      totalDays: _totalDays,
      nextResetDays: _totalDays - (currentDay + 1),
    );
  }

  /// Belirli bir tarih için günlük görevi döndürür
  static DailyTask getDailyTaskForDate(DateTime date) {
    final startDate = DateTime(2024, 1, 1);
    final daysSinceStart = date.difference(startDate).inDays;
    final currentDay = daysSinceStart % _totalDays;

    // 12 gün boyunca her kategori 1 sefer gelsin, sonra başa dönsün
    final categoryIndex = currentDay % _totalCategories;
    // Her kategoride farklı görev gelmesi için: görev = gün % 40
    final taskIndex = currentDay % 40; // 40 farklı görev seçeneği

    final categories = category_models.CategoryData.getAllCategories();
    final selectedCategory = categories[categoryIndex];

    final categoryTasks = TaskData.getTasksByCategory(
      TaskCategory.values.firstWhere(
        (e) => e.toString().split('.').last == selectedCategory.id,
        orElse: () => TaskCategory.kitap,
      ),
    );

    final selectedTask = categoryTasks[taskIndex % categoryTasks.length];

    return DailyTask(
      date: date,
      category: selectedCategory,
      task: selectedTask,
      dayNumber: currentDay + 1,
      totalDays: _totalDays,
      nextResetDays: _totalDays - (currentDay + 1),
    );
  }

  /// Sistemin ne zaman sıfırlanacağını döndürür
  static DateTime getNextResetDate() {
    final today = DateTime.now();
    final startDate = DateTime(2024, 1, 1);
    final daysSinceStart = today.difference(startDate).inDays;
    final currentDay = daysSinceStart % _totalDays;
    final daysUntilReset = _totalDays - currentDay;

    return today.add(Duration(days: daysUntilReset));
  }

  /// Bugünün hangi günü olduğunu döndürür (1-12 arası)
  static int getCurrentDayNumber() {
    final today = DateTime.now();
    final startDate = DateTime(2024, 1, 1);
    final daysSinceStart = today.difference(startDate).inDays;
    return (daysSinceStart % _totalDays) + 1;
  }

  /// Sistemin yüzde kaçında olduğumuzu döndürür (0.0 - 1.0)
  static double getProgressPercentage() {
    final currentDay = getCurrentDayNumber();
    return (currentDay - 1) / _totalDays;
  }
}

/// Günlük görev bilgilerini tutan sınıf
class DailyTask {
  final DateTime date;
  final Category category;
  final Task task;
  final int dayNumber;
  final int totalDays;
  final int nextResetDays;

  DailyTask({
    required this.date,
    required this.category,
    required this.task,
    required this.dayNumber,
    required this.totalDays,
    required this.nextResetDays,
  });

  /// Görevin tamamlanıp tamamlanmadığını kontrol et
  bool get isCompleted {
    // Burada SharedPreferences'tan tamamlanan görevleri kontrol edebilirsiniz
    return false;
  }

  /// Yarının görevini al
  DailyTask get tomorrowTask {
    return DailyTaskService.getDailyTaskForDate(
        date.add(const Duration(days: 1)));
  }

  /// Dünün görevini al
  DailyTask get yesterdayTask {
    return DailyTaskService.getDailyTaskForDate(
        date.subtract(const Duration(days: 1)));
  }
}
