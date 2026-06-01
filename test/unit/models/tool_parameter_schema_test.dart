import 'package:flutter_test/flutter_test.dart';
import 'package:novel_ide/data/models/tool_parameter_schema.dart';

void main() {
  group('ToolParameterSchema', () {
    // ============================================================
    // Constructor
    // ============================================================
    group('constructor', () {
      test('creates instance with required fields only', () {
        // Arrange & Act
        const schema = ToolParameterSchema(
          name: 'title',
          description: 'Chapter title',
        );

        // Assert
        expect(schema.name, 'title');
        expect(schema.description, 'Chapter title');
        expect(schema.type, 'string'); // default
        expect(schema.required, isTrue); // default
        expect(schema.defaultValue, isNull);
      });

      test('creates instance with all fields provided', () {
        // Arrange & Act
        const schema = ToolParameterSchema(
          name: 'count',
          type: 'integer',
          description: 'Number of items',
          required: false,
          defaultValue: '10',
        );

        // Assert
        expect(schema.name, 'count');
        expect(schema.type, 'integer');
        expect(schema.description, 'Number of items');
        expect(schema.required, isFalse);
        expect(schema.defaultValue, '10');
      });
    });

    // ============================================================
    // fromJson
    // ============================================================
    group('fromJson', () {
      test('creates instance from complete JSON', () {
        // Arrange
        final json = {
          'name': 'content',
          'type': 'string',
          'description': 'The content text',
          'required': true,
          'defaultValue': 'hello',
        };

        // Act
        final schema = ToolParameterSchema.fromJson(json);

        // Assert
        expect(schema.name, 'content');
        expect(schema.type, 'string');
        expect(schema.description, 'The content text');
        expect(schema.required, isTrue);
        expect(schema.defaultValue, 'hello');
      });

      test('uses defaults for optional fields missing from JSON', () {
        // Arrange
        final json = {'name': 'title', 'description': 'A title'};

        // Act
        final schema = ToolParameterSchema.fromJson(json);

        // Assert
        expect(schema.type, 'string');
        expect(schema.required, isTrue);
        expect(schema.defaultValue, isNull);
      });

      test('handles required=false from JSON', () {
        // Arrange
        final json = {
          'name': 'optional_field',
          'description': 'Optional',
          'required': false,
        };

        // Act
        final schema = ToolParameterSchema.fromJson(json);

        // Assert
        expect(schema.required, isFalse);
      });

      test('handles null defaultValue in JSON', () {
        // Arrange
        final json = {
          'name': 'field',
          'description': 'desc',
          'defaultValue': null,
        };

        // Act
        final schema = ToolParameterSchema.fromJson(json);

        // Assert
        expect(schema.defaultValue, isNull);
      });
    });

    // ============================================================
    // toJson
    // ============================================================
    group('toJson', () {
      test('serializes all fields', () {
        // Arrange
        const schema = ToolParameterSchema(
          name: 'title',
          type: 'string',
          description: 'The title',
          required: true,
          defaultValue: 'Untitled',
        );

        // Act
        final json = schema.toJson();

        // Assert
        expect(json['name'], 'title');
        expect(json['type'], 'string');
        expect(json['description'], 'The title');
        expect(json['required'], isTrue);
        expect(json['defaultValue'], 'Untitled');
      });

      test('omits defaultValue key when null', () {
        // Arrange
        const schema = ToolParameterSchema(name: 'x', description: 'desc');

        // Act
        final json = schema.toJson();

        // Assert
        expect(json.containsKey('defaultValue'), isFalse);
      });

      test('roundtrip fromJson -> toJson preserves data', () {
        // Arrange
        final original = {
          'name': 'count',
          'type': 'integer',
          'description': 'How many',
          'required': false,
          'defaultValue': '5',
        };

        // Act
        final schema = ToolParameterSchema.fromJson(original);
        final roundtrip = schema.toJson();

        // Assert
        expect(roundtrip['name'], original['name']);
        expect(roundtrip['type'], original['type']);
        expect(roundtrip['description'], original['description']);
        expect(roundtrip['required'], original['required']);
        expect(roundtrip['defaultValue'], original['defaultValue']);
      });
    });

    // ============================================================
    // copyWith
    // ============================================================
    group('copyWith', () {
      test('returns new instance with single field changed', () {
        // Arrange
        const original = ToolParameterSchema(
          name: 'old_name',
          description: 'desc',
        );

        // Act
        final copy = original.copyWith(name: 'new_name');

        // Assert
        expect(copy.name, 'new_name');
        expect(copy.description, original.description);
        expect(copy.type, original.type);
      });

      test('preserves all fields when no arguments provided', () {
        // Arrange
        const original = ToolParameterSchema(
          name: 'field',
          type: 'boolean',
          description: 'a flag',
          required: false,
          defaultValue: 'true',
        );

        // Act
        final copy = original.copyWith();

        // Assert
        expect(copy.name, original.name);
        expect(copy.type, original.type);
        expect(copy.description, original.description);
        expect(copy.required, original.required);
        expect(copy.defaultValue, original.defaultValue);
      });

      test('original instance remains unchanged after copyWith', () {
        // Arrange
        const original = ToolParameterSchema(
          name: 'stable',
          description: 'desc',
        );

        // Act
        original.copyWith(name: 'changed');

        // Assert
        expect(original.name, 'stable');
      });
    });

    // ============================================================
    // toString
    // ============================================================
    group('toString', () {
      test('contains name, type, and required', () {
        // Arrange
        const schema = ToolParameterSchema(
          name: 'title',
          type: 'string',
          description: 'ignored in toString',
        );

        // Act
        final str = schema.toString();

        // Assert
        expect(str, contains('title'));
        expect(str, contains('string'));
        expect(str, contains('true'));
      });
    });
  });

  group('ToolValidationResult', () {
    group('ok', () {
      test('creates valid result with no error message', () {
        // Arrange & Act
        final result = ToolValidationResult.ok();

        // Assert
        expect(result.valid, isTrue);
        expect(result.errorMessage, isEmpty);
      });
    });

    group('invalid', () {
      test('creates invalid result with error message', () {
        // Arrange & Act
        final result = ToolValidationResult.invalid('Parameter missing');

        // Assert
        expect(result.valid, isFalse);
        expect(result.errorMessage, 'Parameter missing');
      });
    });

    group('toString', () {
      test('includes valid state and error message', () {
        // Arrange
        final ok = ToolValidationResult.ok();
        final invalid = ToolValidationResult.invalid('oops');

        // Act & Assert
        expect(ok.toString(), contains('true'));
        expect(invalid.toString(), contains('false'));
        expect(invalid.toString(), contains('oops'));
      });
    });
  });

  group('ToolInvocation', () {
    test('stores all fields', () {
      // Arrange & Act
      const inv = ToolInvocation(
        toolName: 'edit',
        rawText: '<tool name="edit">...</tool>',
        startOffset: 10,
        endOffset: 40,
      );

      // Assert
      expect(inv.toolName, 'edit');
      expect(inv.rawText, '<tool name="edit">...</tool>');
      expect(inv.startOffset, 10);
      expect(inv.endOffset, 40);
    });

    test('toString includes tool name and offset range', () {
      // Arrange
      const inv = ToolInvocation(
        toolName: 'save',
        rawText: '<tool name="save"></tool>',
        startOffset: 0,
        endOffset: 24,
      );

      // Act
      final str = inv.toString();

      // Assert
      expect(str, contains('save'));
      expect(str, contains('0'));
      expect(str, contains('24'));
    });
  });

  group('unescapeXml (tool_parameter_schema)', () {
    test('unescapes standard XML entities', () {
      // Arrange & Act & Assert
      expect(unescapeXml('&lt;'), '<');
      expect(unescapeXml('&gt;'), '>');
      expect(unescapeXml('&amp;'), '&');
      expect(unescapeXml('&quot;'), '"');
      expect(unescapeXml("&apos;"), "'");
    });

    test('unescapes multiple entities in one string', () {
      // Arrange
      const input = '&lt;a href=&quot;url&quot;&gt;link&lt;/a&gt;';

      // Act
      final result = unescapeXml(input);

      // Assert
      expect(result, '<a href="url">link</a>');
    });

    test('strips full CDATA wrapper', () {
      // Arrange
      const input = '<![CDATA[raw content & <tags>]]>';

      // Act & Assert
      expect(unescapeXml(input), 'raw content & <tags>');
    });

    test('strips leading CDATA marker without closing', () {
      // Arrange
      const input = '<![CDATA[incomplete';

      // Act & Assert
      expect(unescapeXml(input), 'incomplete');
    });

    test('strips trailing ]]> without opening CDATA', () {
      // Arrange
      const input = 'trailing]]>';

      // Act & Assert
      expect(unescapeXml(input), 'trailing');
    });

    test('returns plain text unchanged', () {
      // Arrange
      const input = 'no entities here';

      // Act & Assert
      expect(unescapeXml(input), 'no entities here');
    });
  });
}
