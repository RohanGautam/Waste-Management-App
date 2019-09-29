import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:waste_management/MainPage.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pdf;
import 'package:printing/printing.dart';

class AfterLockReport extends StatefulWidget {
  var weight, destination, src, volume;

  LatLng latlng;
  AfterLockReport(
      {this.weight, this.destination, this.src, this.volume, this.latlng});

  @override
  _AfterLockReportState createState() => _AfterLockReportState();
}

class _AfterLockReportState extends State<AfterLockReport> {
  Widget infoSnippet(String name, var info, var unit) {
    return RaisedButton(
      child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                "$name",
                style: TextStyle(fontSize: 15),
                overflow: TextOverflow.ellipsis,
              ),
              VerticalDivider(
                thickness: 2,
              ),
              Text(
                "$info $unit",
                style: TextStyle(fontSize: 14),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              )
            ],
          )),
      onPressed: null,
      shape: RoundedRectangleBorder(
        borderRadius: new BorderRadius.circular(30.0),
      ),
      disabledTextColor: Colors.white,
      disabledColor: Colors.blueGrey,
    );
  }

  Widget customButton(String name,
      {Color backColor = Colors.green,
      Color textColor = Colors.white,
      var func = null}) {
    return RaisedButton(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          name,
          style: TextStyle(fontSize: 25),
        ),
      ),
      onPressed: func,
      shape: RoundedRectangleBorder(
        borderRadius: new BorderRadius.circular(30.0),
      ),
      color: backColor,
      textColor: textColor,
      disabledColor: backColor,
      disabledTextColor: textColor,
    );
    // return Text("hi");
  }

  void goHome() {
    Navigator.of(context).push(MaterialPageRoute(builder: (context) {
      return MainPage();
    })); // change to chat page for testing terminal commands
  }

  void exportPdf() {
    Printing.layoutPdf(
      onLayout: buildPdf,
    );
  }

  List<int> buildPdf(PdfPageFormat format) {
    final pdf.Document doc = pdf.Document();

    doc.addPage(
      pdf.Page(
        pageFormat: format,
        build: (pdf.Context context) {
          return pdf.ConstrainedBox(
            constraints: const pdf.BoxConstraints.expand(),
            child: pdf.FittedBox(
              child: pdf.Column(
                children: <pdf.Widget>[
                  pdf.Text('Bin lock report',
                      style: pdf.TextStyle(fontSize: 20)),
                  pdf.Text('Weight: ${widget.weight}',
                      style: pdf.TextStyle(fontSize: 10)),
                  pdf.Text('Volume: ${widget.volume}',
                      style: pdf.TextStyle(fontSize: 10)),
                  pdf.Text('Destination: ${widget.destination}',
                      style: pdf.TextStyle(fontSize: 10)),
                  pdf.Text(
                    'Source: ${widget.src}',
                    style: pdf.TextStyle(fontSize: 10),
                  )
                ],
              ),
            ),
          );
        },
      ),
    );

    return doc.save();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("data"),
      ),
      body: Center(
          child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            Text(
              "Bin Lock Report",
              style: TextStyle(fontSize: 40),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                infoSnippet("Weight", widget.weight, 'kg'),
                infoSnippet("Destination", widget.destination, ''),
                infoSnippet("Source", widget.src, ''),
                infoSnippet("LatLong", widget.latlng, ''),
                infoSnippet("Volume", widget.volume, 'cm3'),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                customButton("Go home", func: goHome),
                customButton("Export as pdf", backColor: Colors.blue, func: exportPdf)
              ],
            )
          ],
        ),
      )),
    );
  }
}
