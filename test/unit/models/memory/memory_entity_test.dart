import 'package:flutter_test/flutter_test.dart';
import 'package:novel_ide/data/models/memory/memory_entity.dart';
import 'package:novel_ide/data/models/memory/memory_search_config.dart';
import 'package:novel_ide/data/models/memory/embedding.dart';
import 'dart:typed_data';

void main() {
  // ───────────────────────────────────────────
  // MemoryLink
  // ───────────────────────────────────────────
  group('MemoryLink', () {
    group('constructor defaults', () {
      test('sets correct defaults', () {
        // Arrange & Act
        final link = MemoryLink(sourceId: 1, targetId: 2);

        // Assert
        expect(link.id, 0);
        expect(link.sourceId, 1);
        expect(link.targetId, 2);
        expect(link.type, 'related');
        expect(link.weight, 1.0);
        expect(link.description, '');
      });
    });

    group('copyWith', () {
      test('copies with no changes returns equal object', () {
        // Arrange
        final link = MemoryLink(
          id: 10,
          sourceId: 1,
          targetId: 2,
          type: 'causes',
          weight: 0.8,
          description: 'test',
        );

        // Act
        final copy = link.copyWith();

        // Assert
        expect(copy.id, link.id);
        expect(copy.sourceId, link.sourceId);
        expect(copy.targetId, link.targetId);
        expect(copy.type, link.type);
        expect(copy.weight, link.weight);
        expect(copy.description, link.description);
      });

      test('overrides specified fields', () {
        // Arrange
        final link = MemoryLink(sourceId: 1, targetId: 2);

        // Act
        final copy = link.copyWith(
          type: 'explains',
          weight: 0.5,
          description: 'overridden',
        );

        // Assert
        expect(copy.type, 'explains');
        expect(copy.weight, 0.5);
        expect(copy.description, 'overridden');
        expect(copy.sourceId, 1); // unchanged
        expect(copy.targetId, 2); // unchanged
      });
    });

    group('fromJson', () {
      test('parses complete JSON', () {
        // Arrange
        final json = {
          'id': 5,
          'source_id': 10,
          'target_id': 20,
          'type': 'causes',
          'weight': 0.75,
          'description': 'some description',
        };

        // Act
        final link = MemoryLink.fromJson(json);

        // Assert
        expect(link.id, 5);
        expect(link.sourceId, 10);
        expect(link.targetId, 20);
        expect(link.type, 'causes');
        expect(link.weight, 0.75);
        expect(link.description, 'some description');
      });

      test('applies defaults for missing optional fields', () {
        // Arrange
        final json = {
          'source_id': 1,
          'target_id': 2,
        };

        // Act
        final link = MemoryLink.fromJson(json);

        // Assert
        expect(link.id, 0);
        expect(link.type, 'related');
        expect(link.weight, 1.0);
        expect(link.description, '');
      });
    });

    group('toJson', () {
      test('serializes all fields', () {
        // Arrange
        final link = MemoryLink(
          id: 3,
          sourceId: 1,
          targetId: 2,
          type: 'part_of',
          weight: 0.6,
          description: 'desc',
        );

        // Act
        final json = link.toJson();

        // Assert
        expect(json['id'], 3);
        expect(json['source_id'], 1);
        expect(json['target_id'], 2);
        expect(json['type'], 'part_of');
        expect(json['weight'], 0.6);
        expect(json['description'], 'desc');
      });
    });

    group('fromJson/toJson round-trip', () {
      test('preserves all fields through serialization', () {
        // Arrange
        final original = MemoryLink(
          id: 42,
          sourceId: 100,
          targetId: 200,
          type: 'explains',
          weight: 0.95,
          description: 'round trip test',
        );

        // Act
        final json = original.toJson();
        final restored = MemoryLink.fromJson(json);

        // Assert
        expect(restored.id, original.id);
        expect(restored.sourceId, original.sourceId);
        expect(restored.targetId, original.targetId);
        expect(restored.type, original.type);
        expect(restored.weight, original.weight);
        expect(restored.description, original.description);
      });
    });

    group('operator ==', () {
      test('same id links are equal', () {
        // Arrange
        final a = MemoryLink(id: 1, sourceId: 1, targetId: 2);
        final b = MemoryLink(id: 1, sourceId: 3, targetId: 4);

        // Act & Assert
        expect(a, equals(b));
      });

      test('different id links are not equal', () {
        // Arrange
        final a = MemoryLink(id: 1, sourceId: 1, targetId: 2);
        final b = MemoryLink(id: 2, sourceId: 1, targetId: 2);

        // Act & Assert
        expect(a, isNot(equals(b)));
      });
    });
  });

  // ───────────────────────────────────────────
  // MemoryTag
  // ───────────────────────────────────────────
  group('MemoryTag', () {
    group('fromJson/toJson round-trip', () {
      test('preserves all fields', () {
        // Arrange
        final tag = MemoryTag(id: 7, name: 'test_tag', parentId: 3, memoryIds: [1, 2]);

        // Act
        final json = tag.toJson();
        final restored = MemoryTag.fromJson(json);

        // Assert
        expect(restored.id, tag.id);
        expect(restored.name, tag.name);
        expect(restored.parentId, tag.parentId);
        expect(restored.memoryIds, tag.memoryIds);
      });
    });

    group('fromJson defaults', () {
      test('applies defaults for missing optional fields', () {
        // Arrange & Act
        final tag = MemoryTag.fromJson({});

        // Assert
        expect(tag.id, 0);
        expect(tag.name, '');
        expect(tag.parentId, isNull);
        expect(tag.memoryIds, isEmpty);
      });
    });
  });

  // ───────────────────────────────────────────
  // MemoryProperty
  // ───────────────────────────────────────────
  group('MemoryProperty', () {
    group('fromJson/toJson round-trip', () {
      test('preserves all fields', () {
        // Arrange
        final prop = MemoryProperty(id: 5, key: 'color', value: 'red');

        // Act
        final json = prop.toJson();
        final restored = MemoryProperty.fromJson(json);

        // Assert
        expect(restored.id, prop.id);
        expect(restored.key, prop.key);
        expect(restored.value, prop.value);
      });
    });
  });

  // ───────────────────────────────────────────
  // Memory
  // ───────────────────────────────────────────
  group('Memory', () {
    group('constructor defaults', () {
      test('sets expected defaults', () {
        // Arrange & Act
        final memory = Memory(uuid: 'test-uuid');

        // Assert
        expect(memory.id, 0);
        expect(memory.uuid, 'test-uuid');
        expect(memory.novelId, '');
        expect(memory.title, '');
        expect(memory.content, '');
        expect(memory.contentType, 'text/plain');
        expect(memory.source, 'unknown');
        expect(memory.credibility, 0.5);
        expect(memory.importance, 0.5);
        expect(memory.documentPath, isNull);
        expect(memory.isDocumentNode, false);
        expect(memory.chunkIndexFilePath, isNull);
        expect(memory.folderPath, isNull);
        expect(memory.embedding, isNull);
        expect(memory.tags, isEmpty);
        expect(memory.properties, isEmpty);
        expect(memory.links, isEmpty);
        expect(memory.backlinks, isEmpty);
        expect(memory.createdAt, isNotNull);
        expect(memory.updatedAt, isNotNull);
        expect(memory.lastAccessedAt, isNotNull);
      });
    });

    group('copyWith', () {
      test('copies with no changes returns equal object', () {
        // Arrange
        final now = DateTime(2025, 1, 15, 10, 30);
        final memory = Memory(
          uuid: 'uuid-1',
          title: 'Test Title',
          content: 'content',
          createdAt: now,
          updatedAt: now,
          lastAccessedAt: now,
        );

        // Act
        final copy = memory.copyWith();

        // Assert
        expect(copy.uuid, memory.uuid);
        expect(copy.title, memory.title);
        expect(copy.content, memory.content);
        expect(copy.createdAt, memory.createdAt);
      });

      test('overrides specified fields, preserves others', () {
        // Arrange
        final now = DateTime(2025, 1, 15);
        final memory = Memory(
          uuid: 'uuid-1',
          title: 'Original',
          content: 'original content',
          createdAt: now,
          updatedAt: now,
          lastAccessedAt: now,
        );

        // Act
        final copy = memory.copyWith(
          title: 'Updated Title',
          importance: 0.9,
        );

        // Assert
        expect(copy.title, 'Updated Title');
        expect(copy.importance, 0.9);
        expect(copy.uuid, 'uuid-1'); // unchanged
        expect(copy.content, 'original content'); // unchanged
      });
    });

    group('fromJson', () {
      test('parses complete JSON with all fields', () {
        // Arrange
        final json = {
          'id': 10,
          'uuid': 'test-uuid-123',
          'novel_id': 'novel-1',
          'title': 'Test Title',
          'content': 'Test content here',
          'content_type': 'application/json',
          'source': 'chat_summary',
          'credibility': 0.8,
          'importance': 0.9,
          'document_path': '/docs/test.txt',
          'is_document_node': true,
          'chunk_index_file_path': '/chunks/index.json',
          'folder_path': 'characters/protagonist',
          'embedding': [0.1, 0.2, 0.3],
          'tags': [
            {'id': 1, 'name': 'tag1'},
            {'id': 2, 'name': 'tag2'},
          ],
          'properties': [
            {'id': 1, 'key': 'mood', 'value': 'happy'},
          ],
          'links': [
            {'source_id': 10, 'target_id': 20, 'type': 'causes'},
          ],
          'backlinks': [
            {'source_id': 30, 'target_id': 10},
          ],
          'created_at': '2025-06-15T10:30:00.000',
          'updated_at': '2025-06-15T11:00:00.000',
          'last_accessed_at': '2025-06-15T12:00:00.000',
        };

        // Act
        final memory = Memory.fromJson(json);

        // Assert
        expect(memory.id, 10);
        expect(memory.uuid, 'test-uuid-123');
        expect(memory.novelId, 'novel-1');
        expect(memory.title, 'Test Title');
        expect(memory.content, 'Test content here');
        expect(memory.contentType, 'application/json');
        expect(memory.source, 'chat_summary');
        expect(memory.credibility, 0.8);
        expect(memory.importance, 0.9);
        expect(memory.documentPath, '/docs/test.txt');
        expect(memory.isDocumentNode, true);
        expect(memory.chunkIndexFilePath, '/chunks/index.json');
        expect(memory.folderPath, 'characters/protagonist');
        expect(memory.embedding, isNotNull);
        expect(memory.embedding!.vector.length, 3);
        expect(memory.tags.length, 2);
        expect(memory.tags[0].name, 'tag1');
        expect(memory.properties.length, 1);
        expect(memory.properties[0].key, 'mood');
        expect(memory.links.length, 1);
        expect(memory.links[0].type, 'causes');
        expect(memory.backlinks.length, 1);
        expect(memory.createdAt, DateTime(2025, 6, 15, 10, 30));
        expect(memory.updatedAt, DateTime(2025, 6, 15, 11));
        expect(memory.lastAccessedAt, DateTime(2025, 6, 15, 12));
      });

      test('applies defaults for missing optional fields', () {
        // Arrange
        final json = {
          'uuid': 'minimal-uuid',
        };

        // Act
        final memory = Memory.fromJson(json);

        // Assert
        expect(memory.id, 0);
        expect(memory.uuid, 'minimal-uuid');
        expect(memory.novelId, '');
        expect(memory.title, '');
        expect(memory.content, '');
        expect(memory.contentType, 'text/plain');
        expect(memory.source, 'unknown');
        expect(memory.credibility, 0.5);
        expect(memory.importance, 0.5);
        expect(memory.documentPath, isNull);
        expect(memory.isDocumentNode, false);
        expect(memory.embedding, isNull);
        expect(memory.tags, isEmpty);
        expect(memory.properties, isEmpty);
        expect(memory.links, isEmpty);
        expect(memory.backlinks, isEmpty);
        expect(memory.createdAt, isNotNull);
      });

      test('parses integer credibility and importance', () {
        // Arrange — JSON numbers can arrive as int from SQLite
        final json = {
          'uuid': 'int-nums',
          'credibility': 1,
          'importance': 0,
        };

        // Act
        final memory = Memory.fromJson(json);

        // Assert
        expect(memory.credibility, 1.0);
        expect(memory.importance, 0.0);
      });
    });

    group('toJson', () {
      test('serializes all fields', () {
        // Arrange
        final now = DateTime(2025, 6, 15, 10, 30);
        final memory = Memory(
          id: 5,
          uuid: 'uuid-5',
          novelId: 'novel-1',
          title: 'Title',
          content: 'Content',
          contentType: 'text/plain',
          source: 'user_input',
          credibility: 0.7,
          importance: 0.8,
          documentPath: '/path',
          isDocumentNode: true,
          folderPath: 'folder',
          createdAt: now,
          updatedAt: now,
          lastAccessedAt: now,
        );

        // Act
        final json = memory.toJson();

        // Assert
        expect(json['id'], 5);
        expect(json['uuid'], 'uuid-5');
        expect(json['novel_id'], 'novel-1');
        expect(json['title'], 'Title');
        expect(json['content'], 'Content');
        expect(json['content_type'], 'text/plain');
        expect(json['source'], 'user_input');
        expect(json['credibility'], 0.7);
        expect(json['importance'], 0.8);
        expect(json['document_path'], '/path');
        expect(json['is_document_node'], true);
        expect(json['folder_path'], 'folder');
        expect(json['created_at'], now.toIso8601String());
        expect(json['updated_at'], now.toIso8601String());
        expect(json['last_accessed_at'], now.toIso8601String());
      });

      test('serializes null fields as null', () {
        // Arrange
        final memory = Memory(uuid: 'null-fields');

        // Act
        final json = memory.toJson();

        // Assert
        expect(json['document_path'], isNull);
        expect(json['chunk_index_file_path'], isNull);
        expect(json['folder_path'], isNull);
        expect(json['embedding'], isNull);
      });

      test('serializes embedding as list of doubles', () {
        // Arrange
        final memory = Memory(
          uuid: 'with-embedding',
          embedding: Embedding(Float64List.fromList([0.1, 0.2, 0.3])),
        );

        // Act
        final json = memory.toJson();

        // Assert
        expect(json['embedding'], isA<List>());
        expect((json['embedding'] as List).length, 3);
      });

      test('serializes nested lists', () {
        // Arrange
        final memory = Memory(
          uuid: 'with-nested',
          tags: [const MemoryTag(id: 1, name: 't')],
          properties: [const MemoryProperty(id: 2, key: 'k', value: 'v')],
          links: [const MemoryLink(sourceId: 1, targetId: 2)],
        );

        // Act
        final json = memory.toJson();

        // Assert
        expect(json['tags'], isA<List>());
        expect((json['tags'] as List).length, 1);
        expect(json['properties'], isA<List>());
        expect((json['properties'] as List).length, 1);
        expect(json['links'], isA<List>());
        expect((json['links'] as List).length, 1);
      });
    });

    group('fromJson/toJson round-trip', () {
      test('preserves all fields through full serialization', () {
        // Arrange
        final now = DateTime(2025, 6, 15, 10, 30, 0, 0);
        final original = Memory(
          id: 42,
          uuid: 'round-trip-uuid',
          novelId: 'novel-xyz',
          title: 'Round Trip Title',
          content: 'Some content with unicode: 中文',
          contentType: 'application/json',
          source: 'auto_generated',
          credibility: 0.85,
          importance: 0.65,
          documentPath: '/docs/rt.txt',
          isDocumentNode: false,
          chunkIndexFilePath: '/chunks/rt.json',
          folderPath: 'folder/sub',
          embedding: Embedding(
            Float64List.fromList([0.1, 0.2, 0.3, 0.4]),
          ),
          tags: [
            const MemoryTag(id: 1, name: 'round', parentId: null, memoryIds: [42]),
          ],
          properties: [
            const MemoryProperty(id: 1, key: 'test', value: 'value'),
          ],
          links: [
            const MemoryLink(id: 10, sourceId: 42, targetId: 99, type: 'related', weight: 0.5),
          ],
          backlinks: [],
          createdAt: now,
          updatedAt: now,
          lastAccessedAt: now,
        );

        // Act
        final json = original.toJson();
        final restored = Memory.fromJson(json);

        // Assert
        expect(restored.id, original.id);
        expect(restored.uuid, original.uuid);
        expect(restored.novelId, original.novelId);
        expect(restored.title, original.title);
        expect(restored.content, original.content);
        expect(restored.contentType, original.contentType);
        expect(restored.source, original.source);
        expect(restored.credibility, original.credibility);
        expect(restored.importance, original.importance);
        expect(restored.documentPath, original.documentPath);
        expect(restored.isDocumentNode, original.isDocumentNode);
        expect(restored.chunkIndexFilePath, original.chunkIndexFilePath);
        expect(restored.folderPath, original.folderPath);
        expect(restored.embedding, original.embedding);
        expect(restored.tags.length, original.tags.length);
        expect(restored.tags[0].name, 'round');
        expect(restored.properties.length, 1);
        expect(restored.properties[0].key, 'test');
        expect(restored.links.length, 1);
        expect(restored.links[0].type, 'related');
        expect(restored.backlinks, isEmpty);
        expect(restored.createdAt, original.createdAt);
        expect(restored.updatedAt, original.updatedAt);
        expect(restored.lastAccessedAt, original.lastAccessedAt);
      });

      test('round-trip with minimal required fields only', () {
        // Arrange
        final original = Memory(uuid: 'minimal-round-trip');

        // Act
        final json = original.toJson();
        final restored = Memory.fromJson(json);

        // Assert
        expect(restored.uuid, original.uuid);
        expect(restored.novelId, '');
        expect(restored.title, '');
        expect(restored.embedding, isNull);
        expect(restored.tags, isEmpty);
      });
    });

    group('operator ==', () {
      test('memories with same uuid are equal', () {
        // Arrange
        final a = Memory(uuid: 'same-uuid', title: 'Title A');
        final b = Memory(uuid: 'same-uuid', title: 'Title B');

        // Act & Assert
        expect(a, equals(b));
        expect(a.hashCode, equals(b.hashCode));
      });

      test('memories with different uuid are not equal', () {
        // Arrange
        final a = Memory(uuid: 'uuid-a');
        final b = Memory(uuid: 'uuid-b');

        // Act & Assert
        expect(a, isNot(equals(b)));
      });
    });

    group('edge cases', () {
      test('fromJson handles very large credibility/importance values', () {
        // Arrange
        final json = {
          'uuid': 'edge',
          'credibility': 999.9,
          'importance': -1.0,
        };

        // Act
        final memory = Memory.fromJson(json);

        // Assert — no clamping in fromJson, values pass through
        expect(memory.credibility, 999.9);
        expect(memory.importance, -1.0);
      });

      test('fromJson handles empty tags/properties/links arrays', () {
        // Arrange
        final json = {
          'uuid': 'empty-arrays',
          'tags': <dynamic>[],
          'properties': <dynamic>[],
          'links': <dynamic>[],
          'backlinks': <dynamic>[],
        };

        // Act
        final memory = Memory.fromJson(json);

        // Assert
        expect(memory.tags, isEmpty);
        expect(memory.properties, isEmpty);
        expect(memory.links, isEmpty);
        expect(memory.backlinks, isEmpty);
      });
    });
  });

  // ───────────────────────────────────────────
  // MemorySearchConfig
  // ───────────────────────────────────────────
  group('MemorySearchConfig', () {
    group('constructor defaults', () {
      test('sets expected defaults', () {
        // Arrange & Act
        const config = MemorySearchConfig();

        // Assert
        expect(config.scoreMode, MemoryScoreMode.balanced);
        expect(config.keywordWeight, 10.0);
        expect(config.tagWeight, 0.0);
        expect(config.vectorWeight, 0.0);
        expect(config.edgeWeight, 0.4);
      });
    });

    group('copyWith', () {
      test('copies with no changes returns equal config', () {
        // Arrange
        const config = MemorySearchConfig(
          scoreMode: MemoryScoreMode.keywordFirst,
          keywordWeight: 15.0,
        );

        // Act
        final copy = config.copyWith();

        // Assert
        expect(copy.scoreMode, config.scoreMode);
        expect(copy.keywordWeight, config.keywordWeight);
        expect(copy.tagWeight, config.tagWeight);
      });

      test('overrides specified fields', () {
        // Arrange
        const config = MemorySearchConfig();

        // Act
        final copy = config.copyWith(
          scoreMode: MemoryScoreMode.semanticFirst,
          vectorWeight: 5.0,
        );

        // Assert
        expect(copy.scoreMode, MemoryScoreMode.semanticFirst);
        expect(copy.vectorWeight, 5.0);
        expect(copy.keywordWeight, 10.0); // unchanged
      });
    });

    group('normalized', () {
      test('clamps negative weights to zero', () {
        // Arrange
        const config = MemorySearchConfig(
          keywordWeight: -5.0,
          tagWeight: -1.0,
          vectorWeight: -0.5,
          edgeWeight: -0.1,
        );

        // Act
        final result = config.normalized();

        // Assert
        expect(result.keywordWeight, 0.0);
        expect(result.tagWeight, 0.0);
        expect(result.vectorWeight, 0.0);
        expect(result.edgeWeight, 0.0);
      });

      test('keeps non-negative weights unchanged', () {
        // Arrange
        const config = MemorySearchConfig(
          keywordWeight: 10.0,
          tagWeight: 2.0,
          vectorWeight: 3.0,
          edgeWeight: 0.5,
        );

        // Act
        final result = config.normalized();

        // Assert
        expect(result.keywordWeight, 10.0);
        expect(result.tagWeight, 2.0);
        expect(result.vectorWeight, 3.0);
        expect(result.edgeWeight, 0.5);
      });

      test('handles mixed positive and negative weights', () {
        // Arrange
        const config = MemorySearchConfig(
          keywordWeight: 10.0,
          tagWeight: -2.0,
          vectorWeight: 3.0,
          edgeWeight: -0.5,
        );

        // Act
        final result = config.normalized();

        // Assert
        expect(result.keywordWeight, 10.0);
        expect(result.tagWeight, 0.0);
        expect(result.vectorWeight, 3.0);
        expect(result.edgeWeight, 0.0);
      });

      test('does not mutate original config', () {
        // Arrange
        const config = MemorySearchConfig(tagWeight: -1.0);

        // Act
        config.normalized();

        // Assert
        expect(config.tagWeight, -1.0);
      });
    });

    group('fromJson', () {
      test('parses complete JSON', () {
        // Arrange
        final json = {
          'score_mode': 'keywordFirst',
          'keyword_weight': 15.0,
          'tag_weight': 2.0,
          'vector_weight': 5.0,
          'edge_weight': 0.8,
        };

        // Act
        final config = MemorySearchConfig.fromJson(json);

        // Assert
        expect(config.scoreMode, MemoryScoreMode.keywordFirst);
        expect(config.keywordWeight, 15.0);
        expect(config.tagWeight, 2.0);
        expect(config.vectorWeight, 5.0);
        expect(config.edgeWeight, 0.8);
      });

      test('applies defaults for missing fields', () {
        // Arrange
        final json = <String, dynamic>{};

        // Act
        final config = MemorySearchConfig.fromJson(json);

        // Assert
        expect(config.scoreMode, MemoryScoreMode.balanced);
        expect(config.keywordWeight, 10.0);
        expect(config.tagWeight, 0.0);
        expect(config.vectorWeight, 0.0);
        expect(config.edgeWeight, 0.4);
      });

      test('parses semanticFirst mode', () {
        // Arrange
        final json = {'score_mode': 'semanticFirst'};

        // Act
        final config = MemorySearchConfig.fromJson(json);

        // Assert
        expect(config.scoreMode, MemoryScoreMode.semanticFirst);
      });

      test('falls back to balanced for unknown mode string', () {
        // Arrange
        final json = {'score_mode': 'unknownMode'};

        // Act
        final config = MemorySearchConfig.fromJson(json);

        // Assert
        expect(config.scoreMode, MemoryScoreMode.balanced);
      });

      test('handles integer weight values from JSON', () {
        // Arrange
        final json = {
          'keyword_weight': 10,
          'tag_weight': 0,
        };

        // Act
        final config = MemorySearchConfig.fromJson(json);

        // Assert
        expect(config.keywordWeight, 10.0);
        expect(config.tagWeight, 0.0);
      });
    });

    group('toJson', () {
      test('serializes all fields', () {
        // Arrange
        const config = MemorySearchConfig(
          scoreMode: MemoryScoreMode.keywordFirst,
          keywordWeight: 15.0,
          tagWeight: 2.0,
          vectorWeight: 5.0,
          edgeWeight: 0.8,
        );

        // Act
        final json = config.toJson();

        // Assert
        expect(json['score_mode'], 'keywordFirst');
        expect(json['keyword_weight'], 15.0);
        expect(json['tag_weight'], 2.0);
        expect(json['vector_weight'], 5.0);
        expect(json['edge_weight'], 0.8);
      });
    });

    group('fromJson/toJson round-trip', () {
      test('preserves all fields through serialization', () {
        // Arrange
        const original = MemorySearchConfig(
          scoreMode: MemoryScoreMode.semanticFirst,
          keywordWeight: 12.0,
          tagWeight: 3.0,
          vectorWeight: 8.0,
          edgeWeight: 0.6,
        );

        // Act
        final json = original.toJson();
        final restored = MemorySearchConfig.fromJson(json);

        // Assert
        expect(restored.scoreMode, original.scoreMode);
        expect(restored.keywordWeight, original.keywordWeight);
        expect(restored.tagWeight, original.tagWeight);
        expect(restored.vectorWeight, original.vectorWeight);
        expect(restored.edgeWeight, original.edgeWeight);
      });

      test('round-trip with default config', () {
        // Arrange
        const original = MemorySearchConfig();

        // Act
        final json = original.toJson();
        final restored = MemorySearchConfig.fromJson(json);

        // Assert
        expect(restored.scoreMode, original.scoreMode);
        expect(restored.keywordWeight, original.keywordWeight);
        expect(restored.edgeWeight, original.edgeWeight);
      });
    });

    group('multiplier getters', () {
      test('balanced mode returns 1.0 for all multipliers', () {
        // Arrange
        const config = MemorySearchConfig(scoreMode: MemoryScoreMode.balanced);

        // Assert
        expect(config.keywordMultiplier, 1.0);
        expect(config.semanticMultiplier, 1.0);
        expect(config.edgeMultiplier, 1.0);
      });

      test('keywordFirst boosts keywords and reduces semantics', () {
        // Arrange
        const config = MemorySearchConfig(scoreMode: MemoryScoreMode.keywordFirst);

        // Assert
        expect(config.keywordMultiplier, 1.3);
        expect(config.semanticMultiplier, 0.8);
        expect(config.edgeMultiplier, 0.9);
      });

      test('semanticFirst boosts semantics and reduces keywords', () {
        // Arrange
        const config = MemorySearchConfig(scoreMode: MemoryScoreMode.semanticFirst);

        // Assert
        expect(config.keywordMultiplier, 0.8);
        expect(config.semanticMultiplier, 1.3);
        expect(config.edgeMultiplier, 1.1);
      });
    });
  });
}
