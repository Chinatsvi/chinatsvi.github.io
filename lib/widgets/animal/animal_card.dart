// lib/widgets/animal/animal_card.dart
import 'package:flutter/material.dart';
import 'package:agribased/models/animal/animal.dart';

class AnimalCard extends StatelessWidget {
  final Animal animal;
  final VoidCallback? onTap;

  const AnimalCard({super.key, required this.animal, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage:
              animal.photoUrl != null && animal.photoUrl!.startsWith('http')
              ? NetworkImage(animal.photoUrl!)
              : null,
          child: animal.photoUrl == null || !animal.photoUrl!.startsWith('http')
              ? const Icon(Icons.pets)
              : null,
        ),
        title: Text('${animal.species} • ${animal.breed}'),
        subtitle: Text('ID: ${animal.id} • ${animal.ageDisplayLabel}'),
        onTap: onTap,
      ),
    );
  }
}
