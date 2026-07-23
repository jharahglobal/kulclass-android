import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:auralive/pages/reels_page/model/fetch_reels_model.dart';
import 'package:auralive/utils/api.dart';
import 'package:auralive/utils/utils.dart';

class FetchReelsApi {
  static int startPagination = 0;
  static int limitPagination = 20;

  static Future<FetchReelsModel?> callApi({required String loginUserId, required String videoId}) async {
    Utils.showLog("Get Reels Api Calling... ");

    startPagination += 1;

    Utils.showLog("Get Reels Pagination Page => $startPagination");

    String url = "${Api.fetchReels}?start=$startPagination&limit=$limitPagination&userId=$loginUserId";
    if (videoId.isNotEmpty) {
      url += "&videoId=$videoId";
    }
    final uri = Uri.parse(url);
    Utils.showLog("Get Reels Api Url => $uri");

    final headers = {"key": Api.secretKey};

    try {
      var response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        Utils.showLog("Get Reels Api Response => ${response.body}");

        // Check if the response is a Map or a List at the top level.
        if (jsonResponse is Map<String, dynamic>) {
          // If it's a map, proceed with the normal parsing.
          return FetchReelsModel.fromJson(jsonResponse);
        } else if (jsonResponse is List<dynamic>) {
          // If it's a list, manually create the model and parse the data.
          // This is the most likely scenario given your error.
          final List<Data> reelsData = jsonResponse.map((json) => Data.fromJson(json)).toList();
          return FetchReelsModel(
            status: true,
            message: "Reels fetched successfully",
            data: reelsData,
          );
        } else {
          // Handle unexpected response types
          Utils.showLog("Get Reels Api Error: Unexpected JSON response type");
        }
      } else {
        Utils.showLog("Get Reels Api StateCode Error: ${response.statusCode}");
      }
    } catch (error) {
      Utils.showLog("Get Reels Api Error => $error");
    }
    return null;
  }
}
