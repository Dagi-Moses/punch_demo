import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:paged_datatable/paged_datatable.dart';
import 'package:provider/provider.dart';
import 'package:punch/src/color_constants.dart';
import 'package:go_router/go_router.dart';
import 'package:punch/responsiveness/responsive.dart';

import 'package:punch/constants/constants.dart';
import 'package:punch/models/myModels/clientModel.dart';
import 'package:punch/models/myModels/userModel.dart';
import 'package:punch/providers/authProvider.dart';

import 'package:punch/providers/clientProvider.dart';
import 'package:punch/providers/titleProvider.dart';
import 'package:punch/src/routes.dart';


import 'package:punch/widgets/operations.dart';
import 'package:punch/widgets/texts/richTextTableColumn.dart';

class ClientScreen extends StatefulWidget {
  const ClientScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _ClientScreenState();
}

class _ClientScreenState extends State<ClientScreen> {


  String _getAnniversaryTypeQuery(String? query) {
    final titleProvider =Provider.of<TitleProvider>(context, listen: false);
    if (query == null || query.isEmpty) {
      return "";
    }
    int? typeId = int.tryParse(query);
    if (typeId != null &&
        titleProvider
            .titles
            .containsKey(typeId)) {
      return titleProvider
          .titles[typeId]!
          .toLowerCase();
    }
    return query.toLowerCase();
  }


  
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

  List<int> calculatePageSizes(int totalItems) {
    if (totalItems < 10) {
      return [totalItems];
    } else if (totalItems < 50) {
      return [10, totalItems];
    } else if (totalItems < 100) {
      return [10, 20, totalItems];
    } else {
      return [10, 20, 50, 100];
    }
  }

  @override
  Widget build(BuildContext context) {
    final tableController =
        Provider.of<ClientProvider>(context, listen: false).tableController;
    final auth = Provider.of<AuthProvider>(context);
    final titles = Provider.of<TitleProvider>(context);

    final isUser = auth.user?.loginId == UserRole.user;
    if (!_isInitialized) {
      return const Center(
        child: SpinKitWave(
          color: punchRed,
          size: 50.0,
        ),
      );
    }
    return SafeArea(
      child: PagedDataTableTheme(
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
        child:
            Consumer<ClientProvider>(builder: (context, clientProvider, child) {
          final clients = clientProvider.clients;
          clients.sort((a, b) {
            String nameA = a.lastName?.isNotEmpty == true
                ? a.lastName!
                : '\uFFFF'; // Handle null/empty firstName for a
            String nameB = b.lastName?.isNotEmpty == true
                ? b.lastName!
                : '\uFFFF'; // Handle null/empty firstName for b

            return nameA.compareTo(nameB);
          });

          if (clients.isEmpty) {
            return const Center(
              child: SpinKitWave(
                color: punchRed,
                size: 50.0,
              ),
            );
          }
          final pageSizes = calculatePageSizes(clients.length);
          final initialPageSize = pageSizes.isNotEmpty ? pageSizes.first : 10; // ✅ Safe default
          return PagedDataTable<String, Client>(
            fetcher: (pageSize, sortModel, filterModel, pageToken) {
              try {
                int pageIndex = int.parse(pageToken ?? "0");
                List<Client> filteredData = clients.where((client) {
                  // Get the search query
                  String? query = filterModel['Name'];
                  clientProvider.setQuery(query);
                  // If there's no query, include all clients
                  if (query == null || query.isEmpty) {
                    return true;
                  }
                  query = query.toLowerCase();
                  bool matchesFirstName = client.firstName != null &&
                      client.firstName!.toLowerCase().startsWith(query);
                  bool matchesMiddleName = client.middleName != null &&
                      client.middleName!.toLowerCase().startsWith(query);
                  bool matchesLastName = client.lastName != null &&
                      client.lastName!.toLowerCase().startsWith(query);

                  // Return true if any of the fields match
                  return matchesFirstName ||
                      matchesMiddleName ||
                      matchesLastName;
                }).toList();

                // Paginate the filtered data
                List<Client> data = filteredData
                    .skip(pageSize * pageIndex)
                    .take(pageSize)
                    .toList();

                String? nextPageToken = (data.length == pageSize)
                    ? (pageIndex + 1).toString()
                    : null;

                return (data, nextPageToken);
              } catch (e) {
                return Future.error('Error fetching page: $e');
              }
            },
            fixedColumnCount: 1,
            controller: tableController,
            configuration: const PagedDataTableConfiguration(),
            initialPageSize: initialPageSize,
            pageSizes: pageSizes,
            filters: [
              TextTableFilter(
                id: "Name",
                chipFormatter: (value) {
                  return 'Client Name Starts With "$value"';
                },
                name: "Name",
                enabled: true,
              ),
            ],
            filterBarChild: IconTheme(
              data: const IconThemeData(color: Colors.black),
              child: PopupMenuButton(
                  clipBehavior: Clip.hardEdge,
                  icon: const Icon(Icons.more_vert_outlined),
                  itemBuilder: (context) {
                    return <PopupMenuEntry>[
                      if (!isUser)
                        PopupMenuItem(
                          child: const Text("Add Client"),
                          onTap: () {
                                context.go(AppRoutePath.addClient);
                          
                          },
                        ),
                      if (!isUser)
                        PopupMenuItem(
                          child: const Text("Edit Titles"),
                          onTap: () {
                             context.go(AppRoutePath.titles);
                            
                          },
                        ),
                      PopupMenuItem(
                        child: const Text("Refresh"),
                        onTap: () {
                          clientProvider.fetchClients();
                          tableController.refresh();
                        },
                      ),
                      if (!isUser)
                        PopupMenuItem(
                          child: const Text("Select Rows"),
                          onTap: () {
                            clientProvider.setBoolValue(true);
                          },
                        ),
                      if (!isUser)
                        PopupMenuItem(
                          child: const Text("Select all rows"),
                          onTap: () {
                            clientProvider.setBoolValue(true);
                            Future.delayed(Duration.zero, () {
                              tableController.selectAllRows();
                            });
                          },
                        ),
                      if (!isUser)
                        PopupMenuItem(
                          child: const Text("Unselect all rows"),
                          onTap: () {
                            tableController.unselectAllRows();
                            clientProvider.setBoolValue(false);
                          },
                        ),
                      if (clientProvider.isRowsSelected && !isUser)
                        PopupMenuItem(
                          child: const Text("Delete Selected rows"),
                          onTap: () async {
                            await clientProvider.deleteSelectedClients(
                                context, tableController.selectedItems);
                            clientProvider.setBoolValue(false);
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
            footer: DefaultFooter<String, Client>(
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
                                    icons[1],
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
                                  clients.length.toString(),
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
            columns: [
              if (clientProvider.isRowsSelected) RowSelectorColumn(),
              HighlightQueryColumn(
                fieldLabel: "lastName",
                title: const Text("Last Name"),

                id: "lastName",
                size: const FixedColumnSize(200),
                query: clientProvider.query?.toLowerCase() ??
                    "", // Replace with your search query
                getter: (item, index) => item.lastName ?? "N/A",
                setter: (item, newValue, index) async {
                  await Future.delayed(const Duration(seconds: 2));
                  item.lastName = newValue;
                  return true;
                },
              ),
              HighlightQueryColumn(
                fieldLabel: "middleName",
                title: const Text("Middle Name"),

                id: "middleName",
                size: const FixedColumnSize(200),
                query: clientProvider.query?.toLowerCase() ??
                    "", // Replace with your search query
                getter: (item, index) => item.middleName ?? "N/A",
                setter: (item, newValue, index) async {
                  await Future.delayed(const Duration(seconds: 2));
                  item.middleName = newValue;
                  return true;
                },
              ),
              HighlightQueryColumn(
                fieldLabel: "firstName",
                title: const Text("First Name"),
                id: "firstName",
                size: const FixedColumnSize(200),
                query: clientProvider.query?.toLowerCase() ??
                    "", // Replace with your search query
                getter: (item, index) => item.firstName ?? "N/A",
                setter: (item, newValue, index) async {
                  await Future.delayed(const Duration(seconds: 2));
                  item.firstName = newValue;
                  return true;
                },
              ),


               HighlightQueryColumn(
                id: "type",
                title: const Text("Type"),

                query: _getAnniversaryTypeQuery(clientProvider.query),
                size: const FixedColumnSize(210),
                fieldLabel: "Anniversary Type",
                getter: (item, index) {
                  int? typeId = item.titleId;
                  if (typeId == null ||
                      !titles.titles
                          .containsKey(typeId)) {
                    return "Unknown";
                  }
                  return titles.titles[typeId]!;
                },
                setter: (item, newValue, index) async {
                  return false;
                },
              ),
           
              LargeTextTableColumn(
                title: const Text("Age"),
                id: "age",
                size: const FixedColumnSize(150),
                getter: (item, index) => item.age?.toString() ?? '',
                fieldLabel: "Age",
                setter: (item, newValue, index) async {
                  await Future.delayed(const Duration(seconds: 2));
                  //   item.companyNo = newValue;
                  return true;
                },
              ),
              TableColumn(
                title: const Text("Operations"),
                size: const FixedColumnSize(160),
                cellBuilder: (context, item, index) =>
                    operationsWidget(context, item.firstName ?? "N?A", () {
                      context.go(
                   AppRoutePath.clientDetails,extra: item
                  );
                 
                }, () async {
                  clientProvider.deleteClient(context, item);
                }),
              ),
            ],
          );
        }),
      ),
    );
  }
}
