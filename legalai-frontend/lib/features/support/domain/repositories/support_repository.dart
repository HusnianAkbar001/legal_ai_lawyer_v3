abstract class SupportRepository {
  Future<void> submitContact(String fullName, String email, String phone, String subject, String description);
  Future<void> submitFeedback(int rating, String comment);
}
