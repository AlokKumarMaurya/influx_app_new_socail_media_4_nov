import 'package:get/get.dart';
import '../data/models/story_model.dart';
import '../data/services/story_service.dart';

class StoryController extends GetxController {
  final StoryService _storyService = StoryService();

  // Current state for viewing
  final RxInt currentGroupIndex = 0.obs;
  final RxInt currentStoryIndex = 0.obs;
  final RxList<StoryGroup> storyGroups = <StoryGroup>[].obs;

  void initViewer(List<StoryGroup> groups, int initialGroupIndex) {
    storyGroups.value = groups;
    currentGroupIndex.value = initialGroupIndex;
    currentStoryIndex.value = 0;
    _recordView(currentStory.id);
  }

  StoryGroup get currentGroup => storyGroups[currentGroupIndex.value];
  StoryModel get currentStory => currentGroup.stories[currentStoryIndex.value];

  void nextStory() {
    if (currentStoryIndex.value < currentGroup.stories.length - 1) {
      currentStoryIndex.value++;
      _recordView(currentStory.id);
    } else {
      nextGroup();
    }
  }

  void previousStory() {
    if (currentStoryIndex.value > 0) {
      currentStoryIndex.value--;
    } else {
      previousGroup();
    }
  }

  void nextGroup() {
    if (currentGroupIndex.value < storyGroups.length - 1) {
      currentGroupIndex.value++;
      currentStoryIndex.value = 0;
      _recordView(currentStory.id);
    } else {
      Get.back(); // End of all stories
    }
  }

  void previousGroup() {
    if (currentGroupIndex.value > 0) {
      currentGroupIndex.value--;
      currentStoryIndex.value = 0; // Or last story of previous group? Usually 0.
    } else {
      Get.back();
    }
  }

  Future<void> _recordView(int storyId) async {
    await _storyService.recordView(storyId);
  }

  Future<void> deleteStory(int storyId) async {
    try {
      await _storyService.deleteStory(storyId);
      // Update local state if needed (remove from memory)
    } catch (e) {
      Get.snackbar('error'.tr, 'failed_to_delete_story'.tr);
    }
  }
}
