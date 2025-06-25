import 'package:flutter/material.dart';
import 'app_data.dart';
import 'app_ui.dart';
import 'dlsettingpanel.dart';
import 'dlimageselector.dart';
import 'dlbutton.dart';
import 'dldialog2.dart';
import 'dart:io';

class SettingsVisual2 extends StatefulWidget {
  const SettingsVisual2({super.key});

  @override
  State<SettingsVisual2> createState() => _SettingsVisual2State();
}

class _SettingsVisual2State extends State<SettingsVisual2> {
  String selectedVisual = DLAppData.appData.visualLayout;
  String selectedImage = '';
  String originalVisual  = DLAppData.appData.visualLayout;

  Map<String, String> selectedBackground = {}; // maps visuallayout to an image
  bool cleanBackgrounds = false;

  _SettingsVisual2State() {
    selectedBackground.addAll(DLAppData.appData.layoutBackgrounds);
  }

  // MG: Issue 0000840: Copy setting between Visual Layouts
  void doSave( BuildContext context, bool withCopy  ) {
    DLAppData.appData.setVisualLayout(DLAppData.appData.newvisualLayout);
    DLAppData.appData.layoutBackgrounds.clear();
    DLAppData.appData.layoutBackgrounds.addAll(selectedBackground);
    if( withCopy ) {
      DLAppData.appData.copySettings( originalVisual, DLAppData.appData.newvisualLayout);
    }
    if (cleanBackgrounds) {
      DLAppData.appData.clearBackgrounds().whenComplete(() {
        DLAppData.appData.store(load: false).whenComplete(() {
          if (context.mounted) {
            Navigator.pop(context);
          }
        });
      });
    } else {
      DLAppData.appData.store(load: false).whenComplete(() {
        if (context.mounted) {
          Navigator.pop(context);
        }
      });
    }
  }

  void buttonHandler(BuildContext context, String label) {
    if (label == "Cancel") {
      Navigator.pop(context);
    } else if (label == "Save") {
      if( DLAppData.appData.newvisualLayout != originalVisual )
      {
        dlDialog2(
            context: context,
            dlType: 'Confirmation',
            message: 'Do you also want to copy your current layout settings to \'${DLAppData.appData.newvisualLayout}\'?',
            buttons: ['Yes', 'No', 'Cancel'],
            onResult: (String result) async {
              if (result == 'Yes') {
                doSave( context, true );
              }
              else if (result == 'No '){
                doSave( context, false );
              }
              // else cancel does nothing.
            });
        return;
      }
      doSave( context, false );
    }
  }

  void refresh() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    double padding = MediaQuery.of(context).viewPadding.top;
    if (padding == 0) {
      padding = 24;
    }

    double width = MediaQuery.sizeOf(context).width;
    double height = MediaQuery.sizeOf(context).height - padding;

    double panelWidth = width / 7;
    double splitGap = 5;
    double halfWidth = (width - panelWidth - (splitGap * 3)) / 2;

    Widget leftSide = SizedBox(
        width: halfWidth,
        child: Column(
          children: [
            SizedBox(
                height: padding,
                child: Text("Select a layout:",
                    style: TextStyle(fontSize: largerBodyFontSize))),
            SizedBox(
                height: height - padding, child: LayoutVisualList(refresh)),
          ],
        ));

    List<Widget> rightWidgets = [SizedBox(height: padding)];

    double topOffset = 60;
    if (!DLAppData.appData.layoutElements.containsKey("DEBUG")) {
      topOffset += 60;
      rightWidgets.add(SizedBox(
          width: width / 5,
          height: 60,
          child: DLButtonWidget(
              label: "Enable Debug style",
              onPressed: () async {
                DLAppData.appData.layoutElements['DEBUG'] = [];
                setState(() {});
              })));
    } else {
      rightWidgets.add(Text("Debug style temporarily enabled",
          style: TextStyle(
              color: sysTextErrorColor, fontSize: smallBodyFontSize)));
    }

    rightWidgets.add(SizedBox(
        width: (width / 5) * 2,
        height: 60,
        child: // This is why topOffset starts at 60
            Row(children: [
          SizedBox(
              width: width / 5,
              height: 60,
              child: DLButtonWidget(
                  label: "Select Background",
                  onPressed: () async {
                    String? selectedImagePath = await DLImageSelector.show(
                        context,
                        'Background Selection',
                        'backgrounds',
                        DLAppData.appData.newvisualLayout,
                        false,
                        true);
                    if (selectedImagePath != null &&
                        selectedImagePath.isNotEmpty) {
                        cleanBackgrounds = true;
                      selectedBackground[DLAppData.appData.newvisualLayout] =
                          selectedImagePath;
                      selectedImage = selectedImagePath;
                      setState(() {
                        selectedImage = selectedImagePath;
                      });
                    } else {
                      // print("User cancelled");
                    }
                  })),
          SizedBox(
              width: width / 5,
              height: 60,
              child: DLButtonWidget(
                  label: "Clear Background",
                  onPressed: () async {
                    cleanBackgrounds = true;
                    selectedBackground[DLAppData.appData.newvisualLayout] = '';
                    selectedImage = '';
                    setState(() {
                      selectedImage = '';
                    });
                  }))
        ])));

    String path =
        selectedBackground.containsKey(DLAppData.appData.newvisualLayout)
            ? selectedBackground[DLAppData.appData.newvisualLayout]!
            : '';
    if (path.isNotEmpty) {
      rightWidgets.add(SizedBox(
          width: halfWidth,
          height: height - (topOffset + padding),
          child: Image(
            image: FileImage(
              File(path),
            )..evict(), // evict old cache, needed since same file name may be cropped
            key: ValueKey(DateTime.now().millisecondsSinceEpoch),
          )));
    } else {
      rightWidgets.add(
        SizedBox(
            width: halfWidth,
            height: height - (topOffset + padding),
            child: Center(
                child: Text("No background selected",
                    style: TextStyle(
                        fontFamily: 'ChakraPetch',
                        fontSize: defaultFontSize,
                        fontWeight: FontWeight.bold)))),
      );
    }

    Widget rightSide = SizedBox(
        width: width / 2, // right side
        child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: rightWidgets));

    Scaffold scaffold = Scaffold(
      resizeToAvoidBottomInset: true,
      body: SingleChildScrollView(
          child: Column(children: [
        SizedBox(height: padding, width: width),
        Container(
          height: height,
          width: width,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage("images/CheckeredFlagBackground.jpg"),
              fit: BoxFit.cover,
            ),
          ),
          child: Row(children: [
            SizedBox(
                width: panelWidth,
                height: height,
                child: DLSettingPanelWidget(
                  iconFile: 'images/NewSettingVisualsIcon.png',
                  onSave: () => buttonHandler(context, "Save"),
                  onCancel: () => buttonHandler(context, "Cancel"),
                )),
            Expanded(
              child: Row(
                children: [
                  // Expanded(
                  //   child: Stack(
                  //     alignment: Alignment.center,
                  //     children: [
                  SizedBox(width: splitGap),
                  SizedBox(
                    width: halfWidth,
                    height: height,
                    child: leftSide,
                  ),

                  SizedBox(width: splitGap),
                  SizedBox(
                    width: halfWidth,
                    height: height,
                    child: rightSide,
                  ),
                ],
                // ),
                // ),
                // ],
              ),
            ),
          ]),
        ),
      ])),
    );

    return scaffold;
  }
}

class LayoutVisualList extends StatefulWidget {
  final VoidCallback onChanged;
  const LayoutVisualList(this.onChanged, {super.key});

  @override
  createState() => _LayoutVisualList();
}

class _LayoutVisualList extends State<LayoutVisualList> {
  String selected = DLAppData.appData.visualLayout;
  // bool initialized = false;

  void onTap(String aselected) {
    widget.onChanged();
    setState(() {
      selected = aselected;
      DLAppData.appData.newvisualLayout = selected;
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> layouts = [];

    // if (initialized == false) {
      DLAppData.appData.getLayoutsOrdered().forEach((key) {
        layouts.add(LayoutVisualCard(
          title: key,
          image: Image.asset('images/LayoutPreview$key.jpg', fit: BoxFit.cover),
          onTap: () {
            onTap(key);
          },
          selected: selected == key,
        ));
      });
    // }

    return SizedBox(
      //height: 150,
      child: Scrollbar(
        child: ListView(
          padding: EdgeInsets.zero,
          scrollDirection: Axis.vertical,
          children: layouts,
        ),
      ),
    );
  }
}

class LayoutVisualCard extends StatelessWidget {
  final String title;
  final Image image;
  final Function() onTap;
  final bool selected;
  const LayoutVisualCard(
      {required this.title,
      required this.image,
      required this.onTap,
      this.selected = false,
      super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(4),
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 16,
                  color: selected ? Colors.green : Colors.white),
            ),
            const SizedBox(height: 4),
            Container(
              decoration: BoxDecoration(
                  border: !selected
                      ? null
                      : Border.all(width: 2, color: Colors.green),
                  borderRadius: BorderRadius.circular(5.0)),
              child: ClipRRect(
                child: image,
              ),
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}
