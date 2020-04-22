import 'dart:async';

import 'package:firebase_analytics/observer.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:package_info/package_info.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'components/home.dart';
import 'components/onboarding.dart';
import 'components/playlist.dart';
import 'components/rating.dart';
import 'model/analytics.dart';
import 'model/discogs.dart';
import 'model/lastfm.dart';
import 'model/playlist.dart';
import 'model/settings.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set `enableInDevMode` to true to see reports while in debug mode
  // This is only to be used for confirming that reports are being
  // submitted as expected. It is not intended to be used for everyday
  // development.
  //Crashlytics.instance.enableInDevMode = true;

  // Pass all uncaught errors to Crashlytics.
  FlutterError.onError = Crashlytics.instance.recordFlutterError;

  // initialize logger
  const isProduction = bool.fromEnvironment('dart.vm.product');
  if (isProduction) {
    Logger.root.level = Level.WARNING;
    Logger.root.onRecord.listen((record) {
      analytics.logException('${record.level.name}: record.message}');
      if (record.error != null) {
        Crashlytics.instance.recordError(record.error, record.stackTrace);
      }
    });
  } else {
    Logger.root.level = Level.ALL; // defaults to Level.INFO
    Logger.root.onRecord.listen((record) {
      // ignore: avoid_print
      print('[${record.level.name}] ${record.loggerName}: ${record.message}');
      if (record.level > Level.INFO) {
        if (record.error != null) {
          // ignore: avoid_print
          print('Error: ${record.error}');
        }
        if (record.stackTrace != null) {
          // ignore: avoid_print
          print(record.stackTrace);
        }
      }
    });
  }

  // create user-agent
  var userAgent = 'Scrobbler';
  try {
    final packageInfo = await PackageInfo.fromPlatform();

    final version = packageInfo.version;
    final buildNumber = packageInfo.buildNumber;

    userAgent = 'Scrobbler/$version+$buildNumber';

    Logger.root.info('Set user agent to: $userAgent');
  } on Exception catch (e, st) {
    Logger.root.warning('Failed to get package info for user agent', e, st);
  }

  final prefs = await SharedPreferences.getInstance();

  // run app
  runZoned(() {
    runApp(MyApp(prefs, userAgent));
  }, onError: Crashlytics.instance.recordError);
}

class MyApp extends StatelessWidget {
  const MyApp(this.prefs, this.userAgent);

  final SharedPreferences prefs;
  final String userAgent;

  @override
  Widget build(BuildContext context) {
    analytics.logAppOpen();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<DiscogsSettings>(
          create: (_) => DiscogsSettings(prefs),
        ),
        ChangeNotifierProvider<LastfmSettings>(
          create: (_) => LastfmSettings(prefs),
        ),
        ChangeNotifierProxyProvider<DiscogsSettings, Collection>(
            create: (_) => Collection(userAgent),
            update: (_, settings, collection) => collection
              ..updateUsername(settings.username).catchError((e, stackTrace) =>
                  Logger.root.warning(
                      'Exception while updating username.', e, stackTrace))),
        ProxyProvider<LastfmSettings, Scrobbler>(
          lazy: false,
          create: (_) => Scrobbler(userAgent),
          update: (_, settings, scrobbler) =>
              scrobbler..updateSessionKey(settings.sessionKey),
        ),
        ChangeNotifierProvider<Playlist>(create: (_) => Playlist()),
        Provider<ReviewRequester>(
          lazy: false,
          create: (_) => ReviewRequester()..init(),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Record Scrobbler',
        theme: ThemeData(
          primarySwatch: Colors.amber,
          primaryColor: const Color(0xFF2a241a),
          disabledColor: Colors.white30,
        ),
        home: StartPage(),
        routes: <String, WidgetBuilder>{
          '/playlist': (_) => PlaylistPage(),
        },
        navigatorObservers: [FirebaseAnalyticsObserver(analytics: analytics)],
      ),
    );
  }
}

class StartPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<DiscogsSettings>(context);

    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 1000),
        child: (settings.username != null || settings.skipped)
            ? HomePage()
            : OnboardingPage(),
      ),
    );
  }
}
