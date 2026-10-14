

/// Profil wisatawan (F008: Wisatawan dapat mengelola preferensi wisatawan).
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
  int _navIndex = 3; 

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      appBar: _buildAppBar(),
      body: ListView(
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
                const _SectionTitle('Cara Login'),
                const SizedBox(height: 12),
                const Row(
                  children: [
                    Expanded(
                      child: _LoginMethodCard(
                        icon: Icons.lock_outline,
                        title: 'Password',
                        status: 'Aktif',
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: _LoginMethodCard(
                        icon: Icons.cancel_outlined,
                        title: 'Google',
                        status: 'Tersambung',
                      ),
                    ),
                  ],
                ),
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
                  onPressed: () => context.go('/login'),
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
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: kTextDark),
        onPressed: () => context.canPop() ? context.pop() : context.go('/home'),
      ),
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
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: kTextDark,
              ),
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

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: _navIndex,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: kPrimary,
      unselectedItemColor: kTextGrey,
      selectedFontSize: 12,
      unselectedFontSize: 12,
      onTap: (index) => setState(() => _navIndex = index),
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(
            icon: Icon(Icons.favorite_border), label: 'Wishlist'),
        BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'Trip Saya'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
      ],
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

class _LoginMethodCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String status;
  const _LoginMethodCard({
    required this.icon,
    required this.title,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Icon(icon, color: kPrimary, size: 22),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: kTextDark,
                ),
              ),
              Text(
                status,
                style: const TextStyle(fontSize: 11, color: kTextGrey),
              ),
            ],
          ),
        ],
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
                Text(leftLabel,
                    style: const TextStyle(fontSize: 11, color: kTextGrey)),
                Text(rightLabel,
                    style: const TextStyle(fontSize: 11, color: kTextGrey)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}