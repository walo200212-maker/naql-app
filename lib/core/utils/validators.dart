class Validators {
  static String? phone(String? value) {
    if (value == null || value.isEmpty) return 'Numéro requis';
    final cleaned = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (!RegExp(r'^\+?[0-9]{9,15}$').hasMatch(cleaned)) {
      return 'Numéro invalide';
    }
    return null;
  }

  static String? required(String? value, [String field = 'Ce champ']) {
    if (value == null || value.trim().isEmpty) return '$field est requis';
    return null;
  }

  static String? pricePerKm(String? value) {
    if (value == null || value.isEmpty) return 'Prix requis';
    final price = double.tryParse(value);
    if (price == null || price <= 0) return 'Prix invalide';
    if (price > 50) return 'Prix trop élevé (max 50 MAD/km)';
    return null;
  }

  static String? walletTopUp(String? value) {
    if (value == null || value.isEmpty) return 'Montant requis';
    final amount = double.tryParse(value);
    if (amount == null || amount <= 0) return 'Montant invalide';
    if (amount < 50) return 'Montant minimum: 50 MAD';
    if (amount > 5000) return 'Montant maximum: 5000 MAD';
    return null;
  }
}
