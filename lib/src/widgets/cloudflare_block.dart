import 'package:flutter/material.dart';

class CloudflareBlock extends StatefulWidget {
  const CloudflareBlock({super.key});

  @override
  State<CloudflareBlock> createState() => _CloudflareBlockState();
}

class _CloudflareBlockState extends State<CloudflareBlock> {
  @override
  Widget build(BuildContext context) {
    return Center(
        child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Text(
            "403: Likely Cloudflare", // TODO: change
            style: Theme.of(context).textTheme.headlineMedium,
          ),
        ),
        FilledButton(
            onPressed: () {},
            child: const Text("Solve captcha")) // TODO: change
      ],
    ));
  }
}
