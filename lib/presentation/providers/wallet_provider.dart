import 'package:flutter/foundation.dart';
import '../../data/models/transaction_model.dart';
import '../../data/models/topup_model.dart';
import '../../data/services/firestore_service.dart';

class WalletProvider extends ChangeNotifier {
  final FirestoreService _firestore = FirestoreService();

  List<TransactionModel> _transactions = [];
  List<TopUpModel> _topUps = [];
  bool _isLoading = false;
  String? _error;
  bool _topUpSubmitted = false;

  List<TransactionModel> get transactions => _transactions;
  List<TopUpModel> get topUps => _topUps;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get topUpSubmitted => _topUpSubmitted;

  void watchTransactions(String driverId) {
    _firestore.watchDriverTransactions(driverId).listen((txs) {
      _transactions = txs;
      notifyListeners();
    });
    _firestore.watchDriverTopUps(driverId).listen((tops) {
      _topUps = tops;
      notifyListeners();
    });
  }

  Future<void> submitTopUp({
    required String driverId,
    required double amount,
    required String reference,
  }) async {
    _setLoading(true);
    _topUpSubmitted = false;
    try {
      await _firestore.submitTopUp(TopUpModel(
        id: '',
        driverId: driverId,
        amount: amount,
        reference: reference,
        status: 'pending',
        createdAt: DateTime.now(),
      ));
      _topUpSubmitted = true;
    } catch (e) {
      _error = e.toString();
    }
    _setLoading(false);
  }

  void resetTopUpState() {
    _topUpSubmitted = false;
    notifyListeners();
  }

  void _setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }
}
