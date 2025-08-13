import 'package:flutter/material.dart';

class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final Widget Function(Object error, StackTrace? stackTrace)? errorBuilder;
  final void Function(Object error, StackTrace? stackTrace)? onError;
  final String componentName;

  const ErrorBoundary({
    Key? key,
    required this.child,
    this.errorBuilder,
    this.onError,
    this.componentName = 'Component',
  }) : super(key: key);

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  Object? _error;
  StackTrace? _stackTrace;
  
  @override
  void initState() {
    super.initState();
    // Reset error state when widget is rebuilt
    _error = null;
    _stackTrace = null;
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      // Call error callback if provided
      if (widget.onError != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          widget.onError!(_error!, _stackTrace);
        });
      }
      
      // Return error widget
      if (widget.errorBuilder != null) {
        return widget.errorBuilder!(_error!, _stackTrace);
      }
      
      // Default error widget
      return _buildDefaultErrorWidget();
    }

    // Wrap child in error catching widget
    return _ErrorCatcher(
      onError: (error, stackTrace) {
        if (mounted) {
          setState(() {
            _error = error;
            _stackTrace = stackTrace;
          });
        }
      },
      child: widget.child,
    );
  }

  Widget _buildDefaultErrorWidget() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade900.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade700, width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red.shade300,
            size: 48,
          ),
          const SizedBox(height: 8),
          Text(
            '${widget.componentName} Error',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _error.toString(),
            style: TextStyle(
              color: Colors.red.shade200,
              fontSize: 12,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _error = null;
                _stackTrace = null;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

// Internal widget to catch errors
class _ErrorCatcher extends StatelessWidget {
  final Widget child;
  final void Function(Object error, StackTrace? stackTrace) onError;

  const _ErrorCatcher({
    Key? key,
    required this.child,
    required this.onError,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    ErrorWidget.builder = (FlutterErrorDetails details) {
      // Capture the error
      WidgetsBinding.instance.addPostFrameCallback((_) {
        onError(details.exception, details.stack);
      });
      
      // Return empty container to let ErrorBoundary handle display
      return const SizedBox.shrink();
    };
    
    return child;
  }
}

// Specialized error boundary for dashboard gauges
class GaugeErrorBoundary extends StatelessWidget {
  final Widget child;
  final String gaugeName;
  final double? size;

  const GaugeErrorBoundary({
    Key? key,
    required this.child,
    required this.gaugeName,
    this.size,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ErrorBoundary(
      componentName: gaugeName,
      errorBuilder: (error, stackTrace) {
        return Container(
          width: size ?? 150,
          height: size ?? 150,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.grey.shade900,
            border: Border.all(color: Colors.red.shade700, width: 2),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.speed,
                color: Colors.grey.shade600,
                size: (size ?? 150) * 0.3,
              ),
              const SizedBox(height: 8),
              Text(
                'ERROR',
                style: TextStyle(
                  color: Colors.red.shade400,
                  fontSize: (size ?? 150) * 0.08,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                gaugeName,
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: (size ?? 150) * 0.06,
                ),
              ),
            ],
          ),
        );
      },
      child: child,
    );
  }
}

// Error boundary specifically for the main dashboard
class DashboardErrorBoundary extends StatelessWidget {
  final Widget child;

  const DashboardErrorBoundary({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ErrorBoundary(
      componentName: 'Dashboard',
      errorBuilder: (error, stackTrace) {
        // Log error for debugging
        debugPrint('Dashboard Error: $error');
        debugPrint('Stack trace: $stackTrace');
        
        return Scaffold(
          backgroundColor: Colors.black,
          body: Center(
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.red.shade900.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.red.shade700, width: 2),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.red.shade400,
                    size: 80,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Dashboard System Error',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'An error occurred in the dashboard system',
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      // Attempt to restart the app
                      Navigator.of(context).pushNamedAndRemoveUntil(
                        '/',
                        (route) => false,
                      );
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Restart Dashboard'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      onError: (error, stackTrace) {
        // Could send error to logging service here
        print('Dashboard critical error: $error');
      },
      child: child,
    );
  }
}