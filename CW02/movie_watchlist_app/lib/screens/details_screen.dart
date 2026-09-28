import 'package:flutter/material.dart';

import '../models/movie.dart';

class DetailsScreen extends StatelessWidget {
  final Movie movie;
  const DetailsScreen({super.key, required this.movie});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(movie.title),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Image.asset(
                  movie.posterPath,
                  height: 300,
                  fit: BoxFit.contain,
                  semanticLabel: '${movie.title} poster',
                ),
              ),
              const SizedBox(height: 20),
              Text(
                movie.title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              Text('Cast', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(movie.cast.join('\n')),
              const SizedBox(height: 20),
              Text('Synopsis', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                movie.synopsis,
                style: const TextStyle(fontSize: 16, height: 1.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
