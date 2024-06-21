package br.com.academiadoflutter.printers_poc
import android.content.ContentValues.TAG
import android.content.Context
import android.graphics.Canvas

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Typeface
import android.hardware.usb.UsbManager
import android.os.Environment
import android.util.Log
import androidx.annotation.NonNull
import com.brother.ptouch.sdk.LabelInfo
import com.brother.ptouch.sdk.Printer
import com.brother.ptouch.sdk.PrinterInfo
import com.brother.ptouch.sdk.PrinterStatus
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.brother_printer"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
            call, result ->
            if (call.method == "printLabel") {
                val text = call.argument<String>("text")
                val printResult = printLabel(text!!)
                if (printResult != null) {
                    result.success(printResult)
                } else {
                    result.error("UNAVAILABLE", "Print failed", null)
                }
            }else if(call.method == "printImage") {
                val imageBytes: ByteArray = call.argument<ByteArray>("image")!!
                printImage(imageBytes)
            } else {
                result.notImplemented()
            }
        }
    }
    fun createTextBitmap2(text: String): Bitmap {
        val paint = Paint(Paint.ANTI_ALIAS_FLAG)
        paint.textSize = 16f
        paint.typeface = Typeface.create(Typeface.DEFAULT, Typeface.NORMAL)
        paint.color = android.graphics.Color.BLACK

        val lines = text.split("\n")
        val maxWidth = lines.maxOf { line -> paint.measureText(line).toInt() }
        val lineHeight = paint.fontMetricsInt.descent - paint.fontMetricsInt.ascent
        val height = lineHeight * lines.size

        val bitmap = Bitmap.createBitmap(maxWidth, height, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        canvas.drawColor(android.graphics.Color.WHITE)

        var y = -paint.fontMetricsInt.ascent
        for (line in lines) {
            canvas.drawText(line, 0f, y.toFloat(), paint)
            y += lineHeight
        }

        return bitmap
    }
    private fun printLabel(text: String): String? {
        return try {
            // Crie uma imagem a partir do texto
            val bitmap = createTextBitmap2(text)

            // Salve a imagem em um arquivo temporário
//            val tempFile = File(context.filesDir, "temp.png");
//            tempFile.writeText(text);
            val tempFile = File(context.getExternalFilesDir(Environment.DIRECTORY_DOCUMENTS), "print_text.png")
            FileOutputStream(tempFile).use { output ->
                bitmap.compress(Bitmap.CompressFormat.PNG, 100, output)
            }

            val myPrinter = Printer()



            val myPrinterInfo = PrinterInfo().apply {
                printerModel = PrinterInfo.Model.QL_810W
                port = PrinterInfo.Port.USB
                printMode = PrinterInfo.PrintMode.FIT_TO_PAGE
                paperSize = PrinterInfo.PaperSize.CUSTOM
                labelNameIndex = LabelInfo.QL700.W62RB.ordinal
                customPaperWidth = 62
                customPaperLength = 29
                isAutoCut = true
                isHalfCut = false
            }
            val error = setupConnectionManagers(context = context, printer = myPrinter, printInfo = myPrinterInfo)

            myPrinter.printerInfo = myPrinterInfo


            val connected = myPrinter.startCommunication();
            println("Connected: $connected")
            println("mudei")


            //val status: PrinterStatus = myPrinter.printFile(tempFile.path)
            //val status: PrinterStatus = myPrinter.printFile(tempFile.absolutePath)
            val status: PrinterStatus = myPrinter.printImage(bitmap)


            if (status.errorCode == PrinterInfo.ErrorCode.ERROR_NONE) {
                println("Impressão concluída com sucesso")
            } else {
                println("Erro na impressão: ${status.errorCode}")
            }
            "Print successful"
        } catch (e: Exception) {
            null
        }
    }

    private fun printImage(imageBytes: ByteArray): String? {
        return try {
            // Crie uma imagem a partir do texto
            val bitmap = BitmapFactory.decodeByteArray(imageBytes, 0, imageBytes.size)


            val myPrinter = Printer()



            val myPrinterInfo = PrinterInfo().apply {
                printerModel = PrinterInfo.Model.QL_810W
                port = PrinterInfo.Port.USB
                printMode = PrinterInfo.PrintMode.FIT_TO_PAGE
                paperSize = PrinterInfo.PaperSize.CUSTOM
                labelNameIndex = LabelInfo.QL700.W62RB.ordinal
                customPaperWidth = 62
                customPaperLength = 29
                isAutoCut = true
                isHalfCut = false
            }
            val error = setupConnectionManagers(context = context, printer = myPrinter, printInfo = myPrinterInfo)

            myPrinter.printerInfo = myPrinterInfo


            val connected = myPrinter.startCommunication();
            println("Connected: $connected")
            println("mudei")


            //val status: PrinterStatus = myPrinter.printFile(tempFile.path)
            //val status: PrinterStatus = myPrinter.printFile(tempFile.absolutePath)
            val status: PrinterStatus = myPrinter.printImage(bitmap)


            if (status.errorCode == PrinterInfo.ErrorCode.ERROR_NONE) {
                println("Impressão concluída com sucesso")
            } else {
                println("Erro na impressão: ${status.errorCode}")
            }
            "Print successful"
        } catch (e: Exception) {
            null
        }
    }

    fun createTextBitmap(text: String): Bitmap {
        val paint = Paint().apply {
            color = Color.BLACK
            textSize = 24f
            typeface = Typeface.create(Typeface.DEFAULT, Typeface.BOLD)
            isAntiAlias = true
        }

        val textWidth = paint.measureText(text)
        val textHeight = paint.descent() - paint.ascent()
        val bitmapWidth = (textWidth + 20).toInt()
        val bitmapHeight = (textHeight + 20).toInt()

        val bitmap = Bitmap.createBitmap(bitmapWidth, bitmapHeight, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        canvas.drawColor(Color.WHITE)
        canvas.drawText(text, 10f, -paint.ascent() + 10f, paint)

        return bitmap
    }


    fun setupConnectionManagers(context: Context, printInfo: PrinterInfo, printer: Printer): PrinterInfo.ErrorCode {

        if (printInfo.workPath.isEmpty()) {
            printInfo.workPath = context.filesDir.absolutePath + "/";
        }

        if (printInfo.port == PrinterInfo.Port.USB) {
            val usbManager = context.getSystemService(Context.USB_SERVICE) as UsbManager
            val usbDevice = printer.getUsbDevice(usbManager)
            val currSpecs = printer.printerSpec

            if (usbDevice == null) {
                Log.e(TAG, "USB not Connected")
                return PrinterInfo.ErrorCode.ERROR_BROTHER_PRINTER_NOT_FOUND
            }
            // Check if the user has the permission to print to the device.
            val hasPermission = usbManager.hasPermission(usbDevice)
            if (!hasPermission) {
                print("Não tem permissão Cacete")
                // Block until granted/denied
                //val granted = BrotherManager.requestUsbPermission(context = context, usbManager = usbManager, usbDevice = usbDevice)//.take()

            }
        }

        return PrinterInfo.ErrorCode.ERROR_NONE
    }
}
