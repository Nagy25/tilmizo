import 'dart:math';

/// Generates readable invite codes such as `K7QF-3MXP`. Ambiguous characters
/// (0/O, 1/I/L) are excluded. Uniqueness is enforced by the database.
String generateInviteCode([Random? random]) {
  const alphabet = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
  final source = random ?? Random.secure();
  String block() =>
      List.generate(4, (_) => alphabet[source.nextInt(alphabet.length)]).join();
  return '${block()}-${block()}';
}
