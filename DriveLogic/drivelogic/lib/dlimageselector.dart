import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:external_path/external_path.dart';
import 'dlimagecrop.dart';
import 'package:image/image.dart' as img;

class DLImageSelector extends StatefulWidget {
  final String titleDialog;
  final String subFolder;
  final String filePrefix;
  final bool withCopy;
  final bool withSubFolderSource;

  const DLImageSelector( this.titleDialog, this.subFolder, this.filePrefix, this.withSubFolderSource, this.withCopy, {super.key});

  static Future<String?> show(BuildContext context, String titleDialog, String subFolder, String filePrefix, bool withSubFolderSource, bool withCopy) async {
    return await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => DLImageSelector( titleDialog, subFolder, filePrefix, withSubFolderSource, withCopy ),
    );
  }

  @override
  State<DLImageSelector> createState() => _DLImageSelectorState();
}

enum Mode { folderSelect, fileSelect }

class _DLImageSelectorState extends State<DLImageSelector> {
  Mode mode = Mode.folderSelect;
  Map<String, String> folders = {};
  String? selectedFolder;
  File? selectedImage;
  List<File> imageFiles = [];
  String title = "Background Selection";
  Rect? curCrop;

  @override
  void initState() {
    super.initState();
    _requestPermission();
  }

  Future<void> _requestPermission() async {
    var status = await Permission.manageExternalStorage.request();
    if (!status.isGranted && mounted ) {
        Navigator.of(context).pop();
    }
  }

  Future<Map<String, String>> getAvailableFolders() async {
    Map<String, String> ret = {};
    List<String>? x = await ExternalPath.getExternalStorageDirectories();

    int extra = 1;
    if( x != null )
    {
      for (var element in x) {
        String tmp = element.replaceAll('/storage/', '');
        if( tmp.length == 9 && tmp[4]=='-' )
        {
          if( extra == 1 ) {
            ret[ 'USB' ] = x[1];
          } else {
            ret[ 'USB$extra' ] = x[1];
          }
          extra++;
        }
      }
    }

    if( kDebugMode ) {
      String mockPath = '/storage/emulated/0/MockUSB';
      // Create mock folder if needed.
      final mockDir = Directory( mockPath );
      if ( await mockDir.exists()) {
        ret[ 'USB(dbg)' ] = mockPath;
      } else {
        mockPath = '/sdcard/MockUSB';
        // Create mock folder if needed.
        final mockDir = Directory( mockPath );
        if ( await mockDir.exists()) {
          ret[ 'USB(dbg)' ] = mockPath;
        }
      }

    }

    if( widget.withSubFolderSource && widget.subFolder.isNotEmpty ) {
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final String destPath = p.join(appDocDir.path, widget.subFolder);

      // Create folder if needed.
      final destDir = Directory( destPath );
      if ( await destDir.exists()) {
        ret[ widget.subFolder ] = destDir.path;
      }

    }

    ret[ 'Downloads' ] = await ExternalPath.getExternalStoragePublicDirectory( ExternalPath.DIRECTORY_DOWNLOAD, );
    ret[ 'Pictures' ] = await ExternalPath.getExternalStoragePublicDirectory( ExternalPath.DIRECTORY_PICTURES, );
    ret[ 'DCIM' ] = await ExternalPath.getExternalStoragePublicDirectory( ExternalPath.DIRECTORY_DCIM, );

    folders = ret;
    return ret;
  }

  Future<void> loadImages(String folderPath) async {
    final dir = Directory(folderPath);
    if (await dir.exists()) {
      final files =
      dir
          .listSync()
          .whereType<File>()
          .where(
            (f) => [
          '.jpg',
          '.jpeg',
          '.png',
        ].contains(p.extension(f.path).toLowerCase()),
      )
          .toList();
      setState(() {
        imageFiles = files;
        mode = Mode.fileSelect;
      });
    }
  }

  void onSelectionChanged( Rect selection ) {
    curCrop = selection;
  }

  Widget buildFolderSelection() {
    return FutureBuilder<Map<String, String>>(
      future: getAvailableFolders(),
      builder: (context, snapshot) {

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final folders = snapshot.data!;

        return SingleChildScrollView( child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Select Folder",
              style: TextStyle( color: Colors.black, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            ...folders.entries.map((entry) {
              return ListTile(
                title: Text(entry.key),
                // dense: true,
                visualDensity: const VisualDensity(vertical: -3),
                // subtitle: Text(entry.value),
                onTap: () {
                  selectedFolder = entry.value;
                  loadImages(entry.value);
                },
              );

            }),
            const SizedBox(height: 10),
            // ElevatedButton(
            //   onPressed: () => Navigator.of(context).pop(null),
            //   child: const Text("Back"),
            // ),
          ],
        ));
      },
    );
  }

  Widget buildFileSelection( BuildContext conext ) {
    Size displaySize = MediaQuery.sizeOf(context);
    EdgeInsets displayPadding = MediaQuery.of(context).viewPadding;

    double width = displaySize.width;
    double height = displaySize.height - (displayPadding.top+displayPadding.bottom);
    double aspect = width / height;

    Widget? rightSide;
    if( selectedImage != null ) {
      //rightSide = Image.file(selectedImage!, fit: BoxFit.contain);
      rightSide = DLImageCrop(file: selectedImage!.path, aspectRatio: aspect, onChanged: onSelectionChanged);
    } else {
      rightSide = const Center(child: Text("No image selected", style: TextStyle(color: Colors.black)));
    }

    return SizedBox(
      height: 400,
      width: 600,
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: ListView.builder(
              itemCount: imageFiles.length,
              itemBuilder: (context, index) {
                final file = imageFiles[index];
                return ListTile(
                  title: Text(p.basename(file.path)),
                  selected: selectedImage?.path == file.path,
                  onTap: () {
                    setState(() {
                      selectedImage = file;
                    });
                  },
                );
              },
            ),
          ),
          const VerticalDivider(),
          Expanded(
            flex: 3,
            child: Container( child: rightSide ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return AlertDialog(
      title: Text( title,
        style: const TextStyle( color: Colors.black )),
      content:
      mode == Mode.folderSelect
          ? buildFolderSelection()
          : buildFileSelection( context ),
      actions: [

        ElevatedButton(
          onPressed: () {
            if (mode == Mode.folderSelect) {
              Navigator.of(context).pop(null);
            } else {
              setState(() {
                mode = Mode.folderSelect;
                selectedImage = null;
              });
            }
          },
          child: const Text("Back"),
        ),

        if (mode == Mode.fileSelect)
          ElevatedButton(
            onPressed: onOK,
            // selectedImage != null
            //     ? () => Navigator.of(context).pop(selectedImage!.path)
            //     : null,
            child: const Text("OK"),
          ),
      ],
    );
  }

  Future<void> onOK()
  async {
    String fileName="";
    if( selectedImage != null )
    {
      if( widget.withCopy ) {
        showDialog(
          context: context,
          barrierDismissible: false,
          barrierColor: Colors.black.withValues( alpha: .5),
          builder: (BuildContext context) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          },
        );

        // Copy selectedImage!.path to documents
        try {
          final Directory appDocDir = await getApplicationDocumentsDirectory();
          String pre = widget.filePrefix.isNotEmpty ?  '${widget.filePrefix}_' : '';
          final String destPath = p.join(appDocDir.path, widget.subFolder, pre + p.basename( selectedImage!.path ));

          // Create folder if needed.
          final destDir = Directory(p.dirname(destPath));
          if (!await destDir.exists()) {
            await destDir.create(recursive: true);
          }
          if( destPath !=selectedImage!.path ) {
            fileName = await imageCopyAndCrop( srcFile: selectedImage!.path, dstFile: destPath, crop: curCrop );
          }
          else {
            fileName = destPath;
          }
        } catch (e) {
          setState(() { // Just redraw for now
          });
        }
        if( mounted ) {
          Navigator.of(context).pop(fileName); // When the task is complete
        }
      }
      else {
        fileName = selectedImage!.path;
      }
      if( mounted ) {
        Navigator.of(context).pop(fileName);
      }
    }
  }

  Future<String> imageCopyAndCrop({
    required String srcFile,
    required String dstFile,
    Rect? crop,
  }) async {
    if (crop == null) {
      if (srcFile != dstFile) {
        await File(srcFile).copy(dstFile);
      }
      return dstFile;
    }

    final bytes = await File(srcFile).readAsBytes();
    final image = img.decodeImage(bytes);
    if (image == null) {
      throw Exception('Failed to decode image');
    }

    // Convert crop Rect from double to int and ensure it's within bounds
    final left = crop.left.round().clamp(0, image.width - 1);
    final top = crop.top.round().clamp(0, image.height - 1);
    final width = crop.width.round().clamp(1, image.width - left);
    final height = crop.height.round().clamp(1, image.height - top);

    final cropped = img.copyCrop(image, x: left, y: top, width: width, height: height);

    final isPng = srcFile.toLowerCase().endsWith('.png');
    final encoded = isPng ? img.encodePng(cropped) : img.encodeJpg(cropped);

    await File(dstFile).writeAsBytes(encoded);
    return dstFile;
  }

}
