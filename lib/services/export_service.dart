import 'dart:typed_data';
import 'package:csv/csv.dart';
import 'package:file_saver/file_saver.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/riwayat_scan_model.dart';

class ExportService {
  static Future<void> exportToCsv(List<RiwayatScanModel> data) async {
    List<List<dynamic>> rows = [
      ["ID", "Tanggal", "Nama Lahan", "Nilai BWD", "Status BWD", "Penyakit", "Akurasi", "Tindakan"],
    ];

    for (var item in data) {
      rows.add([
        item.id,
        item.formattedDateTime,
        item.lahan?.name ?? "Lahan Utama",
        item.bwdValue ?? "-",
        item.bwdStatus ?? "-",
        item.penyakit,
        item.akurasi ?? 0.0,
        item.tindakan,
      ]);
    }

    String csvStr = const CsvEncoder().convert(rows);
    Uint8List bytes = Uint8List.fromList(csvStr.codeUnits);
    
    await FileSaver.instance.saveFile(
      name: "laporan_scan_padi_${DateTime.now().millisecondsSinceEpoch}",
      bytes: bytes,
      fileExtension: "csv",
      mimeType: MimeType.csv,
    );
  }

  static Future<void> exportToPdf(List<RiwayatScanModel> data) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            pw.Header(level: 0, child: pw.Text("Laporan Riwayat Scan PadiNexa (BWD & Penyakit)")),
            pw.TableHelper.fromTextArray(
              context: context,
              headers: ["Tanggal", "Lahan", "Nilai BWD", "Status BWD", "Penyakit", "Akurasi"],
              data: data.map((item) => [
                item.formattedDateTime,
                item.lahan?.name ?? "Lahan Utama",
                item.bwdValue?.toString() ?? "-",
                item.bwdStatus ?? "-",
                item.penyakit,
                "${item.akurasi ?? 0.0}%"
              ]).toList(),
            ),
          ];
        },
      ),
    );

    Uint8List bytes = await pdf.save();
    await FileSaver.instance.saveFile(
      name: "laporan_scan_padi_${DateTime.now().millisecondsSinceEpoch}",
      bytes: bytes,
      fileExtension: "pdf",
      mimeType: MimeType.pdf,
    );
  }
}
