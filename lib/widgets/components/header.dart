import 'package:provider/provider.dart';
import 'package:punch/src/color_constants.dart';
import 'package:punch/responsiveness/responsive.dart';
import 'package:flutter/material.dart';
import 'package:punch/providers/authProvider.dart';
class ProfileCard extends StatelessWidget {
  const ProfileCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;

    // Define dynamic sizes based on screen size
    double cardHeight = Responsive.isMobile(context) ? 45 : 65;
    double horizontalPadding = Responsive.isMobile(context) ? 8 : 16;
    double verticalPadding = Responsive.isMobile(context) ? 4 : 10;

    return Card(
      elevation: 4,
      margin: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Container(
        height: cardHeight,
        padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding, vertical: verticalPadding),
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.white),
        ),
       child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
                
              children: [
                // Show avatar only on desktop
                if (Responsive.isDesktop(context))
                  const CircleAvatar(
                    radius: 20,
                    backgroundImage: AssetImage("assets/images/profile_pic.png"),
                  ),
            
                // Spacing between avatar and text
                if (Responsive.isDesktop(context)) const SizedBox(width: 10),
            
                // Show text only on tablet & desktop
                if (!Responsive.isMobile(context))
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          user!.loginId.toString().split('.').last,
                          style: Theme.of(context).textTheme.bodyMedium,
                          overflow:
                              TextOverflow.ellipsis, // Prevents overflow issues
                        ),
                        Text(
                          user.lastName!,
                          style: Theme.of(context).textTheme.bodySmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
            
                // Dropdown icon (always visible)
                const Icon(Icons.keyboard_arrow_down),
              ],
            ),
        ),
        ),
      
    );
  }
}
