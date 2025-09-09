import 'dart:convert';
import 'dart:math';
import 'package:vector_math/vector_math.dart' as vm;
import 'package:logger/logger.dart';
import 'package:hive/hive.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class VectorDocument {
  final String id;
  final String content;
  final Map<String, dynamic> metadata;
  final List<double> embedding;
  final DateTime createdAt;

  VectorDocument({
    required this.id,
    required this.content,
    required this.metadata,
    required this.embedding,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'metadata': metadata,
      'embedding': embedding,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory VectorDocument.fromJson(Map<String, dynamic> json) {
    return VectorDocument(
      id: json['id'] as String,
      content: json['content'] as String,
      metadata: Map<String, dynamic>.from(json['metadata']),
      embedding: List<double>.from(json['embedding']),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

class SearchResult {
  final VectorDocument document;
  final double similarity;

  SearchResult({
    required this.document,
    required this.similarity,
  });
}

class VectorStoreService {
  static const String _boxName = 'vector_store';
  final Logger _logger = Logger();
  Box<String>? _box;
  final Random _random = Random();

  /// Initialize the vector store
  Future<void> initialize() async {
    try {
      _box = await Hive.openBox<String>(_boxName);
      _logger.i('Vector store initialized successfully');
    } catch (e) {
      _logger.e('Failed to initialize vector store: $e');
      // Don't rethrow - allow app to continue without vector store
      _logger.w('App will continue without vector store functionality');
    }
  }

  /// Add a document to the vector store
  Future<void> addDocument({
    required String id,
    required String content,
    Map<String, dynamic>? metadata,
  }) async {
    if (_box == null) {
      _logger.w('Vector store not initialized, skipping document addition');
      return;
    }

    try {
      // Generate embedding (simplified - in production, use a proper embedding model)
      final embedding = _generateEmbedding(content);
      
      final document = VectorDocument(
        id: id,
        content: content,
        metadata: metadata ?? {},
        embedding: embedding,
        createdAt: DateTime.now(),
      );

      await _box!.put(id, jsonEncode(document.toJson()));
      _logger.d('Document added to vector store: $id');
    } catch (e) {
      _logger.e('Failed to add document to vector store: $e');
      rethrow;
    }
  }

  /// Search for similar documents
  Future<List<SearchResult>> search({
    required String query,
    int limit = 10,
    double threshold = 0.5,
  }) async {
    if (_box == null) {
      _logger.w('Vector store not initialized, returning empty results');
      return [];
    }

    try {
      final queryEmbedding = _generateEmbedding(query);
      final results = <SearchResult>[];

      for (final key in _box!.keys) {
        final docJson = _box!.get(key);
        if (docJson == null) continue;

        final document = VectorDocument.fromJson(jsonDecode(docJson));
        
        final similarity = _cosineSimilarity(queryEmbedding, document.embedding);
        
        if (similarity >= threshold) {
          results.add(SearchResult(
            document: document,
            similarity: similarity,
          ));
        }
      }

      // Sort by similarity (descending) and limit results
      results.sort((a, b) => b.similarity.compareTo(a.similarity));
      return results.take(limit).toList();
    } catch (e) {
      _logger.e('Failed to search vector store: $e');
      return [];
    }
  }

  /// Get a document by ID
  Future<VectorDocument?> getDocument(String id) async {
    if (_box == null) {
      throw Exception('Vector store not initialized');
    }

    try {
      final docJson = _box!.get(id);
      if (docJson == null) return null;

      return VectorDocument.fromJson(jsonDecode(docJson));
    } catch (e) {
      _logger.e('Failed to get document from vector store: $e');
      return null;
    }
  }

  /// Update a document
  Future<void> updateDocument({
    required String id,
    required String content,
    Map<String, dynamic>? metadata,
  }) async {
    await addDocument(id: id, content: content, metadata: metadata);
  }

  /// Delete a document
  Future<void> deleteDocument(String id) async {
    if (_box == null) {
      throw Exception('Vector store not initialized');
    }

    try {
      await _box!.delete(id);
      _logger.d('Document deleted from vector store: $id');
    } catch (e) {
      _logger.e('Failed to delete document from vector store: $e');
      rethrow;
    }
  }

  /// Get all documents with optional filters
  Future<List<VectorDocument>> getAllDocuments({
    Map<String, dynamic>? filters,
  }) async {
    if (_box == null) {
      throw Exception('Vector store not initialized');
    }

    try {
      final documents = <VectorDocument>[];

      for (final key in _box!.keys) {
        final docJson = _box!.get(key);
        if (docJson == null) continue;

        final document = VectorDocument.fromJson(jsonDecode(docJson));
        
        if (filters == null || _matchesFilters(document.metadata, filters)) {
          documents.add(document);
        }
      }

      return documents;
    } catch (e) {
      _logger.e('Failed to get all documents from vector store: $e');
      return [];
    }
  }

  /// Clear all documents
  Future<void> clear() async {
    if (_box == null) {
      throw Exception('Vector store not initialized');
    }

    try {
      await _box!.clear();
      _logger.i('Vector store cleared');
    } catch (e) {
      _logger.e('Failed to clear vector store: $e');
      rethrow;
    }
  }

  /// Get statistics about the vector store
  Future<Map<String, dynamic>> getStats() async {
    if (_box == null) {
      throw Exception('Vector store not initialized');
    }

    try {
      final totalDocuments = _box!.length;
      final documents = await getAllDocuments();
      
      final categories = <String, int>{};
      var totalContentLength = 0;
      DateTime? oldestDoc;
      DateTime? newestDoc;

      for (final doc in documents) {
        totalContentLength += doc.content.length;
        
        if (oldestDoc == null || doc.createdAt.isBefore(oldestDoc)) {
          oldestDoc = doc.createdAt;
        }
        
        if (newestDoc == null || doc.createdAt.isAfter(newestDoc)) {
          newestDoc = doc.createdAt;
        }

        final category = doc.metadata['category'] as String? ?? 'uncategorized';
        categories[category] = (categories[category] ?? 0) + 1;
      }

      return {
        'totalDocuments': totalDocuments,
        'averageContentLength': totalDocuments > 0 ? totalContentLength / totalDocuments : 0,
        'categories': categories,
        'oldestDocument': oldestDoc?.toIso8601String(),
        'newestDocument': newestDoc?.toIso8601String(),
      };
    } catch (e) {
      _logger.e('Failed to get vector store stats: $e');
      return {};
    }
  }

  /// Generate a simple embedding for text (simplified version)
  /// In production, use a proper embedding model like sentence-transformers
  List<double> _generateEmbedding(String text) {
    const embeddingSize = 384; // Common embedding size
    final words = text.toLowerCase().split(RegExp(r'\W+'));
    final embedding = List<double>.filled(embeddingSize, 0.0);
    
    // Simple hash-based embedding (for demonstration)
    for (final word in words) {
      if (word.isEmpty) continue;
      
      final hash = word.hashCode;
      for (int i = 0; i < embeddingSize; i++) {
        final index = (hash + i) % embeddingSize;
        embedding[index] += 1.0 / words.length;
      }
    }
    
    // Normalize the embedding
    final magnitude = sqrt(embedding.fold(0.0, (sum, val) => sum + val * val));
    if (magnitude > 0) {
      for (int i = 0; i < embedding.length; i++) {
        embedding[i] /= magnitude;
      }
    }
    
    return embedding;
  }

  /// Calculate cosine similarity between two vectors
  double _cosineSimilarity(List<double> a, List<double> b) {
    if (a.length != b.length) return 0.0;
    
    double dotProduct = 0.0;
    double magnitudeA = 0.0;
    double magnitudeB = 0.0;
    
    for (int i = 0; i < a.length; i++) {
      dotProduct += a[i] * b[i];
      magnitudeA += a[i] * a[i];
      magnitudeB += b[i] * b[i];
    }
    
    magnitudeA = sqrt(magnitudeA);
    magnitudeB = sqrt(magnitudeB);
    
    if (magnitudeA == 0.0 || magnitudeB == 0.0) return 0.0;
    
    return dotProduct / (magnitudeA * magnitudeB);
  }

  /// Check if document metadata matches filters
  bool _matchesFilters(Map<String, dynamic> metadata, Map<String, dynamic> filters) {
    for (final entry in filters.entries) {
      final key = entry.key;
      final value = entry.value;
      
      if (!metadata.containsKey(key)) return false;
      
      if (metadata[key] != value) return false;
    }
    
    return true;
  }

  /// Close the vector store
  Future<void> close() async {
    await _box?.close();
    _box = null;
  }
}

// Provider for VectorStoreService
final vectorStoreServiceProvider = Provider<VectorStoreService>((ref) {
  return VectorStoreService();
});