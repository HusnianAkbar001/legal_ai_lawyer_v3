class RagMetrics {
  final String period;
  final int totalQueries;
  final RagDecisions decisions;
  final RagQuality quality;
  final RagPerformance performance;
  final RagTokens tokens;
  final String? summary;

  RagMetrics({
    required this.period,
    required this.totalQueries,
    required this.decisions,
    required this.quality,
    required this.performance,
    required this.tokens,
    this.summary,
  });

  factory RagMetrics.fromApi(Map<String, dynamic> json) {
    return RagMetrics(
      period: (json['period'] as String?) ?? 'N/A',
      totalQueries: (json['totalQueries'] as int?) ?? 0,
      summary: json['summary'] as String?,
      decisions: RagDecisions.fromApi(json['decisions'] as Map<String, dynamic>? ?? {}),
      quality: RagQuality.fromApi(json['quality'] as Map<String, dynamic>? ?? {}),
      performance: RagPerformance.fromApi(json['performance'] as Map<String, dynamic>? ?? {}),
      tokens: RagTokens.fromApi(json['tokens'] as Map<String, dynamic>? ?? {}),
    );
  }
}

class RagDecisions {
  final int answer;
  final int outOfDomain;
  final int noHits;

  RagDecisions({
    required this.answer,
    required this.outOfDomain,
    required this.noHits,
  });

  factory RagDecisions.fromApi(Map<String, dynamic> json) {
    return RagDecisions(
      answer: (json['answer'] as int?) ?? 0,
      outOfDomain: (json['outOfDomain'] as int?) ?? 0,
      noHits: (json['noHits'] as int?) ?? 0,
    );
  }
}

class RagQuality {
  final double inDomainRate;
  final double fallbackRate;
  final double errorRate;
  final double avgDistance;
  final double avgContextsUsed;

  RagQuality({
    required this.inDomainRate,
    required this.fallbackRate,
    required this.errorRate,
    required this.avgDistance,
    required this.avgContextsUsed,
  });

  factory RagQuality.fromApi(Map<String, dynamic> json) {
    return RagQuality(
      inDomainRate: (json['inDomainRate'] as num?)?.toDouble() ?? 0,
      fallbackRate: (json['fallbackRate'] as num?)?.toDouble() ?? 0,
      errorRate: (json['errorRate'] as num?)?.toDouble() ?? 0,
      avgDistance: (json['avgDistance'] as num?)?.toDouble() ?? 0,
      avgContextsUsed: (json['avgContextsUsed'] as num?)?.toDouble() ?? 0,
    );
  }
}

class RagPerformance {
  final double avgTotalTimeMs;
  final double avgEmbeddingTimeMs;
  final double avgLlmTimeMs;

  RagPerformance({
    required this.avgTotalTimeMs,
    required this.avgEmbeddingTimeMs,
    required this.avgLlmTimeMs,
  });

  factory RagPerformance.fromApi(Map<String, dynamic> json) {
    return RagPerformance(
      avgTotalTimeMs: (json['avgTotalTimeMs'] as num?)?.toDouble() ?? 0,
      avgEmbeddingTimeMs: (json['avgEmbeddingTimeMs'] as num?)?.toDouble() ?? 0,
      avgLlmTimeMs: (json['avgLlmTimeMs'] as num?)?.toDouble() ?? 0,
    );
  }
}

class RagTokens {
  final int totalUsed;
  final double avgPerQuery;

  RagTokens({
    required this.totalUsed,
    required this.avgPerQuery,
  });

  factory RagTokens.fromApi(Map<String, dynamic> json) {
    return RagTokens(
      totalUsed: (json['totalUsed'] as int?) ?? 0,
      avgPerQuery: (json['avgPerQuery'] as num?)?.toDouble() ?? 0,
    );
  }
}

class KnowledgeSource {
  final int id;
  final String title;
  final String type;
  final String language;
  final String status;
  final String? errorMessage;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  KnowledgeSource({
    required this.id,
    required this.title,
    required this.type,
    required this.language,
    required this.status,
    this.errorMessage,
    this.createdAt,
    this.updatedAt,
  });

  factory KnowledgeSource.fromApi(Map<String, dynamic> json) {
    return KnowledgeSource(
      id: json['id'] as int,
      title: (json['title'] as String?) ?? '',
      type: (json['type'] as String?) ?? '',
      language: (json['language'] as String?) ?? 'en',
      status: (json['status'] as String?) ?? '',
      errorMessage: json['errorMessage'] as String?,
      createdAt: _parseDate(json['createdAt'] as String?),
      updatedAt: _parseDate(json['updatedAt'] as String?),
    );
  }

  static DateTime? _parseDate(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }
}
