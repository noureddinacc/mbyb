import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class BookCardSkeleton extends StatelessWidget {
  const BookCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(width: double.infinity, height: 20, color: Colors.white),
                        const SizedBox(height: 4),
                        Container(width: 150, height: 16, color: Colors.white),
                        const SizedBox(height: 12),
                        Container(width: 100, height: 20, color: Colors.white),
                        const SizedBox(height: 8),
                        Container(width: 200, height: 20, color: Colors.white),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(width: 70, height: 24, color: Colors.white),
                ],
              ),
              const SizedBox(height: 24),
              Container(width: double.infinity, height: 48, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}

class ChatCardSkeleton extends StatelessWidget {
  const ChatCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: ListTile(
          leading: const CircleAvatar(backgroundColor: Colors.white),
          title: Container(width: 100, height: 16, color: Colors.white),
          subtitle: Container(width: double.infinity, height: 14, color: Colors.white),
          trailing: const Icon(Icons.chevron_right),
        ),
      ),
    );
  }
}
