import 'dart:typed_data';
import 'dart:math';

/// 嵌入向量包装类
///
/// 用于存储文本内容的向量嵌入（embedding），
/// 支持余弦相似度计算，用于语义搜索。
class Embedding {
  /// 向量数据
  final Float64List vector;

  const Embedding(this.vector);

  /// 从 JSON 数组创建 Embedding
  factory Embedding.fromJson(List<dynamic> json) {
    final data = Float64List.fromList(
      json.map((e) => (e as num).toDouble()).toList(),
    );
    return Embedding(data);
  }

  /// 序列化为 JSON 数组
  List<double> toJson() => vector.toList();

  /// 计算两个嵌入向量之间的余弦相似度
  ///
  /// 返回值范围 [-1.0, 1.0]，越接近 1.0 表示越相似。
  /// 当向量为空或维度不匹配时返回 0.0。
  static double cosineSimilarity(Embedding left, Embedding right) {
    final leftVector = left.vector;
    final rightVector = right.vector;

    if (leftVector.isEmpty ||
        rightVector.isEmpty ||
        leftVector.length != rightVector.length) {
      return 0.0;
    }

    double dot = 0.0;
    double leftNorm = 0.0;
    double rightNorm = 0.0;

    for (int i = 0; i < leftVector.length; i++) {
      final lv = leftVector[i];
      final rv = rightVector[i];
      dot += lv * rv;
      leftNorm += lv * lv;
      rightNorm += rv * rv;
    }

    if (leftNorm <= 0.0 || rightNorm <= 0.0) {
      return 0.0;
    }

    return dot / (sqrt(leftNorm) * sqrt(rightNorm));
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Embedding) return false;
    if (vector.length != other.vector.length) return false;
    for (int i = 0; i < vector.length; i++) {
      if (vector[i] != other.vector[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll(vector);
}
