import 'package:faculty_app/personal_details.dart';
import 'package:flutter/material.dart';
import 'package:sign_in_button/sign_in_button.dart';

class OnboardingPage1 extends StatelessWidget {
  const OnboardingPage1({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: OnboardingPagePresenter(pages: [
        OnboardingPageModel(
          title: 'Stay Informed, Stay Ahead',
          description:
              'Get real-time updates on lectures, events, and deadlines with the faculty noticeboard.',
          imageUrl: 'assets/images/Learning-rafiki.png',
          bgColor: Color(0xff347928), // Deep Green
        ),
        OnboardingPageModel(
          title: 'Find Lecturers & Offices Easily',
          description:
              'A simple directory to search for lecturers, office locations, and contacts.',
          imageUrl: 'assets/images/Teaching-amico.png',
          bgColor: Color(0xffAAB99A), // Soft Off-White
        ),
        OnboardingPageModel(
          title: 'Never Miss a Class',
          description: 'Access lecture timetables and exam schedules easily.',
          imageUrl: 'assets/images/Learning-cuate.png',
          bgColor: Color(0xffC7FFD8), // Navy Blue
        ),
      ]),
    );
  }
}

class OnboardingPagePresenter extends StatefulWidget {
  final List<OnboardingPageModel> pages;
  final VoidCallback? onSkip;
  final VoidCallback? onFinish;

  const OnboardingPagePresenter(
      {super.key, required this.pages, this.onSkip, this.onFinish});

  @override
  State<OnboardingPagePresenter> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPagePresenter> {
  // Store the currently visible page
  int _currentPage = 0;

  // Define a controller for the pageview
  final PageController _pageController = PageController(initialPage: 0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        color: widget.pages[_currentPage].bgColor,
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                // Pageview to render each page
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: widget.pages.length,
                  onPageChanged: (idx) {
                    // Change current page when pageview changes
                    setState(() {
                      _currentPage = idx;
                    });
                  },
                  itemBuilder: (context, idx) {
                    final item = widget.pages[idx];
                    return Column(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Image.asset(
                              item.imageUrl,
                            ),
                          ),
                        ),
                        Expanded(
                            flex: 1,
                            child: Column(children: [
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Text(item.title,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: _currentPage ==
                                                  widget.pages.length - 1
                                              ? Colors.black
                                              : item.textColor,
                                        )),
                              ),
                              Container(
                                constraints:
                                    const BoxConstraints(maxWidth: 280),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24.0, vertical: 8.0),
                                child: Text(item.description,
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: _currentPage ==
                                                  widget.pages.length - 1
                                              ? Colors.black
                                              : item.textColor,
                                        )),
                              )
                            ]))
                      ],
                    );
                  },
                ),
              ),

              // Current page indicator
              _currentPage != widget.pages.length - 1
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: widget.pages
                          .map((item) => AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                width:
                                    _currentPage == widget.pages.indexOf(item)
                                        ? 30
                                        : 8,
                                height: 8,
                                margin: const EdgeInsets.all(2.0),
                                decoration: BoxDecoration(
                                    color:
                                        _currentPage == widget.pages.length - 1
                                            ? Colors.black
                                            : Colors.white,
                                    borderRadius: BorderRadius.circular(10.0)),
                              ))
                          .toList(),
                    )
                  : Container(),

              // Bottom buttons
              _currentPage != widget.pages.length - 1
                  ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: SizedBox(
                        height: 100,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton(
                                style: TextButton.styleFrom(
                                    visualDensity: VisualDensity.comfortable,
                                    foregroundColor:
                                        _currentPage == widget.pages.length - 1
                                            ? Colors.black
                                            : Colors.white,
                                    textStyle: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold)),
                                onPressed: () {
                                  widget.onSkip?.call();
                                },
                                child: const Text("Skip")),
                            TextButton(
                              style: TextButton.styleFrom(
                                  visualDensity: VisualDensity.comfortable,
                                  foregroundColor:
                                      _currentPage == widget.pages.length - 1
                                          ? Colors.black
                                          : Colors.white,
                                  textStyle: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold)),
                              onPressed: () {
                                if (_currentPage == widget.pages.length - 1) {
                                  widget.onFinish?.call();
                                } else {
                                  _pageController.animateToPage(
                                      _currentPage + 1,
                                      curve: Curves.easeInOutCubic,
                                      duration:
                                          const Duration(milliseconds: 250));
                                }
                              },
                              child: Row(
                                children: [
                                  Text(
                                    _currentPage == widget.pages.length - 1
                                        ? "Finish"
                                        : "Next",
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    _currentPage == widget.pages.length - 1
                                        ? Icons.done
                                        : Icons.arrow_forward,
                                    color:
                                        _currentPage == widget.pages.length - 1
                                            ? Colors.black
                                            : Colors.white,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        // Adjust the radius as needed
                        child: SignInButton(
                          padding: const EdgeInsets.only(
                              left: 20, top: 10, bottom: 10),
                          Buttons.google,
                          text: "Sign in with Google",
                          onPressed: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        PersonalInfoScreen()));
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
}

class OnboardingPageModel {
  final String title;
  final String description;
  final String imageUrl;
  final Color bgColor;
  final Color textColor;

  OnboardingPageModel(
      {required this.title,
      required this.description,
      required this.imageUrl,
      this.bgColor = Colors.blue,
      this.textColor = Colors.white});
}
