import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart' as dio_lib;
import 'package:auralive/pages/upload_reels_page/model/upload_reels_model.dart';
import 'package:auralive/utils/api.dart';
import 'package:auralive/utils/utils.dart';

class UploadReelsApi {
  static Future<UploadReelsModel?> callApi({
    required String loginUserId,
    required String videoImage,
    required String videoUrl,
    required String videoTime,
    required String hashTag,
    required String caption,
    required String songId,
    required Function(String) onProgressUpdate, // ✅ Accept progress tracker callback hook
  }) async {
    Utils.showLog("🚀 Upload Reels Api Started via Optimized Stream...");

    final videoFile = File(videoUrl);
    if (!await videoFile.exists()) {
      Utils.showLog("❌ ERROR: Video file does not exist at path: $videoUrl");
      return null;
    }

    try {
      final dio = dio_lib.Dio();

      // Forgiving connection setups for processing larger objects over mobile cells safely
      dio.options.connectTimeout = const Duration(minutes: 5);
      dio.options.sendTimeout = const Duration(minutes: 20);    // ✅ Increased to 20 minutes to prevent premature failure during large data streaming
      dio.options.receiveTimeout = const Duration(minutes: 20); // ✅ Increased to 20 minutes to give server time to write file to disk

      final Map<String, dynamic> formDataMap = {
        'caption': caption,
        'hashTagId': hashTag,
        'videoTime': videoTime,
        'videoUrl': await dio_lib.MultipartFile.fromFile(
          videoUrl,
          filename: videoUrl.split('/').last, // ✅ Explicitly attached file name string parameter
          contentType: dio_lib.DioMediaType('video', 'mp4'),
        ),
      };

      if (songId.isNotEmpty) {
        formDataMap['songId'] = songId;
      }

      if (videoImage.isNotEmpty && await File(videoImage).exists()) {
        formDataMap['videoImage'] = await dio_lib.MultipartFile.fromFile(
          videoImage,
          filename: videoImage.split('/').last, // ✅ Explicitly attached file name string parameter
          contentType: dio_lib.DioMediaType('image', 'jpeg'),
        );
      }

      final formData = dio_lib.FormData.fromMap(formDataMap);

      final response = await dio.post(
        "${Api.uploadReels}?userId=$loginUserId",
        data: formData,
        options: dio_lib.Options(
          headers: {
            "key": Api.secretKey,
          },
          responseType: dio_lib.ResponseType.json,
        ),
        onSendProgress: (sent, total) {
          if (total != -1) {
            double progress = (sent / total) * 100;
            // Update percentage string live on the UI window frame
            onProgressUpdate("${progress.toStringAsFixed(0)}%");
          }
        },
      );

      if (response.statusCode == 200) {
        final jsonResult = response.data is String ? jsonDecode(response.data) : response.data;
        return UploadReelsModel.fromJson(jsonResult);
      } else {
        Utils.showLog("❌ Upload Failed Status: ${response.statusCode}");
        return null;
      }
    } on dio_lib.DioException catch (e) {
      if (e.response?.statusCode == 413) {
        Utils.showLog("❌ ERROR: File too large (413). Check backend / Nginx client_max_body_size config.");
      } else {
        Utils.showLog("❌ Dio Network Exception => ${e.type} - ${e.message}");
      }
      return null;
    } catch (e) {
      Utils.showLog("❌ Upload General Exception => $e");
      return null;
    }
  }
}
