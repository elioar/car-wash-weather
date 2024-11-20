import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'dart:async';
import 'dart:ui' as ui;
import 'package:geolocator/geolocator.dart';
import 'pages/tips_page.dart';
import 'pages/onboarding_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('el', null);
  Intl.defaultLocale = 'el';
  
  runApp(const MyApp(hasSeenOnboarding: false));
}

class MyApp extends StatelessWidget {
  final bool hasSeenOnboarding;
  
  const MyApp({super.key, required this.hasSeenOnboarding});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Car Wash Weather',
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('el', ''),
        Locale('en', ''),
      ],
      locale: const Locale('el', ''),
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.transparent,
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFF6C63FF),
          secondary: const Color(0xFF00D4FF),
          surface: const Color(0xFF1A1A1A),
          onSurface: Colors.white.withOpacity(0.1),
        ),
        cardTheme: CardTheme(
          color: Colors.white.withOpacity(0.1),
          elevation: 0,
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
          bodyMedium: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w400,
          ),
          titleLarge: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
          titleMedium: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        useMaterial3: true,
      ),
      home: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0A0A0A),
              Color(0xFF151515),
            ],
            stops: [0.0, 1.0],
          ),
        ),
        child: hasSeenOnboarding 
            ? const WeatherForecastScreen()
            : const OnboardingPage(),
      ),
    );
  }
}

class WeatherForecastScreen extends StatefulWidget {
  const WeatherForecastScreen({super.key});

  @override
  State<WeatherForecastScreen> createState() => _WeatherForecastScreenState();
}

class _WeatherForecastScreenState extends State<WeatherForecastScreen> with SingleTickerProviderStateMixin {
  // State variables
  List<dynamic> _weatherData = [];
  String _cityName = 'Αθήνα, GR';
  List<dynamic> _searchResults = [];
  bool _isSearching = false;
  bool _isLoadingLocation = false;
  String? _locationError;

  // Controllers
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  late final ScrollController _scrollController;
  late final AnimationController _animationController;
  late final Animation<double> _animation;
  Timer? _debounce;

  // Data
  final List<Map<String, dynamic>> _savedLocations = [
    {'name': 'Αθήνα', 'country': 'GR', 'lat': '37.9838', 'lon': '23.7275'},
    {'name': 'Θεσσαλονίκη', 'country': 'GR', 'lat': '40.6401', 'lon': '22.9444'},
    {'name': 'Πάτρα', 'country': 'GR', 'lat': '38.2466', 'lon': '21.7346'},
  ];

  late PageController _pageController;

  // Πρθήκη μεταβλητής για το τρέχον index
  int _currentPageIndex = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _searchController.addListener(_onSearchChanged);
    _scrollController = ScrollController();

    _initializeLocation();
    _pageController = PageController(viewportFraction: 1.0);
    _pageController.addListener(() {
      int next = _pageController.page!.round();
      if (_currentPageIndex != next) {
        setState(() {
          _currentPageIndex = next;
        });
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _debounce?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _scrollController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (_searchController.text.length >= 2) {
        _searchLocation(_searchController.text);
      } else {
        setState(() {
          _searchResults = [];
        });
      }
    });
  }

  Future<void> _searchLocation(String query) async {
    const apiKey = '84fc5e6caa77a1297513bc29bd1dfae5';
    final url = 'https://api.openweathermap.org/geo/1.0/direct?q=$query&limit=5&appid=$apiKey';

    try {
      setState(() {
        _isSearching = true;
      });

      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _searchResults = data;
          _isSearching = false;
        });
      } else {
        setState(() {
          _isSearching = false;
        });
      }
    } catch (e) {
      setState(() {
        _isSearching = false;
      });
    }
  }

  Future<void> _selectLocation(dynamic location, {bool addToSaved = false}) async {
    _searchController.clear();
    setState(() {
      _searchResults = [];
      _cityName = '${location['name']}, ${location['country']}';
    });

    if (addToSaved) {
      _addToSavedLocations(location);
    }

    await _fetchWeatherDataForLocation(
      location['lat'].toString(),
      location['lon'].toString(),
    );
    _animationController.reverse();
  }

  Future<void> _fetchWeatherDataForLocation(String lat, String lon) async {
    const apiKey = '84fc5e6caa77a1297513bc29bd1dfae5';
    final url = 'https://api.openweathermap.org/data/2.5/forecast?lat=$lat&lon=$lon&appid=$apiKey&units=metric&cnt=56';

    if (!mounted) return;

    try {
      setState(() {
        _isLoadingLocation = true;
      });

      final response = await http.get(Uri.parse(url));
      if (!mounted) return;
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final groupedData = _groupForecastByDay(data['list']);
        setState(() {
          _weatherData = groupedData;
          _isLoadingLocation = false;
        });
      } else {
        if (mounted) {
          setState(() {
            _isLoadingLocation = false;
          });
          _showErrorSnackBar('Αποτυχία λήψης δεδομένων καιρού');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
        });
        _showErrorSnackBar('Σφάλμα: $e');
      }
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  List<Map<String, dynamic>> _groupForecastByDay(List<dynamic> forecastList) {
    final Map<String, Map<String, dynamic>> groupedData = {};
    
    for (var forecast in forecastList) {
      final date = DateTime.parse(forecast['dt_txt']).toLocal();
      final dateKey = DateFormat('yyyy-MM-dd').format(date);
      
      if (!groupedData.containsKey(dateKey)) {
        groupedData[dateKey] = forecast;
      }
    }
    
    // Πάρε τις πρώτες 6 μέρες τ για 5
    return groupedData.values.take(6).toList();
  }

  String _getWeatherAdvice(Map<String, dynamic> weatherData) {
    final weather = weatherData['weather'][0]['main'].toString().toLowerCase();
    final temp = weatherData['main']['temp'];
    final pop = (weatherData['pop'] * 100).round(); // Probability of precipitation
    
    if (weather.contains('rain') || weather.contains('drizzle')) {
      return 'Ακατάλλη μέρα ια πλύσιο ❌';
    } else if (pop >= 40) {
      return 'Καλύτερα όχι σήμερα ⚠️';
    } else if (weather.contains('snow')) {
      return 'Πολ κρύο για πλύσιμο ️';
    } else if (temp < 10) {
      return 'Πολύ κρύο για πλύσιμο 🥶';
    } else if (weather.contains('clear') && temp > 10 && temp < 30 && pop < 20) {
      return 'Ιδανική μέρ για πλύσιμο! ✨';
    } else if (pop < 30) {
      return 'Αποδεκτή μέρα για πλύσιμο 👍';
    } else {
      return 'Μέτριες συθήκες ι πλύσιμο ⚠️';
    }
  }

  void _addToSavedLocations(Map<String, dynamic> location) {
    if (!_savedLocations.any((loc) => 
        loc['name'] == location['name'] && loc['country'] == location['country'])) {
      setState(() {
        _savedLocations.add({
          'name': location['name'],
          'country': location['country'],
          'lat': location['lat'].toString(),
          'lon': location['lon'].toString(),
        });
      });
    }
  }

  void _removeFromSavedLocations(int index) {
    setState(() {
      _savedLocations.removeAt(index);
    });
  }

  bool _isCurrentLocationSaved() {
    final currentCity = _cityName.split(',')[0].trim();
    final currentCountry = _cityName.split(',')[1].trim();
    return _savedLocations.any((loc) => 
        loc['name'] == currentCity && loc['country'] == currentCountry);
  }

  void _toggleSaveCurrentLocation() {
    final currentCity = _cityName.split(',')[0].trim();
    final currentCountry = _cityName.split(',')[1].trim();
    
    if (_isCurrentLocationSaved()) {
      // Remove from saved locations
      setState(() {
        _savedLocations.removeWhere((loc) => 
            loc['name'] == currentCity && loc['country'] == currentCountry);
      });
    } else {
      // Find the current location's coordinates from the search results or weather data
      String? currentLat;
      String? currentLon;
      
      // First try to get coordinates from search results
      final matchingResult = _searchResults.firstWhere(
        (result) => result['name'] == currentCity && result['country'] == currentCountry,
        orElse: () => null,
      );
      
      if (matchingResult != null) {
        currentLat = matchingResult['lat'].toString();
        currentLon = matchingResult['lon'].toString();
      } else {
        // If not found in search results, use default coordinates for Athens
        currentLat = '37.9838';
        currentLon = '23.7275';
      }
          
      _addToSavedLocations({
        'name': currentCity,
        'country': currentCountry,
        'lat': currentLat,
        'lon': currentLon,
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    if (!mounted) return;

    setState(() {
      _isLoadingLocation = true;
      _locationError = null;
    });

    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        final requestPermission = await Geolocator.requestPermission();
        if (requestPermission == LocationPermission.denied) {
          throw Exception('Η άδεια τποθεσίας πορρίφθηκε');
        }
      }

      // Νέος τρόπος ορισμού ακρίβειας τοποθεσίας
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 5),
        ),
      );

      if (!mounted) return;

      const apiKey = '84fc5e6caa77a1297513bc29bd1dfae5';
      final url = 'https://api.openweathermap.org/geo/1.0/reverse?lat=${position.latitude}&lon=${position.longitude}&limit=1&appid=$apiKey';

      final response = await http.get(Uri.parse(url));
      if (!mounted) return;

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (data.isNotEmpty) {
          final location = data[0];
          await _selectLocation(location);
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _locationError = e.toString();
      });
      _showErrorSnackBar('Σφάλμα: $_locationError');
    }

    if (mounted) {
      setState(() {
        _isLoadingLocation = false;
      });
    }
  }

  void _showSearchDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.9),
      useSafeArea: true,
      barrierDismissible: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Material(
          color: Colors.transparent,
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(
                  top: 60,
                  left: 16,
                  right: 16,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF5c258d).withOpacity(0.2),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Search Header
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Icon(
                            Icons.search,
                            color: Colors.white.withOpacity(0.7),
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Αναζήτηση Πόλης',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: Icon(
                              Icons.close,
                              color: Colors.white.withOpacity(0.7),
                              size: 24,
                            ),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                    ),
                    // Search Input
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: TextField(
                                controller: _searchController,
                                autofocus: true,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Πληκτρολογήστε μια πόλη...',
                                  hintStyle: TextStyle(
                                    color: Colors.white.withOpacity(0.3),
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                ),
                                onChanged: (value) {
                                  if (value.length >= 2) {
                                    _searchLocation(value).then((_) {
                                      setDialogState(() {});
                                    });
                                  } else {
                                    setDialogState(() {
                                      _searchResults = [];
                                    });
                                  }
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF5c258d).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: IconButton(
                              icon: _isLoadingLocation
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Icon(
                                      Icons.gps_fixed,
                                      color: Colors.white.withOpacity(0.9),
                                    ),
                              onPressed: _isLoadingLocation 
                                  ? null 
                                  : () async {
                                      final navigator = Navigator.of(context);
                                      setDialogState(() {
                                        _isLoadingLocation = true;
                                      });
                                      
                                      await _getCurrentLocation();
                                      
                                      if (mounted) {
                                        setDialogState(() {
                                          _isLoadingLocation = false;
                                        });
                                        navigator.pop();
                                      }
                                    },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
              if (_searchResults.isNotEmpty)
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(
                      top: 8,
                      left: 16,
                      right: 16,
                      bottom: 16,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      itemCount: _searchResults.length,
                      physics: const BouncingScrollPhysics(),
                      itemBuilder: (context, index) {
                        final result = _searchResults[index];
                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () async {
                              final navigator = Navigator.of(context);
                              _addToSavedLocations({
                                'name': result['name'],
                                'country': result['country'],
                                'lat': result['lat'].toString(),
                                'lon': result['lon'].toString(),
                              });
                              
                              await _selectLocation(result);
                              
                              if (mounted) {
                                navigator.pop();
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 16,
                              ),
                              decoration: BoxDecoration(
                                border: index != _searchResults.length - 1
                                    ? Border(
                                        bottom: BorderSide(
                                          color: Colors.white.withOpacity(0.05),
                                        ),
                                      )
                                    : null,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF5c258d).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      Icons.location_on,
                                      color: Colors.white.withOpacity(0.9),
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${result['name']}, ${result['country']}',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.white,
                                          ),
                                        ),
                                        if (result['state'] != null)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 4),
                                            child: Text(
                                              result['state'],
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.white.withOpacity(0.5),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.add_circle_outline,
                                    color: Colors.white.withOpacity(0.5),
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_weatherData.isEmpty) {
      return const WeatherLoadingScreen();
    }
    
    const searchBarHeight = 56.0;
    final screenSize = MediaQuery.of(context).size;
    
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        setState(() {
          _searchResults = [];
        });
        _animationController.reverse();
      },
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 120,
          flexibleSpace: ClipRRect(
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF2A2A2A).withOpacity(0.8),
                      const Color(0xFF1A1A1A).withOpacity(0.6),
                    ],
                  ),
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.white.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    children: [
                      // City name and actions
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF43cea2).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.directions_car,
                                size: 20,
                                color: Color(0xFF9575CD),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _cityName.length > 20 
                                    ? '${_cityName.substring(0, 17)}...' 
                                    : _cityName,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                  letterSpacing: 0.3,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  icon: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF43cea2).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      Icons.search,
                                      color: Colors.white.withOpacity(0.9),
                                      size: 20,
                                    ),
                                  ),
                                  onPressed: () => _showSearchDialog(context),
                                ),
                                const SizedBox(width: 12),
                                IconButton(
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  icon: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF43cea2).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      _isCurrentLocationSaved() 
                                          ? Icons.favorite 
                                          : Icons.favorite_border,
                                      color: Colors.white.withOpacity(0.9),
                                      size: 20,
                                    ),
                                  ),
                                  onPressed: _toggleSaveCurrentLocation,
                                ),
                                IconButton(
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  icon: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF43cea2).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      Icons.settings,
                                      color: Colors.white.withOpacity(0.9),
                                      size: 20,
                                    ),
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => const SettingsPage()),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Saved locations
                      if (_savedLocations.isNotEmpty)
                        Container(
                          height: 40,
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _savedLocations.length,
                            itemBuilder: (context, index) {
                              final location = _savedLocations[index];
                              return Container(
                                margin: const EdgeInsets.only(right: 8),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(12),
                                    onTap: () => _selectLocation(location),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF43cea2).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: const Color(0xFF43cea2).withOpacity(0.3),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            location['name'],
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          InkWell(
                                            borderRadius: BorderRadius.circular(12),
                                            onTap: () => _removeFromSavedLocations(index),
                                            child: Icon(
                                              Icons.close,
                                              color: Colors.white.withOpacity(0.7),
                                              size: 16,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        body: Stack(
          children: [
            RefreshIndicator(
              onRefresh: () async {
                final currentLocation = _savedLocations.firstWhere(
                  (loc) => '${loc['name']}, ${loc['country']}' == _cityName,
                  orElse: () => {
                    'lat': '37.9838',
                    'lon': '23.7275',
                  },
                );
                
                await _fetchWeatherDataForLocation(
                  currentLocation['lat'],
                  currentLocation['lon'],
                );
              },
              color: const Color(0xFF43cea2),
              backgroundColor: const Color(0xFF1A1A1A),
              strokeWidth: 2.5,
              displacement: 20,
              child: SingleChildScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 160,
                      child: PageView.builder(
                        controller: _pageController,
                        itemCount: _weatherData.length,
                        onPageChanged: (index) {
                          setState(() {
                            _currentPageIndex = index;
                          });
                        },
                        itemBuilder: (context, index) {
                          final weatherData = _weatherData[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: _buildWeatherCard(weatherData),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Dots Indicator
                    SizedBox(
                      height: 30,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: _weatherData.asMap().entries.map((entry) {
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            height: 3,
                            width: entry.key == _currentPageIndex ? 12 : 3,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(1.5),
                              color: Colors.white.withOpacity(
                                entry.key == _currentPageIndex ? 0.9 : 0.3,
                              ),
                              boxShadow: entry.key == _currentPageIndex
                                  ? [
                                      BoxShadow(
                                        color: Colors.white.withOpacity(0.3),
                                        blurRadius: 3,
                                        spreadRadius: 0.5,
                                      ),
                                    ]
                                  : null,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildBestDaysCalendar(),
                    _buildNextWashCard(),
                    _buildTipsButton(context),
                  ],
                ),
              ),
            ),
            if (_searchResults.isNotEmpty)
              Positioned(
                top: searchBarHeight + 32,
                left: 16,
                right: 16,
                child: FadeTransition(
                  opacity: _animation,
                  child: Material(
                    elevation: 8,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      constraints: BoxConstraints(
                        maxHeight: screenSize.height * 0.4,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF232526),
                            Color(0xFF414345),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final result = _searchResults[index];
                          return InkWell(
                            onTap: () {
                              _selectLocation(result);
                              FocusScope.of(context).unfocus();
                              _animationController.reverse();
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                border: index != _searchResults.length - 1
                                    ? Border(
                                        bottom: BorderSide(
                                          color: Colors.white.withOpacity(0.1),
                                          width: 1,
                                        ),
                                      )
                                    : null,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    color: Colors.white.withOpacity(0.9),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${result['name']}, ${result['country']}',
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.white.withOpacity(0.9),
                                          ),
                                        ),
                                        if (result['state'] != null)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 4),
                                            child: Text(
                                              result['state'],
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.white.withOpacity(0.7),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.arrow_forward_ios,
                                    color: Colors.white.withOpacity(0.5),
                                    size: 14,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            if (_isSearching)
              const Positioned(
                top: searchBarHeight + 16,
                left: 0,
                right: 0,
                child: LinearProgressIndicator(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherCard(Map<String, dynamic> weatherData) {
    final dateTime = DateTime.parse(weatherData['dt_txt']);
    final temp = weatherData['main']['temp'].round();
    final description = weatherData['weather'][0]['description'];
    final pop = (weatherData['pop'] * 100).round();
    final humidity = weatherData['main']['humidity'];
    final advice = _getWeatherAdvice(weatherData);
    final isGoodDay = advice.contains('Ιδανική') || advice.contains('Αποδεκτή');
    
    // Dummy data for AQI and Pollen Levels
    final aqi = 42; // Example AQI value
    final aqiDescription = 'Good'; // Example AQI description
    final pollenLevel = 'Moderate'; // Example pollen level

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Πρώτη γραμμή: Ημερομηνία και Θερμοκρασία
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Ημερομηνία
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('EEEE', 'el').format(dateTime),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        DateFormat('d MMMM', 'el').format(dateTime),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                  // Θερμοκρασία
                  Text(
                    '$temp°C',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Δεύτερη γραμμή: Καιρός, Βροχή, Υγρασία
              Row(
                children: [
                  // Καιρός
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isGoodDay 
                            ? const Color(0xFF43cea2).withOpacity(0.1)
                            : const Color(0xFFed213a).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isGoodDay 
                              ? const Color(0xFF43cea2).withOpacity(0.3)
                              : const Color(0xFFed213a).withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isGoodDay ? Icons.wash : Icons.not_interested_rounded,
                            size: 16,
                            color: isGoodDay 
                                ? const Color(0xFF43cea2)
                                : const Color(0xFFed213a),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              description,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: isGoodDay 
                                    ? const Color(0xFF43cea2)
                                    : const Color(0xFFed213a),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Βροχή και Υγρασία
                  _buildWeatherInfo(Icons.water_drop_rounded, '$pop%', const Color(0xFF00D4FF)),
                  const SizedBox(width: 8),
                  _buildWeatherInfo(Icons.water_rounded, '$humidity%', const Color(0xFF6C63FF)),
                ],
              ),
              const SizedBox(height: 16),
              // Νέο στοιχείο καταλληλότητας
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isGoodDay 
                      ? const Color(0xFF43cea2).withOpacity(0.15)
                      : const Color(0xFFed213a).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isGoodDay 
                        ? const Color(0xFF43cea2).withOpacity(0.3)
                        : const Color(0xFFed213a).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isGoodDay ? Icons.check_circle_outline : Icons.cancel_outlined,
                      size: 16,
                      color: isGoodDay 
                          ? const Color(0xFF43cea2)
                          : const Color(0xFFed213a),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isGoodDay ? 'Κατάλληλη για πλύσιμο' : 'Ακατάλληλη για πλύσιμο',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isGoodDay 
                            ? const Color(0xFF43cea2)
                            : const Color(0xFFed213a),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Δείκτης Ποιότητας Αέρα (AQI)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF00D4FF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF00D4FF).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.air,
                      size: 16,
                      color: const Color(0xFF00D4FF),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'AQI: $aqi ($aqiDescription)',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Επίπεδα Γύρης
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFC107).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFFFC107).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.grass,
                      size: 16,
                      color: const Color(0xFFFFC107),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Pollen: $pollenLevel',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeatherInfo(IconData icon, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _initializeLocation() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        final requestPermission = await Geolocator.requestPermission();
        if (requestPermission == LocationPermission.denied) {
          // Αν δεν δοθεί άδεια, χρησιμοποίησε την Αθήνα ως προεπιλογή
          _fetchWeatherDataForLocation('37.9838', '23.7275');
          return;
        }
      }

      setState(() {
        _isLoadingLocation = true;
      });

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 5),
        ),
      );

      if (!mounted) return;

      const apiKey = '84fc5e6caa77a1297513bc29bd1dfae5';
      final url = 'https://api.openweathermap.org/geo/1.0/reverse?lat=${position.latitude}&lon=${position.longitude}&limit=1&appid=$apiKey';

      final response = await http.get(Uri.parse(url));
      if (!mounted) return;

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (data.isNotEmpty) {
          final location = data[0];
          setState(() {
            _cityName = '${location['name']}, ${location['country']}';
          });
          await _fetchWeatherDataForLocation(
            position.latitude.toString(),
            position.longitude.toString(),
          );
        }
      }
    } catch (e) {
      // Σε περίπτωση σφάλματος, χρησιμοποίησε την Αθήνα ως προεπιλογή
      if (mounted) {
        _fetchWeatherDataForLocation('37.9838', '23.7275');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
        });
      }
    }
  }

  Widget _buildBestDaysCalendar() {
    List<Map<String, dynamic>> sortedDays = List<Map<String, dynamic>>.from(_weatherData);
    
    // Ταξινόμηση με βάση την ημερομηνία
    sortedDays.sort((a, b) {
      final aDate = DateTime.parse(a['dt_txt']);
      final bDate = DateTime.parse(b['dt_txt']);
      return aDate.compareTo(bDate);
    });
    
    // Πάρε τις πρώτες 5 μέρες
    sortedDays = sortedDays.take(5).toList();

    bool checkIfGoodDay(Map<String, dynamic> day) {
      final advice = _getWeatherAdvice(day);
      return advice.contains('Ιδανική') || advice.contains('Αποδεκτή');
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.wash_outlined,
                  size: 12,
                  color: Colors.white70,
                ),
                SizedBox(width: 6),
                Text(
                  'Προτεινόμενες μέρες',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.white70,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(sortedDays.length, (index) {
              final day = sortedDays[index];
              final date = DateTime.parse(day['dt_txt']);
              final isGoodDay = checkIfGoodDay(day);

              return Container(
                width: 60,
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isGoodDay 
                        ? const Color(0xFF43cea2).withOpacity(0.3)
                        : Colors.white.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      DateFormat('E', 'el').format(date).substring(0, 3).toUpperCase(),
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withOpacity(0.5),
                        letterSpacing: 0.5,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      DateFormat('d', 'el').format(date),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.white.withOpacity(0.9),
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: isGoodDay 
                            ? const Color(0xFF43cea2).withOpacity(0.15)
                            : Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        isGoodDay ? Icons.check_rounded : Icons.close_rounded,
                        size: 10,
                        color: isGoodDay 
                            ? const Color(0xFF43cea2)
                            : const Color(0xFFed213a),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildNextWashCard() {
    final todayWeather = _weatherData.isNotEmpty ? _weatherData[0] : null;
    final washScore = _calculateWashScore(todayWeather);
    final advice = _getWashAdvice(washScore);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _getScoreColor(washScore).withOpacity(0.2),
            _getScoreColor(washScore).withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getScoreColor(washScore).withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getScoreColor(washScore).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.directions_car,
                  size: 20,
                  color: Color(0xFF9575CD),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Καταλληλότητα',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.today,
                      color: Colors.white.withOpacity(0.7),
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Σήμερα',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _getScoreIcon(washScore),
                          color: _getScoreColor(washScore),
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$washScore%',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      advice,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Stack(
                  children: [
                    // Background progress bar
                    Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    // Actual progress bar
                    FractionallySizedBox(
                      widthFactor: washScore / 100,
                      child: Container(
                        height: 8,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              _getScoreColor(washScore),
                              _getScoreColor(washScore).withOpacity(0.7),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: [
                            BoxShadow(
                              color: _getScoreColor(washScore).withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '0%',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white.withOpacity(0.5),
                      ),
                    ),
                    Text(
                      '100%',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  int _calculateWashScore(Map<String, dynamic>? weather) {
    if (weather == null) return 0;
    
    final temp = (weather['main']['temp'] as num).toDouble();
    final weatherMain = weather['weather'][0]['main'].toString().toLowerCase();
    final pop = ((weather['pop'] as num) * 100).round();
    
    int score = 100;
    
    // Μείωση βάσει θερμοκρασίας
    if (temp < 5 || temp > 35) {
      score -= 50;
    } else if (temp < 10 || temp > 30) {
      score -= 25;
    }
    
    // Μείωση βάσει καιρού
    if (weatherMain.contains('rain')) {
      score -= 80;
    } else if (weatherMain.contains('drizzle')) {
      score -= 60;
    } else if (weatherMain.contains('snow')) {
      score -= 100;
    } else if (weatherMain.contains('cloud')) {
      score -= 20;
    }
    
    // Μείωση βάσει πιθανότητα βροχής
    score -= pop ~/ 2;
    
    return score.clamp(0, 100); // Περιορισμός μεταξύ 0 και 100
  }

  String _getWashAdvice(int score) {
    if (score >= 80) return 'Ιδανική μέρα για πλύσιμο!';
    if (score >= 60) return 'Καλή μέρα για πλύσιμο';
    if (score >= 40) return 'Μέτριες συνθήκες';
    if (score >= 20) return 'Όχι ιδανικές συνθήκες';
    return 'Ακατάλληλη μέρα';
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return const Color(0xFF43cea2); // Πράσινο
    if (score >= 60) return const Color(0xFF64B5F6); // Μπλε
    if (score >= 40) return const Color(0xFFFFB74D); // Πορτοκαλί
    if (score >= 20) return const Color(0xFFFF7043); // Κόκκινο-πορτοκαλί
    return const Color(0xFFE57373); // Κόκκινο
  }

  IconData _getScoreIcon(int score) {
    if (score >= 80) return Icons.check_circle;
    if (score >= 60) return Icons.thumb_up;
    if (score >= 40) return Icons.warning;
    if (score >= 20) return Icons.warning_amber;
    return Icons.cancel;
  }

  Widget _buildTipsButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CarWashTipsPage()),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF43cea2).withOpacity(0.2),
              const Color(0xFF185a9d).withOpacity(0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF43cea2).withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF43cea2).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.car_repair,
                color: Colors.white.withOpacity(0.9),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Συμβουλές πλυσίματς',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Μάθετε πώς να πλένετε το αυτοκίνητό σας σωστά',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.white.withOpacity(0.7),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

class WeatherLoadingScreen extends StatefulWidget {
  const WeatherLoadingScreen({super.key});

  @override
  State<WeatherLoadingScreen> createState() => _WeatherLoadingScreenState();
}

class _WeatherLoadingScreenState extends State<WeatherLoadingScreen> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0A0A0A),
            Color(0xFF151515),
          ],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: const Color(0xFF1A1A1A),
          elevation: 0,
          flexibleSpace: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  _buildShimmerBox(40, 40, radius: 12),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildShimmerBox(120, 20, radius: 6),
                  ),
                  const SizedBox(width: 12),
                  _buildShimmerBox(40, 40, radius: 12),
                ],
              ),
            ),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildShimmerBox(double.infinity, 220, radius: 24),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildShimmerBox(150, 24, radius: 12),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(
                        5,
                        (index) => _buildShimmerBox(60, 80, radius: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildShimmerBox(double.infinity, 160, radius: 16),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildShimmerBox(double.infinity, 80, radius: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerBox(double width, double height, {double radius = 8}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.white.withOpacity(0.05),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.5, 1.0],
                    begin: const Alignment(-2.0, -0.0),
                    end: const Alignment(2.0, 0.0),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: -2.0, end: 2.0),
                duration: const Duration(milliseconds: 1500),
                builder: (context, value, child) {
                  return DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.white.withOpacity(0.05),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.5, 1.0],
                        begin: Alignment(value, 0.0),
                        end: Alignment(value + 2.0, 0.0),
                      ),
                    ),
                  );
                },
                onEnd: () {
                  if (mounted) {
                    setState(() {});
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ρυθμίσεις'),
      ),
      body: Center(
        child: const Text('Εδώ μπορείτε να προσθέσετε τις ρυθμίσεις σας.'),
      ),
    );
  }
}
