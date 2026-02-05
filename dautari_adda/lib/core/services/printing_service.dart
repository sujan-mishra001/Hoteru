import 'dart:typed_data';
import 'package:flutter_thermal_printer/flutter_thermal_printer.dart';
import 'package:flutter_thermal_printer/utils/printer.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:flutter/services.dart';

class PrintingService {
  static final PrintingService _instance = PrintingService._internal();
  factory PrintingService() => _instance;
  PrintingService._internal() {
    _printerManager.devicesStream.listen((list) {
      devices = list;
    });
  }

  final _printerManager = FlutterThermalPrinter.instance;

  // Track printers
  List<Printer> devices = [];

  Future<void> scanPrinters() async {
    await _printerManager.getPrinters();
  }

  Future<bool> connectPrinter(Printer printer) async {
    bool? isConnected = await _printerManager.connect(printer);
    return isConnected ?? false;
  }

  Future<bool> disconnectPrinter(Printer printer) async {
    await _printerManager.disconnect(printer);
    return true;
  }

  Future<void> printTestPage(Printer printer) async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm80, profile);
    List<int> bytes = [];

    bytes += generator.text('DAUTARI ADDA',
        styles: const PosStyles(align: PosAlign.center, bold: true, height: PosTextSize.size2, width: PosTextSize.size2));
    bytes += generator.text('PRINTER TEST PAGE', styles: const PosStyles(align: PosAlign.center));
    bytes += generator.hr();
    bytes += generator.text('Connection: ${printer.connectionType?.name ?? "Unknown"}', styles: const PosStyles(align: PosAlign.left));
    bytes += generator.text('Address: ${printer.address}', styles: const PosStyles(align: PosAlign.left));
    bytes += generator.feed(2);
    bytes += generator.cut();

    await _printerManager.printData(printer, Uint8List.fromList(bytes));
  }

  Future<void> printReceipt(Printer printer, Map<String, dynamic> order) async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm80, profile);
    List<int> bytes = [];

    // Header
    bytes += generator.text('DAUTARI ADDA',
        styles: const PosStyles(align: PosAlign.center, bold: true, height: PosTextSize.size2, width: PosTextSize.size2));
    bytes += generator.text('Restaurant & Bar', styles: const PosStyles(align: PosAlign.center));
    bytes += generator.hr();

    // Order Info
    bytes += generator.row([
      PosColumn(text: 'Bill #: ${order['bill_number'] ?? 'N/A'}', width: 6),
      PosColumn(text: 'Table: ${order['table_name'] ?? 'N/A'}', width: 6, styles: const PosStyles(align: PosAlign.right)),
    ]);
    bytes += generator.text('Date: ${DateTime.now().toString().substring(0, 16)}');
    bytes += generator.hr();

    // Items Header
    bytes += generator.row([
      PosColumn(text: 'Item', width: 7, styles: const PosStyles(bold: true)),
      PosColumn(text: 'Qty', width: 2, styles: const PosStyles(align: PosAlign.center, bold: true)),
      PosColumn(text: 'Price', width: 3, styles: const PosStyles(align: PosAlign.right, bold: true)),
    ]);

    // Items
    final items = order['items'] as List? ?? [];
    for (var item in items) {
      bytes += generator.row([
        PosColumn(text: item['name'] ?? '', width: 7),
        PosColumn(text: '${item['quantity']}', width: 2, styles: const PosStyles(align: PosAlign.center)),
        PosColumn(text: '${item['price']}', width: 3, styles: const PosStyles(align: PosAlign.right)),
      ]);
    }
    bytes += generator.hr();

    // Totals
    bytes += generator.row([
      PosColumn(text: 'Subtotal', width: 8),
      PosColumn(text: '${order['subtotal']}', width: 4, styles: const PosStyles(align: PosAlign.right)),
    ]);
    bytes += generator.row([
      PosColumn(text: 'Tax', width: 8),
      PosColumn(text: '${order['tax']}', width: 4, styles: const PosStyles(align: PosAlign.right)),
    ]);
    bytes += generator.row([
      PosColumn(text: 'TOTAL', width: 8, styles: const PosStyles(bold: true)),
      PosColumn(
          text: '${order['total']}',
          width: 4,
          styles: const PosStyles(align: PosAlign.right, bold: true, height: PosTextSize.size2)),
    ]);

    bytes += generator.feed(2);
    bytes += generator.text('Thank you for visit!', styles: const PosStyles(align: PosAlign.center));
    bytes += generator.feed(2);
    bytes += generator.cut();

    await _printerManager.printData(printer, Uint8List.fromList(bytes));
  }

  Future<void> printKOT(Printer printer, Map<String, dynamic> kot) async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm80, profile);
    List<int> bytes = [];

    bytes += generator.text('KITCHEN ORDER TICKET',
        styles: const PosStyles(align: PosAlign.center, bold: true, height: PosTextSize.size2));
    bytes += generator.hr();

    bytes += generator.row([
      PosColumn(text: 'KOT: #${kot['kot_number'] ?? 'N/A'}', width: 6, styles: const PosStyles(bold: true)),
      PosColumn(text: 'Table: ${kot['table_name'] ?? 'N/A'}', width: 6, styles: const PosStyles(align: PosAlign.right, bold: true)),
    ]);
    bytes += generator.text('Time: ${DateTime.now().toString().substring(11, 16)}');
    bytes += generator.hr();

    final items = kot['items'] as List? ?? [];
    for (var item in items) {
      bytes += generator.row([
        PosColumn(text: '${item['quantity']} x ${item['name']}', width: 12, styles: const PosStyles(height: PosTextSize.size2)),
      ]);
      if (item['notes'] != null && item['notes'].toString().isNotEmpty) {
        bytes += generator.text('  * ${item['notes']}', styles: const PosStyles()); // removed italic
      }
    }

    bytes += generator.hr();
    bytes += generator.feed(3);
    bytes += generator.cut();

    await _printerManager.printData(printer, Uint8List.fromList(bytes));
  }
}
