import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../../Util/EventBus/SPEventBus.dart';
import '../../Util/GlobalVar/GlobalVar.dart';
import '../../ViewController/Game/GameEntry.dart';

class SPGameKylinHomePage extends StatefulWidget {
  const SPGameKylinHomePage({super.key});

  @override
  State<SPGameKylinHomePage> createState() => _SPGameKylinHomePageState();
}

class _SPGameKylinHomePageState extends State<SPGameKylinHomePage> {
  final _subscriptions = <StreamSubscription>[];

  @override
  void initState() {
    super.initState();
    _subscriptions.add(
        eventBus.on<SPEvent>().listen((event) {
          if (mounted && event.eventCode == SPEventCode.backToMapHome) {
            Navigator.pop(context);
          }
        })
    );
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Focus(child: GameWidget(game: SPGameKylinHome(GlobalVar.isDebugMode)),),
    );
  }
}