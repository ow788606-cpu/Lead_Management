class ServiceManager {
  static final ServiceManager _instance = ServiceManager._internal();
  factory ServiceManager() => _instance;
  ServiceManager._internal();

  final List<String> _services = [];

  List<String> get services => _services;

  void addService(String service) {
    _services.add(service);
  }

  void removeService(int index) {
    if (index >= 0 && index < _services.length) {
      _services.removeAt(index);
    }
  }
}
