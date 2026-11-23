import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:onnxruntime/onnxruntime.dart';

class CryClassifierService {
  OrtSession? _session;
  List<String> _labels = [];

  Future<void> init() async {
    OrtEnv.instance.init();

    // 1) قراءة أسماء الفئات من ملف meta.json
    final metaStr = await rootBundle.loadString('assets/models/mahd_pipeline1_meta.json');
    final meta = jsonDecode(metaStr);
    _labels = List<String>.from(meta['labels']);

    // 2) تحميل ملف الـ ONNX مباشرة من assets إلى الذاكرة
    final rawModel = await rootBundle.load('assets/models/mahd_pipeline1_int8.onnx');
    final bytes = rawModel.buffer.asUint8List();
    final sessionOptions = OrtSessionOptions();
    _session = OrtSession.fromBuffer(bytes, sessionOptions);
  }

  /// تمررين له الصوت الخام بطول 32000 عينة (ثانيتين على 16kHz)
  Future<Map<String, double>> predict(Float32List audio32k) async {
    if (_session == null) throw Exception('Model not initialized');

    // Peak normalization فقط (التطبيع الإحصائي والـ Softmax مدمجة داخل الـ ONNX)
    double maxAbs = 0.0;
    for (final v in audio32k) {
      if (v.abs() > maxAbs) maxAbs = v.abs();
    }
    final normalized = Float32List(32000);
    final len = min(audio32k.length, 32000);
    for (int i = 0; i < len; i++) {
      normalized[i] = maxAbs > 0 ? (audio32k[i] / maxAbs) : audio32k[i];
    }

    // تجهيز المدخل بنفس الاسم اللي صدّرناه ("audio")
    final inputTensor = OrtValueTensor.createTensorWithDataList(normalized, [1, 32000]);
    final runOptions = OrtRunOptions();
    final outputs = await _session!.runAsync(runOptions, {'audio': inputTensor});

    // قراءة مصفوفة الاحتمالات الجاهزة ("probs")
    final probs = (outputs?.first?.value as List<List<double>>).first;

    // مهم جداً: تحرير الذاكرة بعد كل استنتاج
    inputTensor.release();
    runOptions.release();
    outputs?.forEach((e) => e?.release());

    return {
      for (int i = 0; i < _labels.length; i++) _labels[i]: probs[i],
    };
  }

  void dispose() {
    _session?.release();
    OrtEnv.instance.release();
  }
}
