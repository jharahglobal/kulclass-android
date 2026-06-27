import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart' as dio_lib; // Use prefix to avoid conflicts
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
  }) async {
    Utils.showLog("🚀 Upload Reels Api Started via Optimized Stream...");
    Utils.showLog("   📍 Video Path: $videoUrl");
    Utils.showLog("   📍 Thumb Path: $videoImage");

    // 1. Validate File Existence
    final videoFile = File(videoUrl);
    if (!await videoFile.exists()) {
      Utils.showLog("❌ ERROR: Video file does not exist at path: $videoUrl");
      return null;
    }

    try {
      final dio = dio_lib.Dio();

      // Configure timeouts to be forgiving on slower network speeds for large files
      dio.options.connectTimeout = const Duration(minutes: 2);
      dio.options.receiveTimeout = const Duration(minutes: 5);

      // 2. Prepare Form Data with Multipart Stream
      final Map<String, dynamic> formDataMap = {
        'caption': caption,
        'hashTagId': hashTag,
        'videoTime': videoTime,
        'videoUrl': await dio_lib.MultipartFile.fromFile(
          videoUrl,
          contentType: dio_lib.DioMediaType('video', 'mp4'),
        ),
      };

      if (songId.isNotEmpty) {
        formDataMap['songId'] = songId;
      }

      if (videoImage.isNotEmpty && await File(videoImage).exists()) {
        formDataMap['videoImage'] = await dio_lib.MultipartFile.fromFile(
          videoImage,
          contentType: dio_lib.DioMediaType('image', 'jpeg'),
        );
        Utils.showLog("   ✅ Image File Attached");
      }

      final formData = dio_lib.FormData.fromMap(formDataMap);

      // 3. Send Request with Natively Streamed Chunk Buffering
      Utils.showLog("⏳ Streaming chunks to Server...");
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
            Utils.showLog("📤 Uploading: ${progress.toStringAsFixed(1)}%");
          }
        },
      );

      Utils.showLog("📡 Status Code: ${response.statusCode}");
      
      if (response.statusCode == 200) {
        // Dio automatically parses JSON string responses into Maps
        final jsonResult = response.data is String ? jsonDecode(response.data) : response.data;
        Utils.showLog("✅ Upload Success: $jsonResult");
        return UploadReelsModel.fromJson(jsonResult);
      } else {
        Utils.showLog("❌ Upload Failed Status: ${response.statusCode}");
        return null;
      }
    } on dio_lib.DioException catch (e) {
      if (e.response?.statusCode == 413) {
        Utils.showLog("❌ ERROR: File too large (413). Check backend / Nginx client_max_body_size config.");
      } else {
        Utils.showLog("❌ Dio Network Exception => ${e.message} | Response: ${e.response?.data}");
      }
      return null;
    } catch (e) {
      Utils.showLog("❌ Upload General Exception => $e");
      return null;
    }
  }
}
