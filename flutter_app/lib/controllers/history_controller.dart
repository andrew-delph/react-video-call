// Package imports:
import 'package:get/get.dart';

// Project imports:
import '../models/history_model.dart';
import '../models/user_model.dart';
import '../services/cache_service.dart';
import '../services/options_service.dart';

class HistoryController extends GetxController with StateMixin<HistoryModel> {
  Rx<HistoryModel> historyModel = Rx(HistoryModel());
  RxList<HistoryItemModel> matchHistoryList = RxList();
  RxMap<int, HistoryItemModel> historyMap = RxMap();
  RxInt total = 0.obs;

  final CacheService cacheService = Get.find();
  final OptionsService optionsService;
  HistoryController(this.optionsService);

  @override
  onInit() async {
    super.onInit();
    await loadMoreHistory();
  }

  Future loadMoreHistory() async {
    change(null, status: RxStatus.loading());
    return await optionsService
        .getHistory(matchHistoryList.length, 20)
        .then((body) async {
      if (body.matchHistoryList.isEmpty) {
        change(null, status: RxStatus.empty());
      } else {
        change(body, status: RxStatus.success());
      }

      historyMap.addEntries(body.matchHistoryList
          .where((historyItem) => historyItem.matchId != null)
          .map((historyItem) => MapEntry(historyItem.matchId!, historyItem)));

      total(body.total);

      sortHistory();
    }).catchError((error) {
      change(null, status: RxStatus.error(error.toString()));
    });
  }

  void sortHistory() {
    List<HistoryItemModel> historyItemList = historyMap.values.toList();

    historyItemList
        .sort((a, b) => b.getCreateTime().compareTo(a.getCreateTime()));
    matchHistoryList(historyItemList);
    matchHistoryList.refresh();
  }

  updateFeedback(int matchId, int score) {
    final body = {'match_id': matchId, 'score': score};
    return optionsService.updateFeedback(body).then((match) {
      historyMap[match.matchId!] = match;

      sortHistory();
    }).catchError((error) {
      change(null, status: RxStatus.error(error.toString()));
    });
  }

  Future<UserDataModel?> getUserData(String userId) async {
    return optionsService.getUserData(userId);
  }
}
