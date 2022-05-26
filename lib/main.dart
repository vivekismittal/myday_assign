import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import './data.dart';

import 'dart:math' as math;
import 'package:share/share.dart';
import './webViewScreen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    return MaterialApp(
      title: 'Flutter Instagram Stories',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: StoryScreen(stories: stories),
      routes: {
        WebViewScreen.routeName: (ctx) => WebViewScreen(),
      },
    );
  }
}

class StoryScreen extends StatefulWidget {
  final List<Story> stories;

  const StoryScreen({@required this.stories});

  @override
  _StoryScreenState createState() => _StoryScreenState();
}

class _StoryScreenState extends State<StoryScreen>
    with SingleTickerProviderStateMixin {
  PageController _pageController;
  AnimationController _animController;

  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _animController = AnimationController(vsync: this);

    final Story firstStory = widget.stories.first;
    _loadStory(story: firstStory, animateToPage: false);

    _animController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _animController.stop();
        _animController.reset();
        setState(() {
          if (_currentIndex + 1 < widget.stories.length) {
            _currentIndex += 1;
            _loadStory(story: widget.stories[_currentIndex]);
          } else {
            // Out of bounds - loop story
            // You can also Navigator.of(context).pop() here
            _currentIndex = 0;
            _loadStory(story: widget.stories[_currentIndex]);
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Story story = widget.stories[_currentIndex];
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onVerticalDragUpdate: (_) =>
            Navigator.of(context).pushNamed(WebViewScreen.routeName),
        onLongPress: () => _animController.stop(),
        onLongPressEnd: (_) => _animController.forward(),
        onTapUp: (details) {
          return _onTap(details, story);
        },
        child: PageView.builder(
          controller: _pageController,
          itemCount: widget.stories.length,
          itemBuilder: (context, i) {
            final Story story = widget.stories[i];
            return Stack(
              fit: StackFit.expand,
              children: <Widget>[
                CachedNetworkImage(
                  imageUrl: story.url,
                  fit: BoxFit.cover,
                ),
                Positioned(
                  top: 40.0,
                  left: 10.0,
                  right: 10.0,
                  child: Column(
                    children: <Widget>[
                      TweenAnimationBuilder(
                        duration: Duration(seconds: 8),
                        tween: Tween(begin: 0.0, end: 1.0),
                        builder: (context, value, _) => SizedBox(
                          width: double.infinity,
                          height: 2,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 5, left: 5),
                            child: LinearProgressIndicator(
                                value: value,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                                backgroundColor: Colors.grey.withOpacity(.5)),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 1.5,
                          vertical: 10.0,
                        ),
                        child: UserInfo(),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: 1,
                  right: 1,
                  bottom: 16,
                  child: Center(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.of(context)
                            .pushNamed(WebViewScreen.routeName);
                      },
                      child: Column(
                        children: [
                          Icon(
                            Icons.keyboard_arrow_up_sharp,
                            color: Colors.white,
                            size: 36,
                          ),
                          Container(
                            width: 128,
                            padding: EdgeInsets.all(8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Container(
                                  padding: EdgeInsets.all(4),
                                  child: Transform.rotate(
                                    angle: -math.pi / 4,
                                    child: Icon(
                                      Icons.link,
                                      size: 16,
                                    ),
                                  ),
                                  decoration: BoxDecoration(
                                      color: Colors.grey.withOpacity(.5),
                                      shape: BoxShape.circle),
                                ),
                                Text(
                                  'Read more',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(32),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              ],
            );
          },
        ),
      ),
    );
  }

  void _onTap(TapUpDetails details, Story story) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double dx = details.globalPosition.dx;
    if (dx < screenWidth / 3) {
      setState(() {
        if (_currentIndex - 1 >= 0) {
          _currentIndex -= 1;
          _loadStory(story: widget.stories[_currentIndex]);
        }
      });
    } else if (dx > 2 * screenWidth / 3) {
      setState(() {
        if (_currentIndex + 1 < widget.stories.length) {
          _currentIndex += 1;
          _loadStory(story: widget.stories[_currentIndex]);
        } else {
          _currentIndex = 0;
          _loadStory(story: widget.stories[_currentIndex]);
        }
      });
    }
  }

  void _loadStory({Story story, bool animateToPage = true}) {
    _animController.stop();
    _animController.reset();
    _animController.duration = Duration(seconds: 8);
    _animController.forward();
    if (animateToPage) {
      setState(() {});
      _pageController.animateToPage(
        _currentIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeIn,
      );
    }
  }
}

class UserInfo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        CircleAvatar(
          radius: 16.0,
          backgroundColor: Colors.grey[300],
          backgroundImage: CachedNetworkImageProvider(
              'https://www.thisday.app/uploads/thisday_square_2600ff5756.jpg'),
        ),
        const SizedBox(width: 10.0),
        Expanded(
          child: Text(
            'ThisDay',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Transform.rotate(
          angle: -math.pi / 4,
          child: IconButton(
              iconSize: 24,
              icon: const Icon(Icons.send_rounded),
              color: Colors.white,
              onPressed: () {
                Share.share(
                    'https://www.thisday.app/oppo/details/shining-sardara-and-a-legacy-tainted?utm_source=oppobrowser&utm_medium=banner');
              }),
        ),
        IconButton(
          icon: const Icon(
            Icons.close,
            size: 24,
            color: Colors.white,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
