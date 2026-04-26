class MenuItem {
  final String id, name, description, image, category;
  final double price;
  MenuItem({required this.id, required this.name, required this.description, required this.price, required this.image, required this.category});
}

class Restaurant {
  final String id, name, time, deliveryFee, image;
  final double rating;
  final bool isElite, isCashOnly;
  final String? statusText, description;

  Restaurant({required this.id, required this.name, required this.rating, required this.time, required this.deliveryFee, required this.image, this.isElite = false, this.isCashOnly = false, this.statusText, this.description});
}

final List<Map<String, dynamic>> categories = [
  {"label": "Pizza", "icon": "Pizza"},
  {"label": "Sushi", "icon": "Fish"},
  {"label": "Burgers", "icon": "Utensils"},
  {"label": "Ramen", "icon": "Soup"},
  {"label": "Desserts", "icon": "IceCream"},
];

