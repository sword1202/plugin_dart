import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

/// Screen that shows an example of openFile
class OpenTextPage extends StatelessWidget {
  void _openTextFile(BuildContext context) async {
    final XTypeGroup typeGroup = XTypeGroup(
      label: 'text',
      extensions: ['txt', 'json'],
    );
    final XFile? file = await openFile(acceptedTypeGroups: [typeGroup]);
    if (file == null) {
      // Operation was canceled by the user.
      return;
    }
    final String fileName = file.name;
    final String fileContent = await file.readAsString();

    await showDialog(
      context: context,
      builder: (context) => TextDisplay(fileName, fileContent),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Open a text file"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                primary: Colors.blue,
                onPrimary: Colors.white,
              ),
              child: Text('Press to open a text file (json, txt)'),
              onPressed: () => _openTextFile(context),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget that displays a text file in a dialog
class TextDisplay extends StatelessWidget {
  /// File's name
  final String fileName;

  /// File to display
  final String fileContent;

  /// Default Constructor
  TextDisplay(this.fileName, this.fileContent);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(fileName),
      content: Scrollbar(
        child: SingleChildScrollView(
          child: Text(fileContent),
        ),
      ),
      actions: [
        TextButton(
          child: const Text('Close'),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }
}
