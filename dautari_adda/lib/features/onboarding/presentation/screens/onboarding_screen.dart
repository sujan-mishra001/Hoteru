import 'package:flutter/material.dart';
import 'package:dautari_adda/features/auth/presentation/screens/login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/onboarding_content.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late PageController _pageController;
  int _pageIndex = 0;

  final List<OnboardingContent> _demos = [
    OnboardingContent(
      image: "assets/images/onboarding_hospitality.png",
      title: "Fabulous Hospitality",
      description: "Enjoy a fabulous hospitality.",
    ),
    OnboardingContent(
      image: "assets/images/onboarding_hotel_booking.png",
      title: "Manage Booking",
      description: "Book and cancel table anytime.",
    ),
    OnboardingContent(
      image: "assets/images/onboarding_best_deal.png",
      title: "Find Best Deal",
      description: "Find best deal and discount on food.",
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _demos.length,
                  onPageChanged: (index) {
                    setState(() {
                      _pageIndex = index;
                    });
                  },
                  itemBuilder: (context, index) => OnboardingPage(
                    content: _demos[index],
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ...List.generate(
                    _demos.length,
                    (index) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: DotIndicator(isActive: index == _pageIndex),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_pageIndex < _demos.length - 1) {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.ease,
                          );
                        } else {
                          // Complete onboarding and navigate to Login
                          SharedPreferences.getInstance().then((prefs) {
                            prefs.setBool('hasSeenOnboarding', true);
                          });
                          
                           Navigator.of(context).pushReplacement(
                            MaterialPageRoute(builder: (context) => const LoginScreen()),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFC107),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        _pageIndex == _demos.length - 1 ? "Get Started" : "Next",
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  if (_pageIndex < _demos.length - 1)
                    TextButton(
                      onPressed: () {
                        _pageController.animateToPage(
                          _demos.length - 1,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.ease,
                        );
                      },
                       style: TextButton.styleFrom(
                         foregroundColor: Colors.grey,
                       ),
                      child: const Text("Skip"),
                    ),
                     if (_pageIndex == _demos.length - 1)
                    const SizedBox(height: 48), // Placeholder for skip button height
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DotIndicator extends StatelessWidget {
  const DotIndicator({
    Key? key,
    this.isActive = false,
  }) : super(key: key);

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: 8,
      width: isActive ? 24 : 8,
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFFFC107) : const Color(0xFFFFC107).withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}
