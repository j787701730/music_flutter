import 'package:flutter/material.dart';
import 'dart:io';

/// 无波浪
// 自定义behavior:
class NoWaveBehavior extends ScrollBehavior {
  @override
  Widget buildViewportChrome(BuildContext context, Widget child, AxisDirection axisDirection) {
    if (Platform.isAndroid || Platform.isFuchsia) {
      return child;
    } else {
      return super.buildViewportChrome(context, child, axisDirection);
    }
  }
}

class ScrollNoWave extends StatelessWidget {
  final Widget child;

  ScrollNoWave({@required this.child});

  @override
  Widget build(BuildContext context) {
    // 用ScrollConfiguration包裹滑动子布局:
    return ScrollConfiguration(
        behavior: NoWaveBehavior(), //自定义behavior
        child: child //你的滚动布局组件
        );
  }
}
