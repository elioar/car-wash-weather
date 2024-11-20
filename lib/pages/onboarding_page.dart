import 'package:flutter/material.dart';
import '../main.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _pages = [
    {
      'title': 'Καλώς ήρθατε στο\nCarWash Weather',
      'description': 'Η εφαρμογή που σας βοηθά να επιλέξετε την καλύτερη μέρα για να πλύνετε το αυτοκίνητό σας.',
      'icon': Icons.wb_sunny_outlined,
      'gradient': [const Color(0xFF43cea2), const Color(0xFF185a9d)],
    },
    {
      'title': 'Έξυπνη Πρόγνωση\nΚαιρού',
      'description': 'Λάβετε ακριβείς προβλέψεις καιρού για τις επόμενες 5 ημέρες και δείτε ποιες μέρες είναι κατάλληλες για πλύσιμο.',
      'icon': Icons.calendar_today_outlined,
      'gradient': [const Color(0xFF2193b0), const Color(0xFF6dd5ed)],
    },
    {
      'title': 'Έξυπνες\nΕιδοποιήσεις',
      'description': 'Λάβετε ειδοποιήσεις για τις ιδανικές μέρες πλυσίματος με βάση τον καιρό της περιοχής σας.',
      'icon': Icons.notifications_outlined,
      'gradient': [const Color(0xFF11998e), const Color(0xFF38ef7d)],
    },
    {
      'title': 'Συμβουλές &\nΟδηγίες',
      'description': 'Ανακαλύψτε χρήσιμες συμβουλές για το σωστό πλύσιμο του αυτοκινήτου σας.',
      'icon': Icons.tips_and_updates_outlined,
      'gradient': [const Color(0xFF4e54c8), const Color(0xFF8f94fb)],
    },
  ];

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Stack(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _pages[_currentPage]['gradient'][0].withOpacity(0.15),
                  _pages[_currentPage]['gradient'][1].withOpacity(0.05),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (int page) {
                      setState(() {
                        _currentPage = page;
                      });
                    },
                    itemCount: _pages.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: size.width * 0.25,
                              height: size.width * 0.25,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: _pages[index]['gradient'],
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(2),
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.black.withOpacity(0.8),
                                  ),
                                  child: Icon(
                                    _pages[index]['icon'],
                                    size: size.width * 0.1,
                                    color: _pages[index]['gradient'][0],
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: size.height * 0.04),
                            ShaderMask(
                              shaderCallback: (bounds) => LinearGradient(
                                colors: _pages[index]['gradient'],
                              ).createShader(bounds),
                              child: Text(
                                _pages[index]['title'],
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 24,
                                  height: 1.2,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            SizedBox(height: size.height * 0.02),
                            Text(
                              _pages[index]['description'],
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.4,
                                color: Colors.white.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        height: 4,
                        width: _currentPage == index ? 16 : 4,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                          gradient: LinearGradient(
                            colors: _currentPage == index 
                                ? _pages[index]['gradient']
                                : [Colors.white.withOpacity(0.3), Colors.white.withOpacity(0.3)],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  child: _currentPage == _pages.length - 1
                      ? Container(
                          width: double.infinity,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: _pages[_currentPage]['gradient'],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: MaterialButton(
                            onPressed: () => _completeOnboarding(context),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Ας ξεκινήσουμε!',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton(
                              onPressed: () => _completeOnboarding(context),
                              child: Text(
                                'Παράλειψη',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            Container(
                              height: 48,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: _pages[_currentPage]['gradient'],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: MaterialButton(
                                onPressed: () {
                                  _pageController.nextPage(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                  );
                                },
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'Επόμενο',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _completeOnboarding(BuildContext context) async {
    final navigator = Navigator.of(context);
    
    if (!mounted) return;
    
    navigator.pushReplacement(
      MaterialPageRoute(builder: (context) => const WeatherForecastScreen()),
    );
  }
} 