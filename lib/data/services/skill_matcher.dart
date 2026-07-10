import 'package:novel_ide/data/models/writing_skill_model.dart';

/// Skill匹配引擎
/// 根据用户输入文本，自动匹配相关的Skill
class SkillMatcher {
  /// 最大同时匹配的Skill数量
  static const int maxMatchCount = 3;

  /// 匹配用户消息中的关键词，返回命中的技能列表
  static List<WritingSkill> match(
    String userMessage,
    List<WritingSkill> enabledSkills,
  ) {
    if (userMessage.trim().isEmpty || enabledSkills.isEmpty) return [];

    final normalizedMessage = userMessage.toLowerCase();
    final scored = <({int index, int score, WritingSkill skill})>[];
    for (var index = 0; index < enabledSkills.length; index++) {
      final skill = enabledSkills[index];
      if (skill.keywords.isEmpty) continue;
      var score = 0;
      for (final keyword in skill.keywords) {
        final normalizedKeyword = keyword.trim().toLowerCase();
        if (normalizedKeyword.isNotEmpty &&
            normalizedMessage.contains(normalizedKeyword)) {
          // 命中越多、关键词越具体，优先级越高。
          score += 10 + normalizedKeyword.length;
        }
      }
      if (score > 0) scored.add((index: index, score: score, skill: skill));
    }

    scored.sort((a, b) {
      final byScore = b.score.compareTo(a.score);
      return byScore != 0 ? byScore : a.index.compareTo(b.index);
    });
    return scored.take(maxMatchCount).map((entry) => entry.skill).toList();
  }

  /// 将匹配到的技能内容注入系统提示词
  static String injectSkillContext(
    String systemPrompt,
    List<WritingSkill> matchedSkills,
  ) {
    if (matchedSkills.isEmpty) return systemPrompt;

    final buffer = StringBuffer();
    buffer.writeln(systemPrompt);
    buffer.writeln('\n【已启动Skill参考】');
    for (final skill in matchedSkills) {
      buffer.writeln('\n## ${skill.name}（${skill.category}）');
      buffer.writeln(skill.content);
    }
    return buffer.toString();
  }
}
