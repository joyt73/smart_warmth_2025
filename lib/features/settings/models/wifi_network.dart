// lib/features/settings/models/wifi_network.dart
class WifiNetwork {
  final String ssid;
  final String password;

  WifiNetwork({
    required this.ssid,
    required this.password,
  });

  factory WifiNetwork.fromJson(Map<String, dynamic> json) {
    return WifiNetwork(
      ssid: json['ssid'] as String,
      password: json['password'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ssid': ssid,
      'password': password,
    };
  }

  WifiNetwork copyWith({
    String? ssid,
    String? password,
  }) {
    return WifiNetwork(
      ssid: ssid ?? this.ssid,
      password: password ?? this.password,
    );
  }
}