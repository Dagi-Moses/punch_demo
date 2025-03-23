import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:punch/models/myModels/companyModel.dart';
import 'package:punch/screens/EditViewPages/companyView.dart';
import 'package:punch/screens/ManageTypes/manageCompanySectors.dart';
import 'package:punch/screens/dialogs/add_anniversary_dialog.dart';
import 'package:punch/screens/dialogs/add_client_page.dart';
import 'package:punch/screens/dialogs/add_company_dialog.dart';
import 'package:punch/screens/dialogs/add_user_dialog.dart';
import 'package:punch/screens/home_screen.dart';
import 'package:punch/models/myModels/anniversaryModel.dart';
import 'package:punch/models/myModels/clientModel.dart';
import 'package:punch/models/myModels/userModel.dart';
import 'package:punch/providers/authProvider.dart';
import 'package:punch/screens/EditViewPages/anniversaryView.dart';
import 'package:punch/screens/EditViewPages/clientDetailView.dart';
import 'package:punch/screens/MainViews/clientScreen.dart';
import 'package:punch/screens/MainViews/companyScreen.dart';
import 'package:punch/screens/MainViews/staff.dart';
import 'package:punch/screens/ManageTypes/manageTitlePage.dart';
import 'package:punch/screens/errorScreen.dart';
import 'package:punch/screens/loginPage.dart';
import 'package:punch/screens/MainViews/main%20View.dart';
import 'package:punch/screens/ManageTypes/manageAnniversaryTypes.dart';
import 'package:punch/screens/ManageTypes/managepapersPage.dart';
import 'package:punch/screens/splashScreen.dart';
import 'package:punch/screens/EditViewPages/userDetailView.dart';
import 'package:punch/screens/MainViews/users.dart';

abstract class AppRouteName {
  static const anniversary = 'anniversary';
  static const addAnniversary = 'add-anniversary';
  static const anniversaryDetails = 'anniversary-details';
  static const manageAnniversary = 'manage-anniversary';
  static const managePapers = 'manage-papers';

  static const clients = 'clients';
  static const addClient = 'add-client';
  static const clientDetails = 'client-details';

  static const companies = 'companies';
  static const addCompany = 'add-company';
  static const companyDetails = 'company-details';
  static const manageCompanySectors = 'manage-company-sectors';

  static const titles = 'titles';
  static const staffs = 'staffs';

  static const users = 'users';
  static const userDetails = 'user-details';
  static const addUser = 'add-user';

  static const splash = 'splash';
  static const login = 'login';
  static const errorScreen = 'error';
}

abstract class AppRoutePath {

  static const anniversary = '/anniversary';
  static const addAnniversary = '$anniversary/add-anniversary';
  static const anniversaryDetails = '$anniversary/anniversary-details';
  static const manageAnniversary = '$anniversary/manage-anniversary';
  static const managePapers = '$anniversary/manage-papers';

  static const clients = '/clients';
  static const addClient = '$clients/add-client';
  static const clientDetails = '$clients/client-details';

  static const companies = '/companies';
  static const addCompany = '$companies/add-company';
  static const companyDetails = '$companies/company-details';
  static const manageCompanySectors = '$companies/manage-company-sectors';

   static const titles = '/titles';
  static const staffs = '/staffs';
  static const users = '/users';
  static const userDetails = '$users/user-details';
   static const addUser = '$users/add-user';

  static const splash = '/splash';
  static const login = '/login';
  static const  errorScreen = '/error/:message';
}

class AppRouter {


  static GoRouter createRouter(AuthProvider authProvider) {
    return GoRouter(
  //    initialLocation: '/home/anniversary',
       initialLocation: Uri.base.toString().replaceFirst(Uri.base.origin, ''),
     errorBuilder: (context, state) =>
          const ErrorScreen(message: "Page not found"),
      redirect: (context, state) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);

        //if (authProvider.isLoadingAuth) return splash;

        final isAuthenticated = authProvider.isAuthenticated;

        if (!isAuthenticated && state.matchedLocation != AppRoutePath.login) {
          return AppRoutePath.login;
        }

        // if (isAuthenticated && state.matchedLocation == login){
        //   return '/home/anniversary';
        // }
         if (isAuthenticated && state.matchedLocation == AppRoutePath.login) {
          return state.uri.toString() == AppRoutePath.login
              ? AppRoutePath.anniversary
              : state.uri.toString();
        }
        return null;
      },
      routes: [
        // Shell Route for Persistent Admin Home
        ShellRoute(
          builder: (context, state, child) =>
              AdminHome(child: child), // Pass child to AdminHome
          routes: [
          
                GoRoute(
                  path: AppRoutePath.anniversary,
                  name: AppRouteName.anniversary,
                  builder: (context, state) => const MainView(),
                  
                  routes: [
                    GoRoute(
                       path: AppRouteName.addAnniversary,
                      name: AppRouteName.addAnniversary,
                      builder: (context, state) => const AddAnniversaryPage(),
                    ),
                    GoRoute(
                      path: AppRouteName.manageAnniversary,
                      name: AppRouteName.manageAnniversary,
                      builder: (context, state) => ManageAnniversaryTypesPage(),
                    ),
                    GoRoute(
                        path: AppRouteName.managePapers,
                      name: AppRouteName.managePapers,
                      builder: (context, state) => ManagePapersPage(),
                    ),
                    GoRoute(
                      path: AppRouteName.anniversaryDetails,
                      name: AppRouteName.anniversaryDetails,
                      builder: (context, state) {
                        final anniversary = state.extra as Anniversary?;
                        if (anniversary == null) {
                          return const ErrorScreen(
                              message: "Anniversary details not found");
                        }
                        return AnniversaryDetailView(anniversary: anniversary);
                      },
                    ),
                  ],
                ),

                 GoRoute(
                   path: AppRoutePath.staffs,
                  name: AppRouteName.staffs,
                  builder: (context, state) => const StaffView(),
                ),
                GoRoute(
                   path: AppRoutePath.clients,
                    name: AppRouteName.clients,
                  builder: (context, state) => const ClientScreen(),
                  routes: [
                      GoRoute(
                           path: AppRouteName.addClient,
                        name: AppRouteName.addClient,
                        builder: (context, state) => AddClientPage(),
                      ),
                       GoRoute(
                           path: AppRouteName.clientDetails,
                        name: AppRouteName.clientDetails,
                        builder: (context, state) {
                          final client = state.extra as Client?;
                          if (client == null) {
                            return const ErrorScreen(
                                message: "Client details not found");
                          }
                          return ClientDetailView(
                              client: client);
                        },
                      ),
                  ]
                ),
                GoRoute(
                 path: AppRoutePath.titles,
                  name: AppRouteName.titles,
                  builder: (context, state) =>  ManageTitlePage(),
                ),
                GoRoute(
                   path: AppRoutePath.companies,
                  name: AppRouteName.companies,
                  builder: (context, state) => const CompanyScreen(),
                  routes: [
                     GoRoute(
                    path: AppRouteName.addCompany,
                    name: AppRouteName.addCompany,
                    builder: (context, state) => AddCompanyPage(),
                  ),
                     GoRoute(
                    path: AppRouteName.manageCompanySectors,
                    name: AppRouteName.manageCompanySectors,
                    builder: (context, state) => ManageCompanySectorsPage(),
                  ),
                  GoRoute(
                    path: AppRouteName.companyDetails,
                    name: AppRouteName.companyDetails,
                    builder: (context, state) {
                      final company = state.extra as Company?;
                      if (company == null) {
                        return const ErrorScreen(
                            message: "Company details not found");
                      }
                      return CompanyDetailView(company: company,);
                    },
                  ),
                  ]
                ),
                GoRoute(
                  path: AppRoutePath.users,
                    name: AppRouteName.users,
                    builder: (context, state) => const UsersScreen(),
                    routes: [
                        GoRoute(
                        path: AppRouteName.addUser,
                        name: AppRouteName.addUser,
                        builder: (context, state) => const AddUserPage(),
                      ),
                      GoRoute(
                         path: AppRouteName.userDetails,
                        name: AppRouteName.userDetails,
                        builder: (context, state) {
                          final user = state.extra as User;
                          return UserDetailView(user: user);
                        },
                      ),
                    ]),
              
          ],
        ),

        GoRoute(
          path: AppRoutePath.splash,
          name: AppRouteName.splash,
          builder: (context, state) => SplashScreen(),
        ),
        GoRoute(
           path: AppRoutePath.login,
          name: AppRouteName.login,
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
           path: AppRoutePath.errorScreen,
          name: AppRouteName.errorScreen,
          builder: (context, state) {
             final message = state.pathParameters["message"]!;
            return  ErrorScreen(
            message: message ,
          );}
        ),
      ],
    );
  }
}
