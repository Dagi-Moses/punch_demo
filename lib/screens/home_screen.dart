import 'package:flutter/material.dart';

import '../widgets/side_menu.dart';

class AdminHome extends StatelessWidget {
  final Widget child;

  const AdminHome({super.key, required this.child});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
     
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SideMenu(),
            Expanded(
  
              child: Container(
                // padding: const EdgeInsets.only(
                //     top: 12, bottom: 12, left: 12, right: 12),
                    child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
