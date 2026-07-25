import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/neo_brutal_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/category_model.dart';
import '../../data/repositories/category_repo.dart';
import '../../shared/widgets/neo_card.dart';
import '../../shared/widgets/neo_button.dart';
import '../../shared/widgets/neo_text_field.dart';
import '../../shared/widgets/catat_in_app_bar.dart';
import '../../shared/widgets/dot_pattern_background.dart';

class CategoryManagementScreen extends StatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  State<CategoryManagementScreen> createState() =>
      _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen> {
  List<CategoryModel> _categories = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final cats = await CategoryRepo().getAll();
    setState(() {
      _categories = cats;
      _loading = false;
    });
  }

  void _openForm({CategoryModel? edit}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: NeoBrutalColors.ink.withValues(alpha: 0.5),
      builder: (_) => _CategoryFormSheet(
        category: edit,
        onSaved: () {
          Navigator.pop(context);
          _load();
        },
      ),
    );
  }

  Future<void> _confirmDelete(CategoryModel cat) async {
    final repo = CategoryRepo();
    final count = await repo.countTransactions(cat.id);

    if (!mounted) return;

    if (count > 0) {
      // Category is in use — block deletion
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('TIDAK BISA DIHAPUS'),
          content: Text(
            'Kategori "${cat.name}" masih dipakai di $count transaksi.\n\n'
            'Hapus atau pindahkan transaksi terkait terlebih dahulu.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('HAPUS KATEGORI?'),
        content: Text('Kategori "${cat.name}" akan dihapus permanen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('BATAL'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await repo.delete(cat.id);
              HapticFeedback.mediumImpact();
              _load();
            },
            child: const Text(
              'HAPUS',
              style: TextStyle(color: NeoBrutalColors.danger),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final bgColor = brightness == Brightness.dark
        ? NeoBrutalColors.bgDark
        : NeoBrutalColors.bg;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: const CatatInAppBar(subtitle: 'Kelola Kategori'),
      body: DotPatternBackground(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildSection('PENGELUARAN', CategoryType.expense),
                  const SizedBox(height: 24),
                  _buildSection('PEMASUKAN', CategoryType.income),
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: NeoBrutalColors.yellow,
        onPressed: () => _openForm(),
        child: const Icon(Icons.add_rounded, color: NeoBrutalColors.ink),
      ),
    );
  }

  Widget _buildSection(String title, CategoryType type) {
    final cats = _categories.where((c) => c.type == type).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 20,
              color: type == CategoryType.expense
                  ? NeoBrutalColors.danger
                  : NeoBrutalColors.success,
            ),
            const SizedBox(width: 10),
            Text(
              title,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...cats.map(
          (cat) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: NeoCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              onTap: () => _openForm(edit: cat),
              borderOffset: AppConstants.shadowSmall,
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Color.alphaBlend(
                        cat.colorValue.withValues(alpha: 0.15),
                        NeoBrutalColors.surface,
                      ),
                      border: Border.all(color: cat.colorValue, width: 2),
                    ),
                    child: Icon(
                      Icons.category_rounded,
                      size: 18,
                      color: cat.colorValue,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      cat.name,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      size: 20,
                      color: NeoBrutalColors.danger,
                    ),
                    onPressed: () => _confirmDelete(cat),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CategoryFormSheet extends StatefulWidget {
  const _CategoryFormSheet({this.category, required this.onSaved});
  final CategoryModel? category;
  final VoidCallback onSaved;

  @override
  State<_CategoryFormSheet> createState() => _CategoryFormSheetState();
}

class _CategoryFormSheetState extends State<_CategoryFormSheet> {
  final _nameController = TextEditingController();
  CategoryType _type = CategoryType.expense;
  int _color = NeoBrutalColors.primary.toARGB32();

  static const _presetColors = [
    0xFFFF6B35,
    0xFF4361EE,
    0xFF06D6A0,
    0xFFB5179E,
    0xFFFFD60A,
    0xFF00D9FF,
    0xFFFF9F1C,
    0xFFEF476F,
    0xFFE5E5E5,
    0xFF1A1A1A,
  ];

  @override
  void initState() {
    super.initState();
    if (widget.category != null) {
      final c = widget.category!;
      _nameController.text = c.name;
      _type = c.type;
      _color = c.color;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Nama tidak boleh kosong')));
      return;
    }
    if (name.length > 30) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama maksimal 30 karakter')),
      );
      return;
    }

    final repo = CategoryRepo();

    // Check duplicate name (case-insensitive, same type)
    final all = await repo.getAll();
    final duplicate = all.any(
      (c) =>
          c.name.toLowerCase() == name.toLowerCase() &&
          c.type == _type &&
          c.id != widget.category?.id,
    );
    if (duplicate) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kategori dengan nama ini sudah ada')),
        );
      }
      return;
    }

    if (widget.category != null) {
      await repo.update(
        CategoryModel(
          id: widget.category!.id,
          name: name,
          type: _type,
          icon: widget.category!.icon,
          color: _color,
        ),
      );
    } else {
      await repo.insert(
        CategoryModel(
          id: repo.newId(),
          name: name,
          type: _type,
          icon: 'category',
          color: _color,
        ),
      );
    }

    HapticFeedback.mediumImpact();
    widget.onSaved();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.category != null;
    final brightness = Theme.of(context).brightness;
    final borderColor = brightness == Brightness.dark
        ? NeoBrutalColors.darkLine
        : NeoBrutalColors.ink;
    final labelColor = brightness == Brightness.dark
        ? NeoBrutalColors.inkDark.withValues(alpha: 0.7)
        : NeoBrutalColors.ink.withValues(alpha: 0.7);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        decoration: BoxDecoration(
          color: brightness == Brightness.dark
              ? NeoBrutalColors.bgDark
              : NeoBrutalColors.bg,
          border: Border(
            top: BorderSide(
              color: borderColor,
              width: AppConstants.borderPrimary,
            ),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isEdit ? 'EDIT KATEGORI' : 'TAMBAH KATEGORI',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 20),
            NeoTextField(
              controller: _nameController,
              label: 'Nama Kategori',
              hint: 'Contoh: Makanan',
            ),
            const SizedBox(height: 16),
            Text(
              'TIPE',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
                color: labelColor,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _TypeChip(
                  label: 'Pengeluaran',
                  selected: _type == CategoryType.expense,
                  onTap: () => setState(() => _type = CategoryType.expense),
                ),
                const SizedBox(width: 8),
                _TypeChip(
                  label: 'Pemasukan',
                  selected: _type == CategoryType.income,
                  onTap: () => setState(() => _type = CategoryType.income),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'WARNA',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
                color: labelColor,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _presetColors.map((c) {
                final selected = _color == c;
                final isLightColor =
                    ThemeData.estimateBrightnessForColor(Color(c)) ==
                    Brightness.light;
                final borderColor =
                    Theme.of(context).brightness == Brightness.dark
                    ? NeoBrutalColors.darkLine
                    : NeoBrutalColors.ink;
                return GestureDetector(
                  onTap: () => setState(() => _color = c),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Color(c),
                      border: Border.all(
                        color: selected
                            ? borderColor
                            : borderColor.withValues(alpha: 0.25),
                        width: selected ? 3 : 1.5,
                      ),
                      boxShadow: selected
                          ? [
                              BoxShadow(
                                color: borderColor,
                                offset: const Offset(2, 2),
                                blurRadius: 0,
                              ),
                            ]
                          : null,
                    ),
                    child: selected
                        ? Icon(
                            Icons.check_rounded,
                            size: 18,
                            color: isLightColor
                                ? NeoBrutalColors.ink
                                : Colors.white,
                          )
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: NeoButton(
                label: isEdit ? 'SIMPAN PERUBAHAN' : 'TAMBAH KATEGORI',
                icon: Icons.check_circle_outline_rounded,
                color: NeoBrutalColors.success,
                onTap: _save,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final borderColor = brightness == Brightness.dark
        ? NeoBrutalColors.darkLine
        : NeoBrutalColors.ink;
    final inactiveBg = brightness == Brightness.dark
        ? NeoBrutalColors.surfaceDark
        : NeoBrutalColors.surface;
    final textColor = brightness == Brightness.dark
        ? NeoBrutalColors.inkDark
        : NeoBrutalColors.ink;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? NeoBrutalColors.yellow : inactiveBg,
          border: Border.all(color: borderColor, width: selected ? 3 : 2),
        ),
        child: Text(
          label.toUpperCase(),
          style: GoogleFonts.spaceGrotesk(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w900 : FontWeight.w600,
            letterSpacing: 0.5,
            color: selected ? NeoBrutalColors.ink : textColor,
          ),
        ),
      ),
    );
  }
}
