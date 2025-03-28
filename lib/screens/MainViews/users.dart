import 'package:flutter/material.dart';

import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:paged_datatable/paged_datatable.dart';
import 'package:provider/provider.dart';

import 'package:punch/constants/constants.dart';
import 'package:punch/models/myModels/userModel.dart';
import 'package:punch/providers/authProvider.dart';
import 'package:punch/responsiveness/responsive.dart';
import 'package:punch/src/color_constants.dart';
import 'package:punch/src/routes.dart';
import 'package:punch/utils/helpers.dart';
import 'package:punch/widgets/operations.dart';
import 'package:punch/widgets/texts/richTextTableColumn.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
 

  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeDateFormatting();
  }

  Future<void> _initializeDateFormatting() async {
    await initializeDateFormatting('en');
    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
    }
  }
  @override
  Widget build(BuildContext context) {
    final tableController =
        Provider.of<AuthProvider>(context, listen: false).tableController;
    if (!_isInitialized) {
      return  const Center(
        child: SpinKitWave(
          color: punchRed,
          size: 50.0,
        ),
      );
    }
    return PagedDataTableTheme(
      data: PagedDataTableThemeData(
        horizontalScrollbarVisibility: true,
        borderRadius: BorderRadius.circular(10),
        filterBarHeight: 35,
        backgroundColor: Colors.white,
        cellTextStyle: const TextStyle(color: Colors.black),
        elevation: 10,
        headerTextStyle: const TextStyle(color: Colors.black),
        footerTextStyle: const TextStyle(color: Colors.black),
      ),
      child: Consumer<AuthProvider>(builder: (context, authProvider, child) {
        final users = authProvider.users;
        users.sort((a, b) {
          return (a.username ?? '\uFFFF').compareTo(b.username ?? '\uFFFF');
        });
      
        return PagedDataTable<String, User>(
          fixedColumnCount: 1,
          // initialPageSize: 1,
          controller: tableController,
          configuration: const PagedDataTableConfiguration(),
          // pageSizes: pageSizes.isEmpty ? null : pageSizes,
          fetcher: (pageSize, sortModel, filterModel, pageToken) async {
             try {
              int pageIndex = int.parse(pageToken ?? "0");

              List<User> filteredData = users.where((user) {
                String? query = filterModel['Name'];
                authProvider.setQuery(query);

                if (query == null || query.isEmpty) {
                  return true;
                }
                query = query.toLowerCase();
                bool matchesFirstName = user.firstName != null &&
                    user.firstName!.toLowerCase().startsWith(query);
               
                bool matchesUserName = user.lastName != null &&
                    user.lastName!.toLowerCase().startsWith(query);
                return matchesFirstName || matchesUserName;
              }).toList();

              // Paginate the filtered data
              List<User> data = filteredData
                  .skip(pageSize * pageIndex)
                  .take(pageSize)
                  .toList();

              String? nextPageToken =
                  (data.length == pageSize) ? (pageIndex + 1).toString() : null;

              return (data, nextPageToken);
            } catch (e) {
              return Future.error('Error fetching page: $e');
            }
          },
          filters: [
            TextTableFilter(
              id: "Name",
              chipFormatter: (value) {
                return 'content has "$value"';
              },
              name: "name",
              enabled: true,
            ),
           
          ],
          footer: DefaultFooter<String, User>(
            child: Align(
              alignment: Alignment.bottomLeft,
              child: !Responsive.isMobile(context)
                  ? SizedBox(
                      width: Responsive.isTablet(context)
                          ? MediaQuery.of(context).size.width / 12
                          : MediaQuery.of(context).size.width / 15,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Expanded(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                Icon(
                                  icons.last,
                                  size: 22,
                                  color: secondaryColor,
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Text(
                                users.length.toString(),
                                style: const TextStyle(
                                  fontSize: 19,
                                  color: Colors.black87,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Raleway',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    )
                  : const SizedBox(),
            ),
          ),
          filterBarChild: IconTheme(
            data: const IconThemeData(color: Colors.black),
            child: PopupMenuButton(
                clipBehavior: Clip.hardEdge,
                icon: const Icon(Icons.more_vert_outlined),
                itemBuilder: (context) {
                  return <PopupMenuEntry>[
                    PopupMenuItem(
                      child: const Text("Add User"),
                      onTap: () {
                        context.go(AppRoutePath.addUser);},
                    ),
                    PopupMenuItem(
                      child: const Text("Refresh"),
                      onTap: () {
                        Future.delayed(
                          Duration.zero,
                          () async {
                            await authProvider.fetchUsers();
                            setState(() {
                              tableController.refresh(fromStart: true);
                            });
                          },
                        );
                      },
                    ),
                    PopupMenuItem(
                      child: const Text("Select Rows"),
                      onTap: () {
                        authProvider.setBoolValue(true);
                      },
                    ),
                    PopupMenuItem(
                      child: const Text("Select all rows"),
                      onTap: () {
                        authProvider.setBoolValue(true);
                        Future.delayed(Duration.zero, () {
                          tableController.selectAllRows();
                        });
                      },
                    ),
                    if (authProvider.isRowsSelected)
                      PopupMenuItem(
                        child: const Text("Unselect all rows"),
                        onTap: () {
                          tableController.unselectAllRows();
                          authProvider.setBoolValue(false);
                        },
                      ),
                    if (authProvider.isRowsSelected)
                      PopupMenuItem(
                        child: const Text("Delete Selected rows"),
                        onTap: () {
                          authProvider.deleteSelectedUsers(
                              context, tableController.selectedItems);
                          authProvider.setBoolValue(false);
                        },
                      ),
                    PopupMenuItem(
                      child: const Text("Clear filters"),
                      onTap: () {
                        tableController.removeFilters();
                      },
                    ),
                  ];
                }),
          ),
          // fixedColumnCount: 2,

          columns: [
            if (authProvider.isRowsSelected) RowSelectorColumn(),

             HighlightQueryColumn(
              fieldLabel: "Username",
              title: const Text("Username"),
              id: "username",
              size: const FixedColumnSize(200),
              query: authProvider.query?.toLowerCase() ?? "",
              getter: (item, index) => item.username ?? "N/A",
              setter: (item, newValue, index) async {
              
                return true;
              },
            ),

             HighlightQueryColumn(
              fieldLabel: "Firstname",
              title: const Text("First name"),
              id: "firstname",
              size: const FixedColumnSize(200),
              query: authProvider.query?.toLowerCase() ?? "",
              getter: (item, index) => item.firstName ?? "N/A",
              setter: (item, newValue, index) async {
              
                return true;
              },
            ),
           
           
            LargeTextTableColumn(
              sortable: true,
              id: "staffNo",
              title: const Text("Staff No"),
              size: const FixedColumnSize(250),
              getter: (item, index) => item.staffNo.toString(),
              fieldLabel: "Staff No",
              setter: (item, newValue, index) async {
                await Future.delayed(const Duration(seconds: 2));
                item.staffNo = newValue as int?;
                return true;
              },
            ),
            DropdownTableColumn(
              sortable: true,
              id: "userRole",
              title: const Text("User Role"),
              // Define the items for the dropdown menu
              items: UserRole.values.map((UserRole type) {
                return DropdownMenuItem<UserRole>(
                  value: type,
                  child: Text(
                    type.name,
                  ),
                );
              }).toList(),
              size: const FixedColumnSize(250),
              getter: (item, index) => item.loginId,
              setter: (item, newValue, index) async {
                return false;
              },
            ),
            TableColumn(
              title: const Text("Operations"),
              size: const FixedColumnSize(160),
              cellBuilder: (context, item, index) =>
                  operationsWidget(context, item.username ?? "N?A", () {
               context.go(AppRoutePath.userDetails, extra: item);
              }, () {
                authProvider.deleteUser(context, item);
              }),
            ),
          ],
        );
      }),
    );
  }
}
