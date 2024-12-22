import 'package:flutter/material.dart';
import 'package:susu_micro/extensions/spacing.dart';
import 'package:susu_micro/utils/colors.dart';

class PageIndicator extends StatefulWidget {
  int? selectedIndex;
  PageIndicator({super.key, this.selectedIndex});

  @override
  State<PageIndicator> createState() => _PageIndicatorState();
}

class _PageIndicatorState extends State<PageIndicator> {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: (widget.selectedIndex == 1) ? 60 : 50,
          height: (widget.selectedIndex == 1) ? 60 : 50,
          decoration: BoxDecoration(
            color: (widget.selectedIndex == 1) ? AppColors().yellowColor : null,
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
              color: AppColors().blackColor,
            ),
          ),
          child: const Center(
            child: Text("1"),
          ),
        ),
        20.0.hSpace,
        Container(
          width: (widget.selectedIndex == 2) ? 60 : 50,
          height: (widget.selectedIndex == 2) ? 60 : 50,
          decoration: BoxDecoration(
            color: (widget.selectedIndex == 2) ? AppColors().yellowColor : null,
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
              color: AppColors().blackColor,
            ),
          ),
          child: const Center(
            child: Text("2"),
          ),
        ),
        20.0.hSpace,
        Container(
          width: (widget.selectedIndex == 3) ? 60 : 50,
          height: (widget.selectedIndex == 3) ? 60 : 50,
          decoration: BoxDecoration(
            color: (widget.selectedIndex == 3) ? AppColors().yellowColor : null,
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
              color: AppColors().blackColor,
            ),
          ),
          child: const Center(
            child: Text("3"),
          ),
        ),
      ],
    );
  }
}
