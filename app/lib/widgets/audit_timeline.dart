import 'package:flutter/material.dart';

class AuditEvent {
  final String title;
  final String description;
  final DateTime timestamp;
  final bool isSuccess;

  AuditEvent({
    required this.title,
    required this.description,
    required this.timestamp,
    required this.isSuccess,
  });
}

class AuditTimeline extends StatelessWidget {
  final List<AuditEvent> events;

  const AuditTimeline({super.key, required this.events});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        final isLast = index == events.length - 1;

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Timeline line and dot
              SizedBox(
                width: 40,
                child: Column(
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      margin: const EdgeInsets.only(top: 8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: event.isSuccess ? Colors.greenAccent : Colors.redAccent,
                        boxShadow: [
                          BoxShadow(
                            color: event.isSuccess
                                ? Colors.greenAccent.withValues(alpha: 0.5)
                                : Colors.redAccent.withValues(alpha: 0.5),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 2,
                          color: Colors.white24,
                        ),
                      ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24.0, right: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        event.description,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${event.timestamp.hour}:${event.timestamp.minute.toString().padLeft(2, '0')}',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
