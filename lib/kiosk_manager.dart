import 'package:flutter/cupertino.dart';
import 'package:kiosk_mode/kiosk_mode.dart';

class KioskManager extends WidgetsBindingObserver{

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if(state == AppLifecycleState.paused || state == AppLifecycleState.detached){
      startKioskMode();
    }
  }

}