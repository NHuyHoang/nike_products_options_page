import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      home: new MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => new _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
  Offset gestureCoord;
  Offset startDragCoord;
  AnimationController slidingPointAnimation;
  AnimationController pointReleaseAnimation;
  Animation releaseAnimation;
  PageSlidingState pageSlidingState;
  double pivot = 120.0;
  Size screenSize;

  _onHorizontalDragUpdate(DragUpdateDetails details) {
    setState(() {
      gestureCoord = details.globalPosition;
    });
  }

  _onHorizontalDragStart(DragStartDetails details) {
    setState(() {
      startDragCoord = details.globalPosition;
    });
  }

  _onHorizontalDragEnd(DragEndDetails details) {
    setState(() {
      startDragCoord = null;
    });
    if (gestureCoord.dx > pivot &&
        pageSlidingState == PageSlidingState.closed) {
      releaseAnimation = new Tween(begin:2*gestureCoord.dx - screenSize.width,end:screenSize.width).animate(pointReleaseAnimation);
      pointReleaseAnimation.forward(from: 0.0);
    }
  }

  @override
  void initState() {
    super.initState();
    // timeDilation = 5.0;
    slidingPointAnimation = new AnimationController(
      vsync: this,
      lowerBound: 0.0,
      upperBound: 2.0,
    )
      ..addListener(() {
        //print(pageSlidingAnimation.value);
        setState(() {});
      })
      ..addStatusListener((AnimationStatus status) {
        switch (status) {
          case (AnimationStatus.forward):
            if (this.pageSlidingState != PageSlidingState.opening)
              setState(() => pageSlidingState = PageSlidingState.opening);
            break;
          case (AnimationStatus.completed):
            setState(() {
              pageSlidingState = PageSlidingState.open;
              //gestureCoord = new Offset(120.0, 0.0);
            });
            break;
          case (AnimationStatus.dismissed):
            setState(() {
              pageSlidingState = PageSlidingState.closed;
            });
            break;
          case (AnimationStatus.reverse):
            if (this.pageSlidingState != PageSlidingState.closing)
              setState(() => pageSlidingState = PageSlidingState.closing);
            break;
          default:
            break;
        }
      });

    pointReleaseAnimation = new AnimationController(
        vsync: this, duration: new Duration(milliseconds: 200))
      ..addListener(() {
        print(pointReleaseAnimation.value);
        setState(() {});
      })
      ..addStatusListener((AnimationStatus status) {
        switch (status) {
          case (AnimationStatus.forward):
            if (pageSlidingState != PageSlidingState.releasingToRight) {
              setState(() {
                pageSlidingState = PageSlidingState.releasingToRight;
              });
            }
            break;
          case (AnimationStatus.completed):
            setState(() {
              pageSlidingState = PageSlidingState.closed;
              gestureCoord = new Offset(screenSize.width, 0.0);
            });
            break;
          case (AnimationStatus.dismissed):
            setState(() {
              pageSlidingState = PageSlidingState.open;
            });
            break;
          case (AnimationStatus.reverse):
            break;
          default:
            break;
        }
      });

    pageSlidingState = PageSlidingState.closed;
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    Size size = MediaQuery.of(context).size;
    screenSize = size;
    gestureCoord = new Offset(size.width, size.height);
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      body: new GestureDetector(
        onHorizontalDragUpdate: _onHorizontalDragUpdate,
        onHorizontalDragStart: _onHorizontalDragStart,
        onHorizontalDragEnd: _onHorizontalDragEnd,
        child: new Stack(
          children: <Widget>[
            new Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.white,
            ),
            new Container(
              width: double.infinity,
              height: double.infinity,
              child: new CustomPaint(
                painter: new RevealPainter(
                  gestureCoord: gestureCoord,
                  startDragCoord: startDragCoord,
                  controller: slidingPointAnimation,
                  releaseController: releaseAnimation,
                  pivot: pivot,
                  state: pageSlidingState,
                ),
              ),
            )
          ],
        ),
      ),
      // cer for build methods.
    );
  }
}

class RevealPainter extends CustomPainter {
  final Paint pageRevealPaint;
  final Offset gestureCoord;
  final Offset startDragCoord;
  final AnimationController controller;
  final Animation releaseController;
  final pivot;
  PageSlidingState state;
  double controlPointX = 0.0;
  SpringSimulation springSimulation;

  RevealPainter({
    this.gestureCoord,
    this.controller,
    this.state,
    this.startDragCoord,
    this.releaseController,
    this.pivot,
  }) : pageRevealPaint = new Paint()
          ..color = Colors.blue
          ..style = PaintingStyle.fill;

  @override
  void paint(Canvas canvas, Size size) {
    double _height = size.height;
    double _width = size.width;

    Path path = new Path();
    path.moveTo(_width, 0.0);

    if (state == PageSlidingState.closed) {
      path.lineTo(_width, 0.0);
      path.quadraticBezierTo(
          2 * gestureCoord.dx - _width, _height / 2, _width, _height);
      if (gestureCoord.dx <= pivot) {
        beginTransform();
      }
    } else if (state == PageSlidingState.opening) {
      path.lineTo(_width - (_width - pivot) * controller.value, 0.0);
      controlPointX = 2 * pivot - size.width;
      path.quadraticBezierTo(
          controlPointX - (controlPointX - pivot) * controller.value,
          size.height / 2,
          _width - (_width - pivot) * controller.value,
          size.height);
    } else if (state == PageSlidingState.open) {
      path.lineTo(pivot, 0.0);
      path.quadraticBezierTo(pivot, _height / 2, pivot, _height);
    } else if (state == PageSlidingState.releasingToRight) {
      //releaseControlPoint();
      path.lineTo(_width, 0.0);
      path.quadraticBezierTo(
          releaseController.value,
          _height / 2,
          _width,
          _height);
    }

    path.lineTo(_width, _height);
    path.close();
    canvas.drawPath(path, pageRevealPaint);
  }

  beginTransform() async {
    if (state == PageSlidingState.closed) {
      SpringDescription spring =
          new SpringDescription(mass: 1.0, stiffness: 300.0, damping: 18.0);
      springSimulation =
          new SpringSimulation(spring, 0.0, 1.0, controller.velocity);
      controller.animateWith(springSimulation);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}

enum PageSlidingState {
  closed,
  releasingToRight,
  releasingToLeft,
  closing,
  open,
  opening
}
