import 'package:flutter_test/flutter_test.dart';
import 'package:novel_ide/data/models/writing_skill_model.dart';
import 'package:novel_ide/data/services/skill_matcher.dart';

WritingSkill _skill(String id, List<String> keywords) {
  return WritingSkill(
    id: id,
    name: id,
    category: '测试',
    description: '',
    content: id,
    keywords: keywords,
  );
}

void main() {
  test('优先选择命中更多且关键词更具体的技能', () {
    final generic = _skill('generic', ['开篇']);
    final specific = _skill('specific', ['开篇', '黄金三章']);

    final result = SkillMatcher.match(
      '请按黄金三章的方法重写这个开篇',
      [generic, specific],
    );

    expect(result.map((skill) => skill.id).toList(), ['specific', 'generic']);
  });

  test('最多注入三个技能', () {
    final skills = List.generate(
      5,
      (index) => _skill('skill_$index', ['共同关键词']),
    );

    final result = SkillMatcher.match('共同关键词', skills);

    expect(result, hasLength(SkillMatcher.maxMatchCount));
  });
}
