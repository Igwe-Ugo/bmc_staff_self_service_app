import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'features/common/widget.dart';
import '../../core/network/provider/widget.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  BMCRouter(); // 👈 triggers _internal() which sets router
  await dotenv.load(fileName: '.env');
  runApp(const BMCStaffSelfService());
}

class BMCStaffSelfService extends StatefulWidget{
  const BMCStaffSelfService({super.key});
  // ignore: library_private_types_in_public_api
  static _BMCStaffSelfServiceState of(BuildContext context) => context.findAncestorStateOfType<_BMCStaffSelfServiceState>()!;

  @override
  State<BMCStaffSelfService> createState() => _BMCStaffSelfServiceState();
}

class _BMCStaffSelfServiceState extends State<BMCStaffSelfService>{
  DarkThemeProvider themeChangeProvider = DarkThemeProvider();

  @override
  void initState(){
    super.initState();
    getCurrentAppTheme();
  }

  void getCurrentAppTheme() async{
    themeChangeProvider.darkTheme = await themeChangeProvider.bmcStaffPreferences.getTheme();
  }

  @override
  Widget build(BuildContext context){
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_){
            return themeChangeProvider;
          },
        ),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => AvailabilityProvider()),
        ChangeNotifierProvider(create: (_) => LeaveProvider()),
        ChangeNotifierProvider(create: (_) => RotaProvider()),
      ],
      child: Consumer<DarkThemeProvider>(
          builder: (context, themeData, child){
            return MaterialApp.router(
              debugShowCheckedModeBanner: false,
              title: 'BMC Staff Self-Service',
              routerConfig: BMCRouter.router,
              theme: Styles.themeData(themeChangeProvider.darkTheme, context),
            );
          }
      ),
    );
  }
}
