// Serach.dart (MapSearchPanel) – UI polish only; same API/logic
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

    final trimmed = controller.text.trim();
    final hasQuery = trimmed.isNotEmpty;

    return Positioned(
      left: 14,
      top: 64,
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.86,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.96),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.black.withOpacity(0.06)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 18,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // header row
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                child: Row(
                  children: [
                    Icon(Icons.search_rounded, size: 18, color: Colors.black.withOpacity(0.65)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Search",
                        style: tt.labelLarge?.copyWith(fontWeight: FontWeight.w900),
                      ),
                    ),
                    IconButton(
                      onPressed: onClose,
                      icon: Icon(Icons.close_rounded, color: Colors.black.withOpacity(0.65)),
                      splashRadius: 18,
                    ),
                  ],
                ),
              ),

              // field
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                child: TextField(
                  controller: controller,
                  onChanged: onChanged,
                  style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFFF4F4F4),
                    hintText: hintText,
                    prefixIcon: Icon(Icons.place_rounded, color: Colors.black.withOpacity(0.55)),
                    suffixIcon: hasQuery
                        ? IconButton(
                            icon: Icon(Icons.clear_rounded, color: Colors.black.withOpacity(0.55)),
                            onPressed: () {
                              controller.clear();
                              onChanged("");
                            },
                            splashRadius: 18,
                          )
                        : null,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Colors.black.withOpacity(0.06)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: cs.primary),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
              ),

              // results
              if (!hasQuery)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline_rounded, size: 16, color: Colors.black.withOpacity(0.55)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Type to search and pick a destination.",
                          style: tt.bodySmall?.copyWith(
                            color: Colors.black.withOpacity(0.60),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 260),
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    itemCount: results.length > 7 ? 7 : results.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      thickness: 1,
                      color: Colors.black.withOpacity(0.06),
                    ),
                    itemBuilder: (context, index) {
                      final item = results[index];
                      final title = titleOf(item);
                      if (title.isEmpty) return const SizedBox.shrink();

                      return InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () {
                          onPick(latLngOf(item));
                          onClose();
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                          child: Row(
                            children: [
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: cs.primary.withOpacity(0.10),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(Icons.place_rounded, color: cs.primary, size: 18),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: tt.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: Colors.black.withOpacity(0.78),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(Icons.chevron_right_rounded, color: Colors.black.withOpacity(0.35)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
