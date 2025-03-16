import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:punch/providers/clientProvider.dart';
import 'package:punch/providers/textConroller.dart';
import 'package:punch/widgets/routes/manageType.dart';


class ManageClientTitlePage extends StatelessWidget {
  ManageClientTitlePage({Key? key}) : super(key: key);
  TextEditingController _descriptionController = TextEditingController();
  int? _selectedId;
  @override
  Widget build(BuildContext context) {
    final clientProvider = Provider.of<ClientProvider>(context);
    final notifier = Provider.of<TextControllerNotifier>(context);
    return ManageTypesPage(
      title: 'Client Titles',
      inputLabel: 'Clients Title Description',
      items: clientProvider.titles,
       onItemAdded: () {
        if (notifier.descriptionController.text.isNotEmpty) {
          clientProvider
              .addTitle(notifier.descriptionController);
        }
      },
      onItemUpdated: () {
        if (notifier.selectedId != null) {
          if (notifier.descriptionController.text.isNotEmpty) {
            clientProvider.updateTitle(
                notifier.selectedId!, notifier.descriptionController, () {
              notifier.descriptionController.clear();
            });
          }
        }
      },
      onItemDeleted: (id) async {
        await clientProvider.deleteTitle(context, id);
      },
    );
  }
}

// class ManageClientTitlePage extends StatefulWidget {
//   @override
//   _ManageClientTitlePageState createState() =>
//       _ManageClientTitlePageState();
// }

// class _ManageClientTitlePageState
//     extends State<ManageClientTitlePage> {
//   TextEditingController descriptionController = TextEditingController();
//   int? _selectedId;

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//          automaticallyImplyLeading: false,
//         title: const Text('Manage Client Types'),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Consumer<ClientProvider>(
//             builder: (context, clientProvider, child) {
//           return Column(
//             children: [
//               TextField(
//                 controller: descriptionController,
//                 decoration: const InputDecoration(
//                     labelText: 'Description',
//                     labelStyle: TextStyle(
//                         color: Colors.black, fontWeight: FontWeight.bold)),
//               ),
//               const SizedBox(height: 10),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   ElevatedButton(
//                     style:
//                         ElevatedButton.styleFrom(backgroundColor: Colors.green),
//                     onPressed: () {
//                       if (_selectedId == null) {
//                         clientProvider.addTitle(
//                           descriptionController,
//                         );
//                       } else {
//                         clientProvider.updateTitle(
//                             _selectedId!, descriptionController, () {
//                           setState(() {
//                             _selectedId = null;
//                           });
//                         });
//                       }
//                     },
//                     child: Text(
//                       _selectedId == null ? 'Add' : 'Update',
//                       style: TextStyle(color: Colors.black),
//                     ),
//                   ),
//                   if (_selectedId != null)
//                     ElevatedButton(
//                       onPressed: () {
//                         setState(() {
//                           _selectedId = null;
//                           descriptionController.clear();
//                         });
//                       },
//                       child: const Text('Cancel'),
//                     ),
//                 ],
//               ),
//               const SizedBox(height: 20),
//               Expanded(
//                 child: ListView.builder(
//                   itemCount: clientProvider.titles.length,
//                   itemBuilder: (context, index) {
//                     int typeId = clientProvider.titles.keys
//                         .elementAt(index);
//                     String description =
//                         clientProvider.titles[typeId]!;

//                     return ListTile(
//                       title: Text(description),
//                       trailing: Row(
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           IconButton(
//                             icon: Icon(
//                               Icons.edit,
//                             ),
//                             onPressed: () {
//                               setState(() {
//                                 _selectedId = typeId;
//                                 descriptionController.text = description;
//                               });
//                             },
//                           ),
//                           IconButton(
//                             icon: Icon(
//                               Icons.delete,
//                               color: Colors.red,
//                             ),
//                             onPressed: () {
//                               deleteItemDialog(context, description, () async {
//                                 await clientProvider.deleteTitle(
//                                     context, typeId);
//                                 setState(() {});
//                               });
//                             },
//                           ),
//                         ],
//                       ),
//                     );
//                   },
//                 ),
//               ),
//             ],
//           );
//         }),
//       ),
//     );
//   }
// }
