class Ticket {
  final String id;
  final String name;
  final String status;
  final DateTime createdAt;
  final DateTime? redeemedAt;

  Ticket({
    required this.id,
    required this.name,
    required this.status,
    required this.createdAt,
    this.redeemedAt,
  });

  factory Ticket.fromJson(Map<String, dynamic> json) {
    return Ticket(
      id: json['id'],
      name: json['name'],
      status: json['status'],
      createdAt: DateTime.parse(json['createdAt']),
      redeemedAt: json['redeemedAt'] != null 
          ? DateTime.parse(json['redeemedAt']) 
          : null,
    );
  }
}