import 'package:flutter/material.dart';
import 'text1.dart';

class Rzad extends StatelessWidget implements PreferredSizeWidget {
  final List<Map<String, dynamic>> features;  // ✅ NOWY - dane do przeszukania
  final Function(Map<String, dynamic>)? onFeatureSelected;  // ✅ NOWY callback

  const Rzad({
    super.key,
    this.features = const [],  // ✅ Domyślnie pusta lista
    this.onFeatureSelected,
  });

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text1('85248'),
        const SizedBox(width: 12),
        Expanded(
          child: SizedBox(
            height: 30,
            child: Autocomplete<Map<String, dynamic>>(  // ✅ ZMIANA na Autocomplete!
              optionsBuilder: (TextEditingValue textEditingValue) {  // ✅ Filtrowanie
                if (textEditingValue.text.isEmpty) {
                  return const Iterable<Map<String, dynamic>>.empty();
                }
                final query = textEditingValue.text.toLowerCase();
                return features.where((feature) {
                  final name = (feature['properties']?['name'] ?? '').toString().toLowerCase();
                  return name.contains(query);  // Szuka po nazwie
                });
              },
              displayStringForOption: (option) => option['properties']?['name'] ?? 'Bez nazwy',  // ✅ Co wyświetlić
              onSelected: (Map<String, dynamic> selection) {  // ✅ Po wybraniu
                onFeatureSelected?.call(selection);  // Wywołaj callback!
              },
              fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                return TextField(  // Wygląd pola (taki sam jak wcześniej)
                  controller: controller,
                  focusNode: focusNode,
                  decoration: InputDecoration(
                    hintText: 'Wyszukaj',
                    fillColor: const Color.fromARGB(255, 255, 255, 255),
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 10),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
