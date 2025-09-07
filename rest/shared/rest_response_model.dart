/// Generic REST API response model
class RestResponse<T> {
  final bool success;
  final T? data;
  final RestError? error;
  final RestPagination? pagination;

  const RestResponse({
    required this.success,
    this.data,
    this.error,
    this.pagination,
  });

  factory RestResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic) fromJsonT,
  ) {
    return RestResponse<T>(
      success: json['success'] ?? false,
      data: json['data'] != null ? fromJsonT(json['data']) : null,
      error: json['error'] != null ? RestError.fromJson(json['error']) : null,
      pagination: json['pagination'] != null ? RestPagination.fromJson(json['pagination']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'data': data,
      'error': error?.toJson(),
      'pagination': pagination?.toJson(),
    };
  }

  /// Check if response is successful
  bool get isSuccess => success && error == null;

  /// Check if response has error
  bool get hasError => !success || error != null;

  /// Get error message
  String get errorMessage => error?.message ?? 'Unknown error';

  /// Get error code
  String get errorCode => error?.code ?? 'UNKNOWN_ERROR';
}

/// REST API error model
class RestError {
  final String code;
  final String message;
  final String? details;
  final List<RestValidationError>? validationErrors;

  const RestError({
    required this.code,
    required this.message,
    this.details,
    this.validationErrors,
  });

  factory RestError.fromJson(Map<String, dynamic> json) {
    return RestError(
      code: json['code'] ?? 'UNKNOWN_ERROR',
      message: json['message'] ?? 'Unknown error',
      details: json['details'],
      validationErrors: json['validationErrors'] != null
          ? (json['validationErrors'] as List)
              .map((e) => RestValidationError.fromJson(e))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'message': message,
      'details': details,
      'validationErrors': validationErrors?.map((e) => e.toJson()).toList(),
    };
  }
}

/// REST API validation error model
class RestValidationError {
  final String field;
  final String message;
  final String? value;

  const RestValidationError({
    required this.field,
    required this.message,
    this.value,
  });

  factory RestValidationError.fromJson(Map<String, dynamic> json) {
    return RestValidationError(
      field: json['field'] ?? '',
      message: json['message'] ?? '',
      value: json['value'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'field': field,
      'message': message,
      'value': value,
    };
  }
}

/// REST API pagination model
class RestPagination {
  final int page;
  final int limit;
  final int total;
  final int totalPages;
  final bool hasNext;
  final bool hasPrevious;

  const RestPagination({
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
    required this.hasNext,
    required this.hasPrevious,
  });

  factory RestPagination.fromJson(Map<String, dynamic> json) {
    final page = json['page'] ?? 1;
    final limit = json['limit'] ?? 20;
    final total = json['total'] ?? 0;
    final totalPages = json['totalPages'] ?? 0;

    return RestPagination(
      page: page,
      limit: limit,
      total: total,
      totalPages: totalPages,
      hasNext: page < totalPages,
      hasPrevious: page > 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'page': page,
      'limit': limit,
      'total': total,
      'totalPages': totalPages,
      'hasNext': hasNext,
      'hasPrevious': hasPrevious,
    };
  }

  /// Get next page number
  int? get nextPage => hasNext ? page + 1 : null;

  /// Get previous page number
  int? get previousPage => hasPrevious ? page - 1 : null;

  /// Get start index for current page
  int get startIndex => (page - 1) * limit;

  /// Get end index for current page
  int get endIndex => (startIndex + limit - 1).clamp(0, total - 1);
}

/// REST API search parameters
class RestSearchParams {
  final String? query;
  final Map<String, String> filters;
  final int page;
  final int limit;
  final String? sortBy;
  final String? sortOrder;

  const RestSearchParams({
    this.query,
    this.filters = const {},
    this.page = 1,
    this.limit = 20,
    this.sortBy,
    this.sortOrder,
  });

  Map<String, String> toQueryParams() {
    final params = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };

    if (query != null && query!.isNotEmpty) {
      params['q'] = query!;
    }

    if (sortBy != null) {
      params['sortBy'] = sortBy!;
    }

    if (sortOrder != null) {
      params['sortOrder'] = sortOrder!;
    }

    params.addAll(filters);

    return params;
  }

  RestSearchParams copyWith({
    String? query,
    Map<String, String>? filters,
    int? page,
    int? limit,
    String? sortBy,
    String? sortOrder,
  }) {
    return RestSearchParams(
      query: query ?? this.query,
      filters: filters ?? this.filters,
      page: page ?? this.page,
      limit: limit ?? this.limit,
      sortBy: sortBy ?? this.sortBy,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}

/// REST API batch operation result
class RestBatchResult<T> {
  final List<T> successful;
  final List<RestBatchError> failed;
  final int totalProcessed;
  final int successCount;
  final int failureCount;

  const RestBatchResult({
    required this.successful,
    required this.failed,
    required this.totalProcessed,
    required this.successCount,
    required this.failureCount,
  });

  bool get isComplete => failed.isEmpty;
  bool get hasFailures => failed.isNotEmpty;
  double get successRate => totalProcessed > 0 ? successCount / totalProcessed : 0.0;
}

/// REST API batch operation error
class RestBatchError {
  final int index;
  final String code;
  final String message;
  final dynamic data;

  const RestBatchError({
    required this.index,
    required this.code,
    required this.message,
    this.data,
  });
}
