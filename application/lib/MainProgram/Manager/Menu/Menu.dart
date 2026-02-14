// RestaurantSettings.dart
import 'dart:io';

import 'package:application/GlobalWidgets/AppTheme/Colors.dart';
import 'package:application/GlobalWidgets/InternetManager/HttpClient.dart';
import 'package:application/GlobalWidgets/NavigationServices/NavigationService.dart';
import 'package:application/GlobalWidgets/NavigationServices/RouteFactory.dart';
import 'package:application/GlobalWidgets/PermissionHandlers/ImagePickerService.dart';
import 'package:application/GlobalWidgets/ReusableComponents/TapContainers.dart';
import 'package:application/GlobalWidgets/Services/Map.dart';
import 'package:application/Handlers/TokenHandler.dart';
import 'package:application/MainProgram/Login/Login.dart';
import 'package:application/MainProgram/Manager/Menu/MenuState.dart';
import 'package:application/MainProgram/Manager/Menu/MenuViewModel.dart';
import 'package:application/SourceDesign/Models/Category.dart';
import 'package:application/SourceDesign/Models/Item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

class RestaurantSettings extends ConsumerStatefulWidget {
  const RestaurantSettings({
    super.key,
    required this.callback,
    required this.restaurantId,
  });

  final VoidCallback callback;
  final int restaurantId;

  @override
  ConsumerState<RestaurantSettings> createState() => _RestaurantSettingsState();
}

class _RestaurantSettingsState extends ConsumerState<RestaurantSettings>
    with AutomaticKeepAliveClientMixin<RestaurantSettings> {
  late final TextEditingController _nameController;
  File? _pickedImage;
  ProviderSubscription<RestaurantSettingsState>? _sub;

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(restaurantSettingsViewModelProvider.notifier)
          .init(widget.restaurantId);
    });

    _sub = ref.listenManual<RestaurantSettingsState>(
      restaurantSettingsViewModelProvider,
      (prev, next) {
        final msg = next.snackBarMessage;
        if (msg != null && msg.isNotEmpty) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(msg)));
          ref.read(restaurantSettingsViewModelProvider.notifier).clearSnack();
        }

        final err = next.errorMessage;
        if (err != null && err.isNotEmpty && err != prev?.errorMessage) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(err)));
        }

        final newName = next.restaurantName ?? "";
        if (_nameController.text != newName) {
          _nameController.text = newName;
          _nameController.selection = TextSelection.collapsed(
            offset: _nameController.text.length,
          );
        }
      },
    );
  }

  @override
  void dispose() {
    _sub?.close();
    _nameController.dispose();
    super.dispose();
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final t = Theme.of(context).textTheme;
    final state = ref.watch(restaurantSettingsViewModelProvider);
    final vm = ref.read(restaurantSettingsViewModelProvider.notifier);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      child: Column(
        children: [
          // ---------- Profile ----------
          _SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Restaurant Profile",
                  style: t.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),

                if (state.isLoadingProfile) ...[
                  const _ProfileShimmer(),
                ] else ...[
                  Row(
                    children: [
                      _ImageCircle(
                        file: state.restaurantImageFile,
                        imageUrl:
                            HttpClient.instanceImage +
                            (state.restaurantImageUrl ?? ""),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final picker = ImagePickerService(context: context);
                            await picker.pickImage();
                            _pickedImage = picker.image;
                            vm.setRestaurantImageFile(picker.image);
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
                    ],
                  ),

                  const SizedBox(height: 12),

                  Text(
                    "Restaurant Name",
                    style: t.bodySmall?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nameController,
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
                            state.currentAddress ?? "",
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
                        var route = AppRoutes.fade(
                          MapBuilder(
                            username: "",
                            callBackFunction: (String address, LatLng loc) {
                              vm.setAddress(address);
                              // keep your original behavior
                              vm.setLocationCoords();
                            },
                          ),
                        );
                        NavigationService.push(route);
                      },
                      icon: Icon(
                        Icons.edit_location_alt_outlined,
                        color: Colors.black.withOpacity(0.7),
                      ),
                      label: Text("Change Location", style: t.labelLarge),
                    ),
                  ),

                  const SizedBox(height: 8),

                  AppTapButton(
                    text: "Submit Profile",
                    isLoading: state.isSavingProfile,
                    onTap: state.isSavingProfile
                        ? null
                        : () async {
                            await vm.submitProfileChanges();

                            // if save succeeded, refresh parent profile
                            // (we can detect success by checking errorMessage / snackBarMessage)
                            final s = ref.read(
                              restaurantSettingsViewModelProvider,
                            );
                            if ((s.errorMessage ?? "").isEmpty) {
                              widget
                                  .callback(); // ✅ this calls getRestaurant() in DashboardManager
                            }
                          },
                    backgroundColor: AppColors.primary,
                    textColor: AppColors.white,
                  ),
                ],
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

                if (state.isLoadingMenu) ...[
                  const _MenuShimmer(count: 3),
                ] else ...[
                  ...state.categories.map(
                    (c) => KeyedSubtree(
                      key: ValueKey('cat_${c.id}'),
                      child: _CategoryTile(
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
                  ),

                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _addCategoryDialog(context, vm),
                      icon: const Icon(Icons.add),
                      label: const Text("Add New Category"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.black.withOpacity(0.8),
                        side: BorderSide(color: Colors.black.withOpacity(0.12)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  AppTapButton(
                    text: "Submit Menu",
                    isLoading: state.isSavingMenu,
                    onTap: state.isSavingMenu ? null : vm.submitMenuChanges,
                    backgroundColor: AppColors.primary,
                    textColor: AppColors.white,
                  ),
                ],
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
                  final route = AppRoutes.fade(LoginPage());
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

  // ---------------- dialogs / helpers ----------------

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

    if (ok == true) {
      final name = c.text.trim();
      if (name.isEmpty) {
        _toast("Category name cannot be empty.");
        return;
      }
      vm.addCategory(name);
    }
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

    if (ok == true) {
      final name = c.text.trim();
      if (name.isEmpty) {
        _toast("Category name cannot be empty.");
        return;
      }
      vm.renameCategory(category.id, name);
    }
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
              _field(ctx, controller: descC, hint: "Description"),
              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    final name = nameC.text.trim();
                    final desc = descC.text.trim();
                    final priceText = priceC.text.trim();
                    final durText = durC.text.trim();

                    if (name.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Item name cannot be empty."),
                        ),
                      );
                      return;
                    }
                    if (desc.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Description is required."),
                        ),
                      );
                      return;
                    }

                    final price = num.tryParse(priceText);
                    if (price == null || price <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Price must be greater than 0."),
                        ),
                      );
                      return;
                    }

                    final dur = num.tryParse(durText);
                    if (dur == null || dur <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Duration must be greater than 0."),
                        ),
                      );
                      return;
                    }

                    if (existing == null) {
                      final newItem = Item(
                        id: DateTime.now().millisecondsSinceEpoch,
                        name: name,
                        price: price,
                        expectedDuration: dur,
                        description: desc,
                      );
                      vm.addItem(categoryId, newItem);
                    } else {
                      final updated = Item(
                        id: existing.id,
                        name: name,
                        image: existing.image,
                        expectedDuration: dur,
                        price: price,
                        description: desc,
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
                  AnimatedRotation(
                    turns: expanded ? 0.5 : 0.0,
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

// ---------- Shimmer (no package) ----------

class _Shimmer extends StatefulWidget {
  const _Shimmer({
    required this.child,
    this.period = const Duration(milliseconds: 1200),
  });
  final Widget child;
  final Duration period;

  @override
  State<_Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<_Shimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: widget.period)..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = Colors.black.withOpacity(0.06);
    final highlight = Colors.black.withOpacity(0.14);

    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (rect) {
            final t = _c.value;
            final dx = rect.width * (t * 2 - 1);
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [base, highlight, base],
              stops: const [0.1, 0.5, 0.9],
              transform: _SlidingGradientTransform(dx),
            ).createShader(rect);
          },
          child: widget.child,
        );
      },
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  const _SlidingGradientTransform(this.slideX);
  final double slideX;

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(slideX, 0.0, 0.0);
  }
}

class _Skel extends StatelessWidget {
  const _Skel({
    this.h = 12,
    this.w,
    this.r = 12,
    this.shape = BoxShape.rectangle,
  });
  final double h;
  final double? w;
  final double r;
  final BoxShape shape;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.08),
        shape: shape,
        borderRadius: shape == BoxShape.circle
            ? null
            : BorderRadius.circular(r),
      ),
    );
  }
}

class _ProfileShimmer extends StatelessWidget {
  const _ProfileShimmer();

  @override
  Widget build(BuildContext context) {
    return _Shimmer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _Skel(h: 18, w: 170, r: 8),
          SizedBox(height: 14),
          Row(
            children: [
              _Skel(h: 64, w: 64, shape: BoxShape.circle),
              SizedBox(width: 12),
              Expanded(child: _Skel(h: 44, r: 12)),
            ],
          ),
          SizedBox(height: 14),
          _Skel(h: 12, w: 120, r: 8),
          SizedBox(height: 10),
          _Skel(h: 48, r: 12),
          SizedBox(height: 18),
          _Skel(h: 14, w: 140, r: 8),
          SizedBox(height: 10),
          _Skel(h: 12, w: 220, r: 8),
          SizedBox(height: 6),
          _Skel(h: 12, w: 200, r: 8),
          SizedBox(height: 14),
          _Skel(h: 12, w: 120, r: 8),
          SizedBox(height: 10),
          _Skel(h: 46, r: 12),
          SizedBox(height: 14),
          Align(alignment: Alignment.center, child: _Skel(h: 18, w: 160, r: 8)),
          SizedBox(height: 16),
          _Skel(h: 46, r: 12),
        ],
      ),
    );
  }
}

class _MenuShimmer extends StatelessWidget {
  const _MenuShimmer({this.count = 3});
  final int count;

  @override
  Widget build(BuildContext context) {
    return _Shimmer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Skel(h: 18, w: 140, r: 8),
          const SizedBox(height: 10),
          const _Skel(h: 12, w: 260, r: 8),
          const SizedBox(height: 6),
          const _Skel(h: 12, w: 220, r: 8),
          const SizedBox(height: 14),
          ...List.generate(count, (i) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                padding: const EdgeInsets.all(12),
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
                child: Row(
                  children: const [
                    Expanded(child: _Skel(h: 14, w: 160, r: 8)),
                    SizedBox(width: 12),
                    _Skel(h: 12, w: 60, r: 8),
                    SizedBox(width: 12),
                    _Skel(h: 18, w: 18, r: 6),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 4),
          const _Skel(h: 44, r: 12),
          const SizedBox(height: 12),
          const _Skel(h: 46, r: 12),
        ],
      ),
    );
  }
}
