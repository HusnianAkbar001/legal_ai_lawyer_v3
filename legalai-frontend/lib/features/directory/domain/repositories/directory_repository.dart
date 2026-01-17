import '../models/lawyer_model.dart';

abstract class DirectoryRepository {
  Future<List<Lawyer>> getLawyers({int page = 1, int limit = 20, String? city, String? specialization});
}
