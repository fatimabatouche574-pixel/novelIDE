import 'package:flutter_test/flutter_test.dart';
import 'package:novel_ide/data/models/memory/embedding.dart';
import 'dart:typed_data';

void main() {
  group('Embedding', () {
    group('constructor', () {
      test('creates embedding with given vector', () {
        // Arrange & Act
        final embedding = Embedding(
          Float64List.fromList([1.0, 2.0, 3.0]),
        );

        // Assert
        expect(embedding.vector, [1.0, 2.0, 3.0]);
        expect(embedding.vector.length, 3);
      });

      test('creates embedding with empty vector', () {
        // Arrange & Act
        final embedding = Embedding(Float64List(0));

        // Assert
        expect(embedding.vector, isEmpty);
      });
    });

    group('fromJson', () {
      test('parses JSON list of doubles', () {
        // Arrange
        final json = [1.0, 2.0, 3.0];

        // Act
        final embedding = Embedding.fromJson(json);

        // Assert
        expect(embedding.vector.length, 3);
        expect(embedding.vector[0], 1.0);
        expect(embedding.vector[1], 2.0);
        expect(embedding.vector[2], 3.0);
      });

      test('parses JSON list of ints as doubles', () {
        // Arrange
        final json = [1, 2, 3];

        // Act
        final embedding = Embedding.fromJson(json);

        // Assert
        expect(embedding.vector.length, 3);
        expect(embedding.vector[0], 1.0);
        expect(embedding.vector[1], 2.0);
        expect(embedding.vector[2], 3.0);
      });

      test('parses empty JSON list', () {
        // Arrange
        final json = <dynamic>[];

        // Act
        final embedding = Embedding.fromJson(json);

        // Assert
        expect(embedding.vector, isEmpty);
      });

      test('parses mixed int and num JSON list', () {
        // Arrange
        final json = [1, 2.5, 3];

        // Act
        final embedding = Embedding.fromJson(json);

        // Assert
        expect(embedding.vector[0], 1.0);
        expect(embedding.vector[1], 2.5);
        expect(embedding.vector[2], 3.0);
      });
    });

    group('toJson', () {
      test('returns list of doubles', () {
        // Arrange
        final embedding = Embedding(
          Float64List.fromList([1.5, 2.5, 3.5]),
        );

        // Act
        final json = embedding.toJson();

        // Assert
        expect(json, [1.5, 2.5, 3.5]);
        expect(json, isA<List<double>>());
      });

      test('returns empty list for empty vector', () {
        // Arrange
        final embedding = Embedding(Float64List(0));

        // Act
        final json = embedding.toJson();

        // Assert
        expect(json, isEmpty);
      });
    });

    group('fromJson/toJson round-trip', () {
      test('preserves data through serialization', () {
        // Arrange
        final original = Embedding(
          Float64List.fromList([0.1, 0.2, 0.3, 0.4, 0.5]),
        );

        // Act
        final json = original.toJson();
        final restored = Embedding.fromJson(json);

        // Assert
        expect(restored, original);
      });

      test('preserves empty embedding through serialization', () {
        // Arrange
        final original = Embedding(Float64List(0));

        // Act
        final json = original.toJson();
        final restored = Embedding.fromJson(json);

        // Assert
        expect(restored.vector, isEmpty);
      });

      test('preserves negative values through serialization', () {
        // Arrange
        final original = Embedding(
          Float64List.fromList([-1.0, 0.0, 1.0, -0.5]),
        );

        // Act
        final json = original.toJson();
        final restored = Embedding.fromJson(json);

        // Assert
        expect(restored, original);
      });
    });

    group('operator ==', () {
      test('equal embeddings are equal', () {
        // Arrange
        final a = Embedding(Float64List.fromList([1.0, 2.0, 3.0]));
        final b = Embedding(Float64List.fromList([1.0, 2.0, 3.0]));

        // Act & Assert
        expect(a, equals(b));
        expect(a.hashCode, equals(b.hashCode));
      });

      test('different values are not equal', () {
        // Arrange
        final a = Embedding(Float64List.fromList([1.0, 2.0, 3.0]));
        final b = Embedding(Float64List.fromList([1.0, 2.0, 4.0]));

        // Act & Assert
        expect(a, isNot(equals(b)));
      });

      test('different lengths are not equal', () {
        // Arrange
        final a = Embedding(Float64List.fromList([1.0, 2.0]));
        final b = Embedding(Float64List.fromList([1.0, 2.0, 3.0]));

        // Act & Assert
        expect(a, isNot(equals(b)));
      });

      test('identical instance is equal to itself', () {
        // Arrange
        final a = Embedding(Float64List.fromList([1.0, 2.0]));

        // Act & Assert
        expect(a, equals(a));
      });

      test('empty embeddings are equal', () {
        // Arrange
        final a = Embedding(Float64List(0));
        final b = Embedding(Float64List(0));

        // Act & Assert
        expect(a, equals(b));
      });
    });

    group('cosineSimilarity', () {
      test('returns 1.0 for identical vectors', () {
        // Arrange
        final a = Embedding(Float64List.fromList([1.0, 0.0, 0.0]));
        final b = Embedding(Float64List.fromList([1.0, 0.0, 0.0]));

        // Act
        final result = Embedding.cosineSimilarity(a, b);

        // Assert
        expect(result, closeTo(1.0, 1e-10));
      });

      test('returns 0.0 for orthogonal vectors', () {
        // Arrange
        final a = Embedding(Float64List.fromList([1.0, 0.0]));
        final b = Embedding(Float64List.fromList([0.0, 1.0]));

        // Act
        final result = Embedding.cosineSimilarity(a, b);

        // Assert
        expect(result, closeTo(0.0, 1e-10));
      });

      test('returns -1.0 for opposite vectors', () {
        // Arrange
        final a = Embedding(Float64List.fromList([1.0, 0.0]));
        final b = Embedding(Float64List.fromList([-1.0, 0.0]));

        // Act
        final result = Embedding.cosineSimilarity(a, b);

        // Assert
        expect(result, closeTo(-1.0, 1e-10));
      });

      test('returns close to 1.0 for similar vectors', () {
        // Arrange
        final a = Embedding(Float64List.fromList([1.0, 1.0, 0.0]));
        final b = Embedding(Float64List.fromList([1.0, 0.9, 0.1]));

        // Act
        final result = Embedding.cosineSimilarity(a, b);

        // Assert
        expect(result, greaterThan(0.9));
        expect(result, lessThanOrEqualTo(1.0));
      });

      test('returns 0.0 when left vector is empty', () {
        // Arrange
        final a = Embedding(Float64List(0));
        final b = Embedding(Float64List.fromList([1.0, 2.0]));

        // Act
        final result = Embedding.cosineSimilarity(a, b);

        // Assert
        expect(result, 0.0);
      });

      test('returns 0.0 when right vector is empty', () {
        // Arrange
        final a = Embedding(Float64List.fromList([1.0, 2.0]));
        final b = Embedding(Float64List(0));

        // Act
        final result = Embedding.cosineSimilarity(a, b);

        // Assert
        expect(result, 0.0);
      });

      test('returns 0.0 when both vectors are empty', () {
        // Arrange
        final a = Embedding(Float64List(0));
        final b = Embedding(Float64List(0));

        // Act
        final result = Embedding.cosineSimilarity(a, b);

        // Assert
        expect(result, 0.0);
      });

      test('returns 0.0 when dimensions mismatch', () {
        // Arrange
        final a = Embedding(Float64List.fromList([1.0, 2.0]));
        final b = Embedding(Float64List.fromList([1.0, 2.0, 3.0]));

        // Act
        final result = Embedding.cosineSimilarity(a, b);

        // Assert
        expect(result, 0.0);
      });

      test('returns 0.0 when one vector is all zeros', () {
        // Arrange
        final a = Embedding(Float64List.fromList([0.0, 0.0, 0.0]));
        final b = Embedding(Float64List.fromList([1.0, 2.0, 3.0]));

        // Act
        final result = Embedding.cosineSimilarity(a, b);

        // Assert
        expect(result, 0.0);
      });

      test('works with high-dimensional vectors', () {
        // Arrange — two unit vectors in 100 dimensions
        final vector = Float64List(100);
        for (var i = 0; i < 100; i++) {
          vector[i] = 1.0;
        }
        final a = Embedding(vector);
        final b = Embedding(Float64List.fromList(vector.toList()));

        // Act
        final result = Embedding.cosineSimilarity(a, b);

        // Assert
        expect(result, closeTo(1.0, 1e-10));
      });

      test('symmetric: sim(a,b) == sim(b,a)', () {
        // Arrange
        final a = Embedding(Float64List.fromList([3.0, 4.0, 5.0]));
        final b = Embedding(Float64List.fromList([1.0, 2.0, 3.0]));

        // Act
        final ab = Embedding.cosineSimilarity(a, b);
        final ba = Embedding.cosineSimilarity(b, a);

        // Assert
        expect(ab, closeTo(ba, 1e-10));
      });

      test('correct value for known 3-4-5 triangle', () {
        // Arrange — vectors [3,4] and [4,3]
        // dot=24, |a|=5, |b|=5, cos=24/25=0.96
        final a = Embedding(Float64List.fromList([3.0, 4.0]));
        final b = Embedding(Float64List.fromList([4.0, 3.0]));

        // Act
        final result = Embedding.cosineSimilarity(a, b);

        // Assert
        expect(result, closeTo(0.96, 1e-10));
      });
    });
  });
}
