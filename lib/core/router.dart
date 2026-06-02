import 'package:flutter/material.dart';
import 'package:novel_ide/presentation/pages/main_shell_v2.dart';
import 'package:novel_ide/presentation/pages/writing/editor_page.dart';
import 'package:novel_ide/presentation/pages/writing/rich_editor_page.dart';
import 'package:novel_ide/presentation/pages/writing/global_search_page.dart';
import 'package:novel_ide/presentation/pages/writing/proofread_page.dart';
import 'package:novel_ide/presentation/pages/outline/outline_page.dart';
import 'package:novel_ide/presentation/pages/ai/full_text_review_page.dart';
import 'package:novel_ide/presentation/pages/tomato/agent_marketplace_page.dart';
import 'package:novel_ide/presentation/pages/works/export_page.dart';
import 'package:novel_ide/presentation/pages/materials/materials_tree_page.dart';
import 'package:novel_ide/presentation/pages/stats/stats_page.dart';
import 'package:novel_ide/presentation/pages/profile/profile_page.dart';
import 'package:novel_ide/data/models/memory/memory_entity.dart';
import 'package:novel_ide/presentation/pages/memory/memory_graph_page.dart';
import 'package:novel_ide/presentation/pages/memory/memory_list_page.dart';
import 'package:novel_ide/presentation/pages/memory/memory_edit_page.dart';
import 'package:novel_ide/presentation/pages/settings/operit_theme_page.dart';
import 'package:novel_ide/presentation/pages/settings/operit_user_prefs_page.dart';
import 'package:novel_ide/presentation/pages/settings/operit_language_page.dart';
import 'package:novel_ide/presentation/pages/settings/operit_model_config_page.dart';
import 'package:novel_ide/presentation/pages/settings/operit_functional_config_page.dart';
import 'package:novel_ide/presentation/pages/settings/operit_speech_page.dart';
import 'package:novel_ide/presentation/pages/settings/operit_prompts_page.dart';
import 'package:novel_ide/presentation/pages/settings/operit_waifu_page.dart';
import 'package:novel_ide/presentation/pages/settings/operit_tool_perm_page.dart';
import 'package:novel_ide/presentation/pages/settings/operit_backup_page.dart';
import 'package:novel_ide/presentation/pages/settings/operit_context_summary_page.dart';

class AppRouter {
  static const String home = '/';
  static const String editor = '/editor';
  static const String richEditor = '/rich-editor';
  static const String agents = '/agents';
  static const String globalSearch = '/global-search';
  static const String outline = '/outline';
  static const String proofread = '/proofread';
  static const String fullTextReview = '/full-text-review';
  static const String export = '/export';
  static const String materials = '/materials';
  static const String stats = '/stats';
  static const String profile = '/profile';
  static const String memoryGraph = '/memory-graph';
  static const String memoryList = '/memory-list';
  static const String memoryEdit = '/memory-edit';
  static const String theme = '/settings/theme';
  static const String userPrefs = '/settings/user-prefs';
  static const String language = '/settings/language';
  static const String modelConfig = '/settings/model-config';
  static const String functionalConfig = '/settings/functional-config';
  static const String speech = '/settings/speech';
  static const String prompts = '/settings/prompts';
  static const String waifu = '/settings/waifu';
  static const String toolPerm = '/settings/tool-perm';
  static const String backup = '/settings/backup';
  static const String contextSummary = '/settings/context-summary';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case home:
        return MaterialPageRoute(builder: (_) => const MainShellV2());
      case editor:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => EditorPage(
            novelId: args?['novelId'] ?? '',
            chapterId: args?['chapterId'] ?? '',
          ),
        );
      case richEditor:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => RichEditorPage(
            novelId: args?['novelId'] ?? '',
            chapterId: args?['chapterId'] ?? '',
            initialTitle: args?['title'] ?? '',
            initialContent: args?['content'] ?? '',
          ),
        );
      case agents:
        return MaterialPageRoute(builder: (_) => const AgentMarketplacePage());
      case globalSearch:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => GlobalSearchPage(
            novelId: args?['novelId'] ?? '',
            novelTitle: args?['novelTitle'] ?? '',
          ),
        );
      case outline:
        return MaterialPageRoute(builder: (_) => const OutlinePage());
      case proofread:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => ProofreadPage(novelId: args?['novelId'] ?? ''),
        );
      case fullTextReview:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => FullTextReviewPage(
            novelId: args?['novelId'] ?? '',
            novelTitle: args?['novelTitle'] ?? '',
          ),
        );
      case export:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => ExportPage(
            novelId: args?['novelId'] ?? '',
            novelTitle: args?['novelTitle'] ?? '',
          ),
        );
      case materials:
        return MaterialPageRoute(builder: (_) => const MaterialsTreePage());
      case stats:
        return MaterialPageRoute(builder: (_) => const StatsPage());
      case profile:
        return MaterialPageRoute(builder: (_) => const ProfilePage());
      case memoryGraph:
        return MaterialPageRoute(builder: (_) => const MemoryGraphPage());
      case memoryList:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => MemoryListPage(
            novelId: args?['novelId'] as String?,
          ),
        );
      case memoryEdit:
        final args = settings.arguments as Map<String, dynamic>?;
        final memory = args?['memory'] as Memory?;
        return MaterialPageRoute(
          builder: (_) => MemoryEditPage(
            memory: memory,
            novelId: args?['novelId'] as String?,
          ),
        );
      case theme:
        return MaterialPageRoute(builder: (_) => const OperitThemePage());
      case userPrefs:
        return MaterialPageRoute(builder: (_) => const OperitUserPrefsPage());
      case language:
        return MaterialPageRoute(builder: (_) => const OperitLanguagePage());
      case modelConfig:
        return MaterialPageRoute(builder: (_) => const OperitModelConfigPage());
      case functionalConfig:
        return MaterialPageRoute(
          builder: (_) => const OperitFunctionalConfigPage(),
        );
      case speech:
        return MaterialPageRoute(builder: (_) => const OperitSpeechPage());
      case prompts:
        return MaterialPageRoute(builder: (_) => const OperitPromptsPage());
      case waifu:
        return MaterialPageRoute(builder: (_) => const OperitWaifuPage());
      case toolPerm:
        return MaterialPageRoute(builder: (_) => const OperitToolPermPage());
      case backup:
        return MaterialPageRoute(builder: (_) => const OperitBackupPage());
      case contextSummary:
        return MaterialPageRoute(
          builder: (_) => const OperitContextSummaryPage(),
        );
      default:
        return MaterialPageRoute(builder: (_) => const MainShellV2());
    }
  }
}
