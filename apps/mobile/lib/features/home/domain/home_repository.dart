
abstract interface class HomeRepository {
  Future<HomeSummary> getSummary();
}

class HomeSummary {
  const HomeSummary({
    required this.pendingAssignments,
    required this.upcomingClasses,
  });

  final int pendingAssignments;
  final int upcomingClasses;
}
