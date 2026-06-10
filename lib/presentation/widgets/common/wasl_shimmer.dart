import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/theme/app_colors.dart';

class WaslShimmer extends StatelessWidget {
  final double width;
  final double height;
  final double radius;

  const WaslShimmer({
    super.key,
    required this.width,
    required this.height,
    this.radius = 12,
  });

  const WaslShimmer.card({
    super.key,
    this.width = double.infinity,
    this.height = 100,
    this.radius = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.shimmerBase,
      highlightColor: AppColors.shimmerHigh,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.shimmerBase,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}

class WaslShimmerList extends StatelessWidget {
  final int count;
  final double itemHeight;

  const WaslShimmerList({super.key, this.count = 4, this.itemHeight = 90});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(count, (i) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: WaslShimmer.card(height: itemHeight),
      )),
    );
  }
}
