import 'package:flutter/material.dart';
import 'package:multi_image_picker/multi_image_picker.dart';
import 'package:owl/DIContainer.dart';
import 'package:owl/account/events/events.dart';
import 'package:owl/account/managers/AccountManager.dart';
import 'package:owl/account/models/AccountModel.dart';
import 'package:owl/general/screens/HomeScreen.dart';

class ProfileWidget extends StatelessWidget {
  final AccountManager _accountManager = DIContainer.resolve<AccountManager>();

  @override
  Widget build(BuildContext context) {
    print('===== Build ProfileWidget =====');

    _accountManager.inEvent.add(LoadAccountEvent());

    return Container(
      padding: const EdgeInsets.fromLTRB(10.0, 30.0, 10.0, 10.0),
      color: primaryColor,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xff4b6cb7),
              Color(0xff182848),
            ],
          ),
          borderRadius: BorderRadius.all(Radius.circular(20.0)),
        ),
        child: StreamBuilder<AccountModel>(
          stream: _accountManager.loadAccount$,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Center(child: CircularProgressIndicator());
            }

            AccountModel account = snapshot.data;

            return Column(
              children: <Widget>[
                SizedBox(height: 20.0),
                CircleAvatar(
                  radius: 50.0,
                  backgroundImage: account.user.profilePicture == null
                      ? AssetImage('assets/images/profile_picture.jpg')
                      : MemoryImage(account.user.profilePicture),
                ),
                SizedBox(height: 10.0),
                GestureDetector(
                  onTap: () async {
                    List<Asset> imageAssets =
                        await MultiImagePicker.pickImages(maxImages: 1);

                    if (imageAssets != null && imageAssets.isNotEmpty) {
                      _accountManager.inEvent.add(
                        AddProfilePictureEvent(profilePicture: imageAssets[0]),
                      );
                    }
                  },
                  child: Icon(Icons.photo_camera),
                ),
                SizedBox(height: 10.0),
                Text(account.userId.toString()),
                Text(account.email),
                Text(account.username),
                // QR-code
              ],
            );
          },
        ),
      ),
    );
  }
}
