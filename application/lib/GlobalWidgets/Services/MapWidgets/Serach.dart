import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

class MapSearchPanel<TItem> extends StatelessWidget {
  final bool isExpanded;
  final TextEditingController controller;
  final List<TItem> results;

  final String hintText;
  final String Function(TItem item) titleOf;
  final LatLng Function(TItem item) latLngOf;

  final VoidCallback onClose;
  final void Function(String text) onChanged;
  final void Function(LatLng point) onPick;

  const MapSearchPanel({
    super.key,
    required this.isExpanded,
    required this.controller,
    required this.results,
    required this.hintText,
    required this.titleOf,
    required this.latLngOf,
    required this.onClose,
    required this.onChanged,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    if (!isExpanded) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 0, 0),
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.75,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              onChanged: onChanged,
              style: tt.bodyMedium,
              decoration: InputDecoration(
                filled: true,
                fillColor: cs.surface,
                hintText: hintText,
                prefixIcon: const Icon(Icons.search),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: theme.dividerColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: cs.primary),
                ),
              ),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: results.length,
                itemBuilder: (context, index) {
                  if (index > 6) return const SizedBox.shrink();

                  final item = results[index];
                  final title = titleOf(item);
                  if (title.isEmpty) return const SizedBox.shrink();

                  return Material(
                    color: cs.surface,
                    child: ListTile(
                      title: Text(
                        title,
                        style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      onTap: () {
                        onPick(latLngOf(item));
                        onClose();
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
