import 'package:flutter/material.dart';
import 'package:owl/DIContainer.dart';
import 'package:owl/general/screens/HomeScreen.dart';
import 'package:owl/logging/managers/LoggingManager.dart';

class LoggingWidget extends StatelessWidget {
  final LoggingManager _loggingManager = DIContainer.resolve<LoggingManager>();

  @override
  Widget build(BuildContext context) {
    print('===== Build LoggingWidget =====');

    return GestureDetector(
      onTap: () {
        _loggingManager.getLogs();
      },
      child: Container(
        padding: const EdgeInsets.fromLTRB(10.0, 30.0, 10.0, 10.0),
        color: primaryColor,
        child: GestureDetector(
          onTap: () {
            _loggingManager.getLogs();
          },
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xff000428),
                  Color(0xff004e92),
                ],
              ),
              borderRadius: BorderRadius.all(Radius.circular(20.0)),
            ),
            child: StreamBuilder<List<String>>(
              stream: _loggingManager.getLogs$,
              builder: (context, snapshot) {
                List<String> logs = snapshot.data;

                return ListView.builder(
                  itemCount: logs?.length ?? 0,
                  itemBuilder: (context, index) {
                    String message = logs[index];

                    return Container(
                      margin: EdgeInsets.only(
                        bottom: index == logs.length - 1 ? 0.0 : 10.0,
                        right: 20.0,
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: 20.0,
                        vertical: 10.0,
                      ),
                      decoration: BoxDecoration(
                        color: Color(0xFFe7717d),
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(20.0),
                          bottomRight: Radius.circular(20.0),
                        ),
                      ),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: <Widget>[
                            SelectableText(message),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
