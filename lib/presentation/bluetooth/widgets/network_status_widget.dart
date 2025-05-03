import 'package:flutter/material.dart';

class NetworkStatusWidget extends StatelessWidget {
  final bool isNetworkConnected;
  final int cachedRequestsCount;

  const NetworkStatusWidget({
    super.key,
    required this.isNetworkConnected,
    required this.cachedRequestsCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: isNetworkConnected ? Colors.green[100] : Colors.red[100],
        border: Border.all(
          color: isNetworkConnected ? Colors.green : Colors.red,
          width: 1,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return ScaleTransition(scale: animation, child: child);
                },
                child:
                    isNetworkConnected
                        ? const Icon(
                          Icons.wifi,
                          color: Colors.green,
                          size: 22,
                          key: ValueKey('connected'),
                        )
                        : const Icon(
                          Icons.wifi_off,
                          color: Colors.red,
                          size: 22,
                          key: ValueKey('disconnected'),
                        ),
              ),
              const SizedBox(width: 8),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 300),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isNetworkConnected ? Colors.green : Colors.red,
                ),
                child: Text(
                  isNetworkConnected
                      ? "Internet: Connected"
                      : "Internet: Disconnected",
                ),
              ),
            ],
          ),
          if (cachedRequestsCount > 0) ...[
            const SizedBox(height: 8),
            CachedRequestsIndicator(count: cachedRequestsCount),
          ],
        ],
      ),
    );
  }
}

class CachedRequestsIndicator extends StatelessWidget {
  final int count;

  const CachedRequestsIndicator({super.key, required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.storage, color: Colors.blue, size: 18),
          const SizedBox(width: 4),
          Text(
            "Cached requests: $count",
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.blue[900],
            ),
          ),
        ],
      ),
    );
  }
}
