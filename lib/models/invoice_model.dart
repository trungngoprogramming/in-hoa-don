class InvoiceItem {
  final String name;
  final int quantity;
  final double price;
  final double total;

  InvoiceItem({
    required this.name,
    required this.quantity,
    required this.price,
    required this.total,
  });

  InvoiceItem copyWith({
    String? name,
    int? quantity,
    double? price,
    double? total,
  }) {
    return InvoiceItem(
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      total: total ?? this.total,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'quantity': quantity,
      'price': price,
      'total': total,
    };
  }

  factory InvoiceItem.fromJson(Map<String, dynamic> json) {
    return InvoiceItem(
      name: json['name'] ?? '',
      quantity: json['quantity'] ?? 0,
      price: (json['price'] ?? 0).toDouble(),
      total: (json['total'] ?? 0).toDouble(),
    );
  }
}

class InvoiceModel {
  final String customerName;
  final List<InvoiceItem> items;
  final DateTime createdAt;

  InvoiceModel({
    required this.customerName,
    required this.items,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  double get totalAmount {
    return items.fold(0.0, (sum, item) => sum + item.total);
  }

  InvoiceModel copyWith({
    String? customerName,
    List<InvoiceItem>? items,
    DateTime? createdAt,
  }) {
    return InvoiceModel(
      customerName: customerName ?? this.customerName,
      items: items ?? this.items,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory InvoiceModel.empty() {
    return InvoiceModel(
      customerName: '',
      items: [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'customerName': customerName,
      'items': items.map((item) => item.toJson()).toList(),
      'totalAmount': totalAmount,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory InvoiceModel.fromJson(Map<String, dynamic> json) {
    return InvoiceModel(
      customerName: json['customerName'] ?? '',
      items: (json['items'] as List<dynamic>?)
              ?.map((item) => InvoiceItem.fromJson(item))
              .toList() ??
          [],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }
}
