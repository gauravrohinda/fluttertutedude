import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const WeatherApp());
}

class WeatherApp extends StatelessWidget {
  const WeatherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Weather App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const WeatherHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class WeatherHomePage extends StatefulWidget {
  const WeatherHomePage({super.key});

  @override
  State<WeatherHomePage> createState() => _WeatherHomePageState();
}

class _WeatherHomePageState extends State<WeatherHomePage> {
  final TextEditingController _cityController = TextEditingController();
  
  bool _isLoading = false;
  String _errorMessage = '';
  
  String _cityName = 'New Delhi'; // Default city
  double? _temperature;
  double? _windSpeed;
  int? _weatherCode;
  
  @override
  void initState() {
    super.initState();
    // Fetch initial weather for default city
    _fetchWeather(_cityName);
  }
  
  @override
  void dispose() {
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _fetchWeather(String city) async {
    if (city.isEmpty) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // 1. Fetch Coordinates from City Name using Open-Meteo Geocoding API
      final geocodingUrl = Uri.parse('https://geocoding-api.open-meteo.com/v1/search?name=$city&count=1&language=en&format=json');
      final geoResponse = await http.get(geocodingUrl);
      
      if (geoResponse.statusCode != 200) {
        throw Exception('Failed to fetch location data');
      }
      
      final geoData = json.decode(geoResponse.body);
      
      if (!geoData.containsKey('results') || geoData['results'] == null || geoData['results'].isEmpty) {
        throw Exception('City not found');
      }
      
      final location = geoData['results'][0];
      final lat = location['latitude'];
      final lon = location['longitude'];
      final resolvedCityName = location['name'];

      // 2. Fetch Weather using Coordinates from Open-Meteo Weather API
      final weatherUrl = Uri.parse('https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&current_weather=true');
      final weatherResponse = await http.get(weatherUrl);
      
      if (weatherResponse.statusCode != 200) {
        throw Exception('Failed to fetch weather data');
      }
      
      final weatherData = json.decode(weatherResponse.body);
      final current = weatherData['current_weather'];
      
      setState(() {
        _cityName = resolvedCityName;
        _temperature = current['temperature'];
        _windSpeed = current['windspeed'];
        _weatherCode = current['weathercode'];
        _isLoading = false;
      });
      
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  // WMO Weather interpretation codes
  String _getWeatherCondition(int code) {
    if (code == 0) return 'Clear sky';
    if (code == 1 || code == 2 || code == 3) return 'Mainly clear, partly cloudy, and overcast';
    if (code == 45 || code == 48) return 'Fog and depositing rime fog';
    if (code == 51 || code == 53 || code == 55) return 'Drizzle: Light, moderate, and dense intensity';
    if (code == 56 || code == 57) return 'Freezing Drizzle: Light and dense intensity';
    if (code == 61 || code == 63 || code == 65) return 'Rain: Slight, moderate and heavy intensity';
    if (code == 66 || code == 67) return 'Freezing Rain: Light and heavy intensity';
    if (code == 71 || code == 73 || code == 75) return 'Snow fall: Slight, moderate, and heavy intensity';
    if (code == 77) return 'Snow grains';
    if (code == 80 || code == 81 || code == 82) return 'Rain showers: Slight, moderate, and violent';
    if (code == 85 || code == 86) return 'Snow showers slight and heavy';
    if (code == 95) return 'Thunderstorm: Slight or moderate';
    if (code == 96 || code == 99) return 'Thunderstorm with slight and heavy hail';
    return 'Unknown condition';
  }

  IconData _getWeatherIcon(int code) {
    if (code == 0) return Icons.wb_sunny;
    if (code == 1 || code == 2 || code == 3) return Icons.cloud;
    if (code == 45 || code == 48) return Icons.foggy;
    if (code >= 51 && code <= 67) return Icons.water_drop;
    if (code >= 71 && code <= 86) return Icons.ac_unit;
    if (code >= 95 && code <= 99) return Icons.flash_on;
    return Icons.device_unknown;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weather App'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Search Box
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _cityController,
                    decoration: const InputDecoration(
                      hintText: 'Enter city name...',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16),
                    ),
                    onSubmitted: (value) => _fetchWeather(value),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    _fetchWeather(_cityController.text);
                    FocusScope.of(context).unfocus(); // Dismiss keyboard
                  },
                ),
              ],
            ),
            const SizedBox(height: 32),
            
            // Content Area
            Expanded(
              child: Center(
                child: _buildContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Fetching weather data...'),
        ],
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 16),
          Text(
            _errorMessage,
            style: const TextStyle(color: Colors.red, fontSize: 18),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _fetchWeather(_cityController.text.isNotEmpty ? _cityController.text : _cityName),
            child: const Text('Retry'),
          ),
        ],
      );
    }

    if (_temperature == null || _weatherCode == null) {
      return const Text('Search for a city to see the weather.');
    }

    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _getWeatherIcon(_weatherCode!),
            size: 100,
            color: Colors.blue.shade700,
          ),
          const SizedBox(height: 16),
          Text(
            _cityName,
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            '${_temperature!.toStringAsFixed(1)}°C',
            style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w300),
          ),
          const SizedBox(height: 8),
          Text(
            _getWeatherCondition(_weatherCode!),
            style: TextStyle(fontSize: 18, color: Colors.grey.shade700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.air, color: Colors.grey),
              const SizedBox(width: 8),
              Text(
                'Wind: ${_windSpeed} km/h',
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
