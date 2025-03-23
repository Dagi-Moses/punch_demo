import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:punch/src/color_constants.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:punch/providers/anniversaryProvider.dart';
import 'package:punch/providers/auth.dart';

import 'package:punch/providers/authProvider.dart';
import 'package:punch/providers/clientExtraProvider.dart';
import 'package:punch/providers/clientProvider.dart';
import 'package:punch/providers/companyProvider.dart';

import 'package:punch/providers/sexProvider.dart';
import 'package:punch/providers/staffprovider.dart';
import 'package:punch/providers/textConroller.dart';
import 'package:paged_datatable/l10n/generated/l10n.dart';
import 'package:provider/provider.dart';
import 'package:punch/providers/titleProvider.dart';
import 'package:punch/src/routes.dart';

import 'package:flutter_web_plugins/flutter_web_plugins.dart';

Future<void> main() async {
  setUrlStrategy(PathUrlStrategy());
 //   usePathUrlStrategy();
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
       ChangeNotifierProvider(create: (_) => SexProvider()),
       ChangeNotifierProvider(create: (_) => StaffProvider()),
       
        ChangeNotifierProvider(create: (_) => AnniversaryProvider()),
        ChangeNotifierProvider(create: (_) => CompanyProvider()),
        ChangeNotifierProvider(create: (_) => ClientProvider()),
        ChangeNotifierProvider(create: (_) => ClientExtraProvider()),
        ChangeNotifierProvider(create: (_) => TitleProvider()),
        ChangeNotifierProvider(create: (_) => Auth()),
        ChangeNotifierProvider(create: (_) => TextControllerNotifier()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Provider.of<ClientExtraProvider>(context, listen: false);
    Provider.of<ClientProvider>(context, listen: false);
    Provider.of<AnniversaryProvider>(context, listen: false);
    Provider.of<CompanyProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context);
    return ChangeNotifierProvider(
        create: (_) => AuthProvider(),
        child: MaterialApp.router(
          localizationsDelegates: const [
            PagedDataTableLocalization.delegate,
          ],
          supportedLocales: const [
            Locale('en', 'NG'),
          ],
          title: 'Punch Anniversary',
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
            textTheme: kIsWeb ? GoogleFonts.robotoTextTheme() : null,
            floatingActionButtonTheme: FloatingActionButtonThemeData(
              hoverColor: hoverPunchRed,
              backgroundColor: punchRed,
              foregroundColor: Colors.white,
              elevation: 4,
            ),
          ),
          debugShowCheckedModeBanner: false,
          routerConfig: AppRouter.createRouter(authProvider),
        ));
  }
}
