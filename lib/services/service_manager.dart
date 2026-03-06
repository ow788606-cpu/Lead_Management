import 'package:flutter/foundation.dart';

import 'service_api.dart';

class ServiceManager extends ChangeNotifier {
  static final ServiceManager _instance = ServiceManager._internal();
  factory ServiceManager() => _instance;
  ServiceManager._internal() {
    refreshServices();
  }

  final List<ServiceItem> _items = [];

  List<String> get services => _items.map((item) => item.name).toList();

  Future<void> refreshServices() async {
    final fetched = await ServiceApi.fetchServices();
    _items
      ..clear()
      ..addAll(fetched);
    notifyListeners();
  }

  Future<void> addService(String service, {int userId = 1}) async {
    final normalized = service.trim();
    if (normalized.isEmpty) return;
    await ServiceApi.addService(serviceName: normalized, userId: userId);
    await refreshServices();
  }

  Future<void> removeService(int index) async {
    if (index >= 0 && index < _items.length) {
      await ServiceApi.deleteService(_items[index].id);
      await refreshServices();
    }
  }
}
