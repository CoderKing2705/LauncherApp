import 'dart:async';

import 'package:device_apps/device_apps.dart';
import 'package:device_policy_controller/device_policy_controller.dart';
import 'package:fl_live_launcher/apps.dart';
import 'package:fl_live_launcher/kiosk_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kiosk_mode/kiosk_mode.dart';
import 'app_state.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await startKioskMode();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Flutter Launcher',
        darkTheme: ThemeData.dark().copyWith(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
        ),
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        onGenerateRoute: (settings) {
          return MaterialPageRoute(
              settings: settings,
              builder: (context) {
                switch (settings.name) {
                  case "apps":
                    return AppsPage();
                  case "home":
                    return HomePage();
                  default:
                    return HomePage();
                }
              });
        },
      ),
    );
  }
}

class HomePage extends StatelessWidget with WidgetsBindingObserver {
  final dpc = DevicePolicyController.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.transparent,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'exit') {
                _showPinDialog(context, doExit: true);
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                PopupMenuItem<String>(
                  value: 'exit',
                  child: Row(
                    children: [
                      Icon(Icons.exit_to_app),
                      SizedBox(width: 5),
                      Text('Exit')
                    ],
                  ),
                )
              ];
            },
            icon: Icon(Icons.more_vert),
          )
        ],
      ),
      backgroundColor: Colors.transparent,
      body: PopScope(
        canPop: true,
        child: Consumer(
          builder: (
            context,
            ref,
            _,
          ) {
            final selectedApplication =
                ref.watch(selectedAppsProvider.notifier).state;
            return selectedApplication.isNotEmpty
                ? ListView.builder(
                    itemCount: selectedApplication.length,
                    itemBuilder: (BuildContext context, int index) {
                      final application = selectedApplication[index];
                      return ListTile(
                        leading: Image.memory(
                          application.icon,
                          width: 40,
                        ),
                        title: Text(application.appName),
                        textColor: Colors.white,
                        onTap: () async {
                          await getKioskMode().then((value) => {
                                value == KioskMode.disabled
                                    ? DeviceApps.openApp(
                                        application.packageName)
                                    : KioskMode.enabled
                              });
                          // stopKioskMode();
                        },
                      );
                    })
                : Center(
                    child: Text('Apps will be display here...'),
                  );
          },
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.transparent,
        elevation: 0,
        child: Container(
          height: 70,
          child: Center(
            child: IconButton(
              icon: Icon(Icons.apps),
              color: Colors.amberAccent,
              onPressed: () => _showPinDialog(context, doExit: false),
            ),
          ),
        ),
      ),
    );
  }

// This Dialog will get the generate pin UI
  void _showPinDialog(BuildContext context, {required bool doExit}) {
    final TextEditingController pinController = TextEditingController();
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Enter Pin'),
            content: Form(
              key: formKey,
              child: TextFormField(
                controller: pinController,
                keyboardType: TextInputType.number,
                maxLength: 4,
                obscureText: true,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration:
                    InputDecoration(labelText: '4-digit pin', counterText: ''),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter Pin';
                  } else if (value.length != 4 || value.length == 0) {
                    return 'Please enter 4 digit Pin';
                  }
                  return null;
                },
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('Cancel')),
              ElevatedButton(
                  onPressed: () {
                    if (formKey.currentState?.validate() ?? false) {
                      if (pinController.text == '1234') {
                        Navigator.of(context).pop();
                        if (doExit) {
                          stopKioskMode()
                              .then((value) => SystemNavigator.pop());
                        }
                        Navigator.pushNamed(context, "apps");
                      }
                    }
                  },
                  child: Text('Submit')),
            ],
          );
        });
  }
}
