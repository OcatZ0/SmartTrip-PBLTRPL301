// Profil wisatawan (F008: Wisatawan dapat mengelola preferensi wisatawan).
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/router/app_routes.dart';
import '../../core/widgets/app_bottom_bar.dart';
import '../../l10n/app_localizations.dart';

const kPrimary = Color(0xFF1B6CB0);
const kBackground = Color(0xFFF4F6FC);
const kTextDark = Color(0xFF14284B);
const kTextGrey = Color(0xFF6B7A90);
const kBorder = Color(0xFFD6DEEA);
const kDanger = Color(0xFFD32F2F);

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final List<String> _allInterests = [
    'Wisata Bahari',
    'Kuliner Seafood',
    'Belanja',
    'Sejarah & Budaya',
    'Alam & Outdoor',
    'Hiburan Malam',
    'Keluarga',
  ];

  final Set<String> _selectedInterests = {
    'Wisata Bahari',
    'Kuliner Seafood',
    'Alam & Outdoor',
  };

  double _interestWeight = 9;
  double _distanceWeight = 8;
  double _budgetWeight = 7;

  String _language = 'ID';

  void _toggleInterest(String interest, bool selected) {
    setState(() {
      if (selected) {
        _selectedInterests.add(interest);
      } else {
        _selectedInterests.remove(interest);
      }
    });
  }

  void _saveSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Pengaturan berhasil disimpan')),
    );
  }

  void _selectTab(AppTab tab) {
    switch (tab) {
      case AppTab.home:
        context.go(AppRoutes.catalog);
      case AppTab.trips:
        context.push(AppRoutes.trips);
      case AppTab.wishlist:
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context).comingSoon)),
          );
      case AppTab.profile:
        break;
    }
  }

  Future<void> _showExitDialog() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Keluar Akun'),
        content: const Text('Apakah kamu yakin ingin keluar dari akun?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Keluar',
              style: TextStyle(color: kDanger, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      context.go(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: kBackground,
      extendBody: true,
      appBar: _buildAppBar(),
      body: ListView(
        padding: EdgeInsets.only(
          bottom:
              AppBottomBar.barHeight +
              AppBottomBar.fabRise +
              16 +
              MediaQuery.paddingOf(context).bottom,
        ),
        children: [
          const _ProfileHeader(
            name: 'Ahmad Rizki',
            email: 'ahmad.rizki@email.com',
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionTitle('Ganti Kata Sandi'),
                const SizedBox(height: 12),
                _buildChangePasswordTile(),
                const SizedBox(height: 24),

                const _SectionTitle('Minat Default'),
                const SizedBox(height: 12),
                _buildInterestChips(),
                const SizedBox(height: 24),
                _buildPriorityCard(),
                const SizedBox(height: 16),
                _buildLanguageCard(),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _saveSettings,
                  style: FilledButton.styleFrom(
                    backgroundColor: kPrimary,
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Simpan Pengaturan',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => _showExitDialog(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: kDanger,
                    backgroundColor: const Color(0xFFFFEBEE),
                    side: const BorderSide(color: kDanger),
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Keluar Akun',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: AppBottomBar(
        current: AppTab.profile,
        onSelect: _selectTab,
        onCreateTrip: () => context.push(AppRoutes.newTrip),
        labels: {
          AppTab.home: l10n.navHome,
          AppTab.wishlist: l10n.navWishlist,
          AppTab.trips: l10n.navTrips,
          AppTab.profile: l10n.navProfile,
        },
        createLabel: l10n.catalogCreateTrip,
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: const Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: Color(0xFFE3F0FA),
            child: Icon(Icons.explore, size: 16, color: kPrimary),
          ),
          SizedBox(width: 8),
          Text(
            'Profil Pengguna',
            style: TextStyle(
              color: kTextDark,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      actions: [
        Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_none, color: kTextDark),
              onPressed: () {},
            ),
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
        const Padding(
          padding: EdgeInsets.only(right: 16, left: 4),
          child: CircleAvatar(
            radius: 16,
            backgroundColor: kBorder,
            child: Icon(Icons.person, size: 18, color: kTextGrey),
          ),
        ),
      ],
    );
  }

  Widget _buildInterestChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _allInterests.map((interest) {
        final isSelected = _selectedInterests.contains(interest);
        return FilterChip(
          label: Text(interest),
          selected: isSelected,
          onSelected: (value) => _toggleInterest(interest, value),
          showCheckmark: true,
          checkmarkColor: kPrimary,
          backgroundColor: Colors.white,
          selectedColor: const Color(0xFFEAF3FB),
          labelStyle: TextStyle(
            color: kTextDark,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
          side: BorderSide(color: isSelected ? kPrimary : kBorder),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPriorityCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Prioritas Default Rute',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: kTextDark,
            ),
          ),
          const SizedBox(height: 16),
          _PrioritySlider(
            title: 'Kesesuaian Minat Wisata',
            value: _interestWeight,
            leftLabel: 'Eksplorasi Acak',
            rightLabel: 'Sesuai Minat',
            onChanged: (v) => setState(() => _interestWeight = v),
          ),
          _PrioritySlider(
            title: 'Jarak / Waktu Perjalanan',
            value: _distanceWeight,
            leftLabel: 'Bebas Keliling',
            rightLabel: 'Paling Cepat',
            onChanged: (v) => setState(() => _distanceWeight = v),
          ),
          _PrioritySlider(
            title: 'Kepatuhan Anggaran',
            value: _budgetWeight,
            leftLabel: 'Fleksibel',
            rightLabel: 'Hemat Cerdas',
            onChanged: (v) => setState(() => _budgetWeight = v),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: _cardDecoration(),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 4),
            child: Text(
              'Bahasa Aplikasi',
              style: TextStyle(fontWeight: FontWeight.bold, color: kTextDark),
            ),
          ),
          SegmentedButton<String>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: 'ID', label: Text('ID')),
              ButtonSegment(value: 'EN', label: Text('EN')),
            ],
            selected: {_language},
            onSelectionChanged: (set) => setState(() => _language = set.first),
            style: SegmentedButton.styleFrom(
              selectedBackgroundColor: kPrimary,
              selectedForegroundColor: Colors.white,
              foregroundColor: kTextGrey,
              side: BorderSide.none,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChangePasswordTile() {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: kBorder),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: _showChangePasswordSheet,
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.lock_outline, color: kPrimary, size: 22),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Ganti Password',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: kTextDark,
                  ),
                ),
              ),
              Icon(Icons.chevron_right, color: kTextGrey),
            ],
          ),
        ),
      ),
    );
  }

  void _showChangePasswordSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true, 
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (_) => const _ChangePasswordSheet(),
    );
  }
}

BoxDecoration _cardDecoration() => BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(12),
  border: Border.all(color: kBorder),
);

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: kTextDark,
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final String name;
  final String email;
  const _ProfileHeader({required this.name, required this.email});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 36,
            backgroundColor: kBorder,
            child: Icon(Icons.person, size: 40, color: kTextGrey),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: kTextDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(email, style: const TextStyle(color: kTextGrey)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChangePasswordSheet extends StatefulWidget {
  const _ChangePasswordSheet();

  @override
  State<_ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<_ChangePasswordSheet> {
  final _formKey = GlobalKey<FormState>();
  final _oldController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _hideOld = true;
  bool _hideNew = true;
  bool _hideConfirm = true;
  bool _submitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _oldController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    try {
      await Future.delayed(const Duration(seconds: 1)); 

      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();
      messenger.showSnackBar(
        const SnackBar(content: Text('Password berhasil diganti')),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _errorMessage = 'Gagal mengganti password. Periksa password lama.';
      });
    }
  }

  InputDecoration _decoration(String label, bool hidden, VoidCallback onToggle) {
    OutlineInputBorder border(Color color) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: color),
        );

    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: kTextGrey, fontSize: 14),
      suffixIcon: IconButton(
        icon: Icon(
          hidden ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          color: kTextGrey,
          size: 20,
        ),
        onPressed: onToggle,
      ),
      enabledBorder: border(kBorder),
      focusedBorder: border(kPrimary),
      errorBorder: border(kDanger),
      focusedErrorBorder: border(kDanger),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        0,
        24,
        24 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Ganti Password',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: kTextDark,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Masukkan password lama untuk verifikasi, lalu buat password baru.',
                style: TextStyle(fontSize: 13, color: kTextGrey),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _oldController,
                obscureText: _hideOld,
                decoration: _decoration(
                  'Password Lama',
                  _hideOld,
                  () => setState(() => _hideOld = !_hideOld),
                ),
                validator: (v) => (v == null || v.isEmpty)
                    ? 'Password lama wajib diisi'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _newController,
                obscureText: _hideNew,
                decoration: _decoration(
                  'Password Baru',
                  _hideNew,
                  () => setState(() => _hideNew = !_hideNew),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Password baru wajib diisi';
                  if (v.length < 8) return 'Minimal 8 karakter';
                  if (v == _oldController.text) {
                    return 'Password baru harus berbeda dari password lama';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmController,
                obscureText: _hideConfirm,
                decoration: _decoration(
                  'Konfirmasi Password Baru',
                  _hideConfirm,
                  () => setState(() => _hideConfirm = !_hideConfirm),
                ),
                validator: (v) =>
                    v != _newController.text ? 'Konfirmasi tidak cocok' : null,
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: kDanger, fontSize: 13),
                ),
              ],
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          _submitting ? null : () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: kTextDark,
                        side: const BorderSide(color: kBorder),
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Batal'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _submitting ? null : _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: kPrimary,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _submitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Simpan',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrioritySlider extends StatelessWidget {
  final String title;
  final double value;
  final String leftLabel;
  final String rightLabel;
  final ValueChanged<double> onChanged;

  const _PrioritySlider({
    required this.title,
    required this.value,
    required this.leftLabel,
    required this.rightLabel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: kTextDark,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F0FA),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${value.round()}/10',
                  style: const TextStyle(
                    color: kPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          Slider(
            value: value,
            min: 0,
            max: 10,
            divisions: 10,
            activeColor: kPrimary,
            inactiveColor: const Color(0xFFDCE6EF),
            onChanged: onChanged,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  leftLabel,
                  style: const TextStyle(fontSize: 11, color: kTextGrey),
                ),
                Text(
                  rightLabel,
                  style: const TextStyle(fontSize: 11, color: kTextGrey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
