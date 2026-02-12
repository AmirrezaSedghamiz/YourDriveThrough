// RestaurantSettings.dart
import 'dart:io';

import 'package:application/GlobalWidgets/AppTheme/Colors.dart';
import 'package:application/GlobalWidgets/NavigationServices/NavigationService.dart';
import 'package:application/GlobalWidgets/NavigationServices/RouteFactory.dart';
import 'package:application/GlobalWidgets/PermissionHandlers/ImagePickerService.dart';
import 'package:application/GlobalWidgets/ReusableComponents/TapContainers.dart';
import 'package:application/Handlers/TokenHandler.dart';
import 'package:application/MainProgram/Login/Login.dart';
import 'package:application/MainProgram/Manager/Menu/MenuState.dart';
import 'package:application/MainProgram/Manager/Menu/MenuViewModel.dart';
import 'package:application/SourceDesign/Models/Category.dart';
import 'package:application/SourceDesign/Models/Item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RestaurantSettings extends ConsumerStatefulWidget {
  const RestaurantSettings({super.key});

  @override
  ConsumerState<RestaurantSettings> createState() => _RestaurantSettingsState();
}

class _RestaurantSettingsState extends ConsumerState<RestaurantSettings>
    with AutomaticKeepAliveClientMixin<RestaurantSettings> {
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    // Might not be initialized if widget disposed very fast
    try {
      _nameController.dispose();
    } catch (_) {}
    super.dispose();
  }

  File? image;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final t = Theme.of(context).textTheme;
    final state = ref.watch(restaurantSettingsViewModelProvider);
    final vm = ref.read(restaurantSettingsViewModelProvider.notifier);
    // initialize from state after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final s = ref.read(restaurantSettingsViewModelProvider);
      _nameController = TextEditingController(text: s.restaurantName);

      // snack/errors
      ref.listen<RestaurantSettingsState>(restaurantSettingsViewModelProvider, (
        prev,
        next,
      ) {
        final msg = next.snackBarMessage;
        if (msg != null && msg.isNotEmpty) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(msg)));
          ref.read(restaurantSettingsViewModelProvider.notifier).clearSnack();
        }
        final err = next.errorMessage;
        if (err != null && err.isNotEmpty) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(err)));
        }

        // keep controller in sync if you ever load from API later
        if (_nameController.text != next.restaurantName) {
          _nameController.text = next.restaurantName;
        }
      });
    });
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      child: Column(
        children: [
          // ---------- Profile (Image + Name + Location) ----------
          _SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Restaurant Profile",
                  style: t.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),

                // Image + button
                Row(
                  children: [
                    _ImageCircle(
                      file: state.restaurantImageFile,
                      imageUrl: state.restaurantImageUrl,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            ImagePickerService imagePicker = ImagePickerService(
                              context: context,
                            );
                            await imagePicker.pickImage().then((value) {
                              image = imagePicker.image;
                            });
                          },
                          icon: const Icon(
                            Icons.photo_camera_outlined,
                            size: 18,
                          ),
                          label: Text("Upload Image", style: t.labelLarge),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.black.withOpacity(0.8),
                            side: BorderSide(
                              color: Colors.black.withOpacity(0.12),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Name
                Text(
                  "Restaurant Name",
                  style: t.bodySmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: TextEditingController(text: state.restaurantName)
                    ..selection = TextSelection.collapsed(
                      offset: state.restaurantName.length,
                    ),
                  onChanged: vm.setRestaurantName,
                  decoration: InputDecoration(
                    hintText: "Enter restaurant name",
                    filled: true,
                    fillColor: const Color(0xFFF7F7F7),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFEAEAEA)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFEAEAEA)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.primary),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                Text(
                  "Location Changer",
                  style: t.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(
                  "Manage your restaurant's physical location and\ndelivery radius.",
                  style: t.bodySmall?.copyWith(
                    color: Colors.black.withOpacity(0.55),
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 12),

                Text(
                  "Current Address",
                  style: t.bodySmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F7F7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFEAEAEA)),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        color: Colors.black.withOpacity(0.55),
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          state.currentAddress,
                          style: t.bodyMedium?.copyWith(
                            color: Colors.black.withOpacity(0.75),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                Center(
                  child: TextButton.icon(
                    onPressed: () async {
                      // YOU will handle map picker; then call vm.setAddress(...)
                      vm.setAddress("456 New Street, Anytown, CA 90210");
                    },
                    icon: Icon(
                      Icons.edit_location_alt_outlined,
                      color: Colors.black.withOpacity(0.7),
                    ),
                    label: Text("Change Location", style: t.labelLarge),
                  ),
                ),

                // const SizedBox(height: 12),

                // Row(
                //   children: [
                //     Expanded(
                //       child: Text(
                //         "Geofence Radius",
                //         style: t.bodySmall?.copyWith(
                //           fontWeight: FontWeight.w700,
                //         ),
                //       ),
                //     ),
                //     Text(
                //       "${state.geofenceRadius.round()}m",
                //       style: t.bodySmall?.copyWith(fontWeight: FontWeight.w700),
                //     ),
                //   ],
                // ),

                // SliderTheme(
                //   data: SliderTheme.of(context).copyWith(
                //     activeTrackColor: AppColors.primary,
                //     inactiveTrackColor: Colors.black.withOpacity(0.10),
                //     thumbColor: AppColors.primary,
                //     overlayColor: AppColors.primary.withOpacity(0.10),
                //     trackHeight: 3,
                //   ),
                //   child: Slider(
                //     value: state.geofenceRadius,
                //     min: 50,
                //     max: 2000,
                //     onChanged: vm.setGeofenceRadius,
                //   ),
                // ),
                const SizedBox(height: 8),

                AppTapButton(
                  text: "Submit Profile",
                  isLoading: state.isSavingProfile,
                  onTap: state.isSavingProfile ? null : vm.submitProfileChanges,
                  backgroundColor: AppColors.primary,
                  textColor: AppColors.white,
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // ---------- Menu Builder ----------
          _SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Menu Builder",
                  style: t.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(
                  "Add, edit and delete categories and items.\nSubmit when you're done.",
                  style: t.bodySmall?.copyWith(
                    color: Colors.black.withOpacity(0.55),
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 12),

                // Categories list
                ...state.categories.map(
                  (c) => _CategoryTile(
                    category: c,
                    expanded: state.expandedCategoryId == c.id,
                    onToggle: () => vm.setExpandedCategory(
                      state.expandedCategoryId == c.id ? null : c.id,
                    ),
                    onEdit: () => _editCategoryDialog(context, c, vm),
                    onDelete: () => _confirmDelete(
                      context,
                      title: "Delete category?",
                      message:
                          "This will delete '${c.name}' and all its items.",
                      onYes: () => vm.deleteCategory(c.id),
                    ),
                    onAddItem: () =>
                        _addOrEditItemSheet(context, vm, categoryId: c.id),
                    onEditItem: (item) => _addOrEditItemSheet(
                      context,
                      vm,
                      categoryId: c.id,
                      existing: item,
                    ),
                    onDeleteItem: (item) => _confirmDelete(
                      context,
                      title: "Delete item?",
                      message: "Delete '${item.name}' from '${c.name}'?",
                      onYes: () => vm.deleteItem(c.id, item.id),
                    ),
                  ),
                ),

                // const SizedBox(height: 10),

                // SizedBox(
                //   width: double.infinity,
                //   child: OutlinedButton.icon(
                //     onPressed: () => _addCategoryDialog(context, vm),
                //     icon: const Icon(Icons.add),
                //     label: const Text("Add New Category"),
                //     style: OutlinedButton.styleFrom(
                //       foregroundColor: Colors.black.withOpacity(0.8),
                //       side: BorderSide(color: Colors.black.withOpacity(0.12)),
                //       shape: RoundedRectangleBorder(
                //         borderRadius: BorderRadius.circular(12),
                //       ),
                //     ),
                //   ),
                // ),
                const SizedBox(height: 12),

                AppTapButton(
                  text: "Submit Menu",
                  isLoading: state.isSavingMenu,
                  onTap: state.isSavingMenu ? null : vm.submitMenuChanges,
                  backgroundColor: AppColors.primary,
                  textColor: AppColors.white,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          AppTapButton(
            text: "Log Out",
            onTap: () {
              _confirmLogOut(
                context,
                title: "Log out",
                message:
                    "You will be logged out of the application and need to log in again for using this application. Continue",
                onYes: () {
                  TokenStore.clearTokens();
                  var route = AppRoutes.fade(LoginPage());
                  NavigationService.popAllAndPush(route);
                },
              );
            },
            backgroundColor: AppColors.primary,
            textColor: AppColors.white,
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context, {
    required String title,
    required String message,
    required VoidCallback onYes,
  }) async {
    final t = Theme.of(context).textTheme;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title, style: t.titleLarge),
        content: Text(message, style: t.bodyMedium),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              "Delete",
              style: t.labelLarge?.copyWith(color: AppColors.white),
            ),
          ),
        ],
      ),
    );

    if (ok == true) onYes();
  }

  Future<void> _confirmLogOut(
    BuildContext context, {
    required String title,
    required String message,
    required VoidCallback onYes,
  }) async {
    final t = Theme.of(context).textTheme;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title, style: t.titleLarge),
        content: Text(message, style: t.bodyMedium),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              "Log Out",
              style: t.labelLarge?.copyWith(color: AppColors.white),
            ),
          ),
        ],
      ),
    );

    if (ok == true) onYes();
  }

  Future<void> _addCategoryDialog(
    BuildContext context,
    RestaurantSettingsViewModel vm,
  ) async {
    final t = Theme.of(context).textTheme;
    final c = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("New Category", style: t.titleLarge),
        content: TextField(
          controller: c,
          decoration: const InputDecoration(hintText: "Category name"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              "Add",
              style: t.labelLarge?.copyWith(color: AppColors.white),
            ),
          ),
        ],
      ),
    );

    if (ok == true) vm.addCategory(c.text);
  }

  Future<void> _editCategoryDialog(
    BuildContext context,
    Category category,
    RestaurantSettingsViewModel vm,
  ) async {
    final t = Theme.of(context).textTheme;
    final c = TextEditingController(text: category.name);

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Edit Category", style: t.titleLarge),
        content: TextField(
          controller: c,
          decoration: const InputDecoration(hintText: "Category name"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              "Save",
              style: t.labelLarge?.copyWith(color: AppColors.white),
            ),
          ),
        ],
      ),
    );

    if (ok == true) vm.renameCategory(category.id, c.text);
  }

  Future<void> _addOrEditItemSheet(
    BuildContext context,
    RestaurantSettingsViewModel vm, {
    required int categoryId,
    Item? existing,
  }) async {
    final t = Theme.of(context).textTheme;
    final nameC = TextEditingController(text: existing?.name ?? "");
    final priceC = TextEditingController(
      text: existing?.price.toString() ?? "",
    );
    final durC = TextEditingController(
      text: existing?.expectedDuration.toString() ?? "",
    );
    final descC = TextEditingController(text: existing?.description ?? "");

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final bottom = MediaQuery.of(ctx).viewInsets.bottom;
        return Container(
          padding: EdgeInsets.fromLTRB(16, 10, 16, 16 + bottom),
          decoration: const BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Text(
                    existing == null ? "New Item" : "Edit Item",
                    style: t.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    icon: Icon(
                      Icons.close_rounded,
                      color: Colors.black.withOpacity(0.65),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              _field(ctx, controller: nameC, hint: "Name"),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _field(
                      ctx,
                      controller: priceC,
                      hint: "Price",
                      keyboard: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _field(
                      ctx,
                      controller: durC,
                      hint: "Expected Duration (min)",
                      keyboard: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _field(ctx, controller: descC, hint: "Description (optional)"),
              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    final name = nameC.text.trim();
                    if (name.isEmpty) return;

                    final price = num.tryParse(priceC.text.trim()) ?? 0;
                    final dur = num.tryParse(durC.text.trim()) ?? 0;

                    if (existing == null) {
                      final newItem = Item(
                        id: DateTime.now()
                            .millisecondsSinceEpoch, // temp local id
                        name: name,
                        price: price,
                        expectedDuration: dur,
                        description: descC.text.trim().isEmpty
                            ? null
                            : descC.text.trim(),
                      );
                      vm.addItem(categoryId, newItem);
                    } else {
                      final updated = Item(
                        id: existing.id,
                        name: name,
                        image: existing.image,
                        expectedDuration: dur,
                        price: price,
                        description: descC.text.trim().isEmpty
                            ? null
                            : descC.text.trim(),
                      );
                      vm.updateItem(categoryId, updated);
                    }

                    Navigator.of(ctx).pop();
                  },
                  child: Text(
                    existing == null ? "Add Item" : "Save Changes",
                    style: t.labelLarge?.copyWith(color: AppColors.white),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _field(
    BuildContext context, {
    required TextEditingController controller,
    required String hint,
    TextInputType keyboard = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboard,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFFF7F7F7),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFEAEAEA)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFEAEAEA)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary),
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.category,
    required this.expanded,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
    required this.onAddItem,
    required this.onEditItem,
    required this.onDeleteItem,
  });

  final Category category;
  final bool expanded;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onAddItem;
  final void Function(Item item) onEditItem;
  final void Function(Item item) onDeleteItem;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEAEAEA)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C000000),
            blurRadius: 10,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      category.name,
                      style: t.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Text(
                    "${category.item.length} items",
                    style: t.bodySmall?.copyWith(
                      color: Colors.black.withOpacity(0.55),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // ✅ Animated Chevron Rotation
                  AnimatedRotation(
                    turns: expanded ? 0.5 : 0.0, // 180deg when expanded
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Colors.black.withOpacity(0.55),
                    ),
                  ),

                  PopupMenuButton<String>(
                    onSelected: (v) {
                      if (v == "edit") onEdit();
                      if (v == "delete") onDelete();
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: "edit", child: Text("Edit")),
                      PopupMenuItem(value: "delete", child: Text("Delete")),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ✅ Animated expand/collapse content
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 240),
            reverseDuration: const Duration(milliseconds: 180),
            firstCurve: Curves.easeOutCubic,
            secondCurve: Curves.easeOutCubic,
            crossFadeState: expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox.shrink(),
            secondChild: Column(
              children: [
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                  child: Column(
                    children: [
                      ...category.item.map(
                        (it) => Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF7F7F7),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFEAEAEA)),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  it.name,
                                  style: t.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              Text(
                                "\$${it.price}",
                                style: t.bodySmall?.copyWith(
                                  color: Colors.black.withOpacity(0.6),
                                ),
                              ),
                              const SizedBox(width: 8),
                              InkWell(
                                onTap: () => onEditItem(it),
                                borderRadius: BorderRadius.circular(8),
                                child: Padding(
                                  padding: const EdgeInsets.all(6),
                                  child: Icon(
                                    Icons.edit_outlined,
                                    size: 20,
                                    color: Colors.black.withOpacity(0.65),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              InkWell(
                                onTap: () => onDeleteItem(it),
                                borderRadius: BorderRadius.circular(8),
                                child: const Padding(
                                  padding: EdgeInsets.all(6),
                                  child: Icon(
                                    Icons.delete_outline,
                                    size: 20,
                                    color: Colors.red,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Add item button as a tap container
                      AppTapRowButton(
                        text: "Add Item",
                        icon: Icons.add,
                        onTap: onAddItem,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ImageCircle extends StatelessWidget {
  const _ImageCircle({required this.file, required this.imageUrl});
  final File? file;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    Widget child;

    if (file != null) {
      child = ClipOval(
        child: Image.file(file!, width: 64, height: 64, fit: BoxFit.cover),
      );
    } else if (imageUrl != null && imageUrl!.isNotEmpty) {
      child = ClipOval(
        child: Image.network(
          imageUrl!,
          width: 64,
          height: 64,
          fit: BoxFit.cover,
        ),
      );
    } else {
      child = Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: const Color(0xFFF7F7F7),
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFEAEAEA)),
        ),
        child: Icon(
          Icons.storefront_outlined,
          color: Colors.black.withOpacity(0.45),
        ),
      );
    }

    return SizedBox(width: 64, height: 64, child: child);
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 14,
            offset: Offset(0, 8),
          ),
        ],
        border: Border.all(color: const Color(0xFFEFEFEF)),
      ),
      padding: const EdgeInsets.all(14),
      child: child,
    );
  }
}
