
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/picked_station_location.dart';
import 'station_location_picker_screen.dart';

class StationRegisterScreen extends StatefulWidget {
  const StationRegisterScreen({super.key});

  @override
  State<StationRegisterScreen> createState() => _StationRegisterScreenState();
}

class _StationRegisterScreenState extends State<StationRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();

  // Section A — Owner account
  final _ownerNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();
  String _countryCode = '+962';

  // Section B — Station info
  final _stationNameController = TextEditingController();
  PickedStationLocation? _pickedLocation;

  // Section C — Charger details
  final _chargerCountController = TextEditingController(text: '1');
  double _powerKw = 22.0;
  final Set<String> _connectorTypes = {'Type 2'};

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String? _errorMessage;

  static const _connectors = [
    'Type 1',
    'Type 2',
    'CCS',
    'CHAdeMO',
    'Tesla/NACS',
    'GB/T',
  ];

  @override
  void dispose() {
    _scrollController.dispose();
    _ownerNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    _stationNameController.dispose();
    _chargerCountController.dispose();
    super.dispose();
  }

  // ── Register ───────────────────────────────────────────────────────────────

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) {
      // Scroll to top so user sees first error.
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
      return;
    }

    if (_connectorTypes.isEmpty) {
      setState(() => _errorMessage = 'Select at least one connector type.');
      return;
    }

    if (_pickedLocation == null) {
      setState(() => _errorMessage = 'Pin your station on the map.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 1. Create Firebase Auth user with email + password.
      final credential =
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      final uid = credential.user!.uid;
      final phoneE164 =
          '$_countryCode${_phoneController.text.trim().replaceAll(RegExp(r'[^0-9]'), '')}';

      final firestore = FirebaseFirestore.instance;
      final stationName = _stationNameController.text.trim();
      final location = _pickedLocation!;

      // 2. Write user profile.
      // Matches the fields read by SessionGate.resolveHome() via UserModel:
      //   profile.role.isStation  → role field
      //   profile.stationId       → stationId field
      //   profile.phoneE164       → phoneE164 field
      await firestore.collection('users').doc(uid).set({
        'uid': uid,
        'displayName': _ownerNameController.text.trim(),
        'name': _ownerNameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': phoneE164,
        'phoneE164': phoneE164,
        'role': 'station',
        'stationId': uid,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 3. Write station document (auto-approved when verified on Google Maps).
      await firestore.collection('stations').doc(uid).set({
        'id': uid,
        'ownerId': uid,
        'ownerName': _ownerNameController.text.trim(),
        'ownerEmail': _emailController.text.trim(),
        'ownerPhoneE164': phoneE164,
        'name': stationName,
        'address': location.formattedAddress,
        'status': 'approved',
        'ownerUserId': uid,
        'isPublic': true,
        'latitude': location.latitude,
        'longitude': location.longitude,
        if (location.googlePlaceId != null)
          'googlePlaceId': location.googlePlaceId,
        'chargersCount': int.tryParse(_chargerCountController.text) ?? 1,
        'connectorTypes': _connectorTypes.toList(),
        'powerKw': _powerKw,
        'availablePorts': 1,
        'totalPorts': int.tryParse(_chargerCountController.text) ?? 1,
        'pricePerKwh': 0.42,
        'rating': 0,
        'createdAt': FieldValue.serverTimestamp(),


      });

      // Prevent auth race condition: sign out after registration, then return to login.
      await FirebaseAuth.instance.signOut();

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF00D4FF),
          content: Text(
            'Station registered successfully. Please sign in.',
            style: const TextStyle(color: Colors.black),
          ),
        ),
      );

      Navigator.of(context).pop();
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = _friendlyError(e);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Registration failed. Please try again.';
      });
    }
  }

  String _friendlyError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'An account with this email already exists. Try signing in.';
      case 'invalid-email':
        return 'Invalid email address format.';
      case 'weak-password':
        return 'Password is too weak. Use at least 8 characters.';
      default:
        return e.message ?? 'Registration failed. Please try again.';
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFF080B14),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded,
                color: Color(0xFF5A7FA8), size: 20),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text('Register your station'),
        ),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              controller: _scrollController,
              padding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              children: [
                const SizedBox(height: 8),
                _buildIntro(),
                const SizedBox(height: 32),

                // ── Section A: Owner account ──
                _buildSectionHeader(
                  Icons.person_outline_rounded,
                  'Owner account',
                  'Your personal login credentials',
                ),
                const SizedBox(height: 16),
                _buildOwnerNameField(),
                const SizedBox(height: 14),
                _buildEmailField(),
                const SizedBox(height: 14),
                _buildPasswordField(),
                const SizedBox(height: 14),
                _buildConfirmPasswordField(),
                const SizedBox(height: 14),
                _buildPhoneField(),

                const SizedBox(height: 32),
                const Divider(color: Color(0xFF1A2840), thickness: 0.8),
                const SizedBox(height: 32),

                // ── Section B: Station info ──
                _buildSectionHeader(
                  Icons.ev_station_rounded,
                  'Station details',
                  'Basic information about your station',
                ),
                const SizedBox(height: 16),
                _buildStationNameField(),
                const SizedBox(height: 14),
                _buildLocationPicker(),

                const SizedBox(height: 32),
                const Divider(color: Color(0xFF1A2840), thickness: 0.8),
                const SizedBox(height: 32),

                // ── Section C: Charger details ──
                _buildSectionHeader(
                  Icons.electrical_services_rounded,
                  'Charger information',
                  'Details help drivers find compatible chargers',
                ),
                const SizedBox(height: 16),
                _buildChargerCountField(),
                const SizedBox(height: 20),
                _buildPowerSlider(),
                const SizedBox(height: 20),
                _buildConnectorSelector(),

                const SizedBox(height: 32),
                if (_errorMessage != null) ...[
                  _buildError(),
                  const SizedBox(height: 20),
                ],
                _buildSubmitButton(),
                const SizedBox(height: 32),
                _buildTermsNote(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIntro() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF00D4FF).withAlpha(10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF00D4FF).withAlpha(40),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded,
              color: Color(0xFF00D4FF), size: 18),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Your station will be reviewed by our team after registration. '
                  'You can complete pricing and booking details in your dashboard.',
              style: TextStyle(
                color: Color(0xFF5A7FA8),
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title, String subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFF00D4FF).withAlpha(15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFF00D4FF), size: 18),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFFEEF4FF),
                fontSize: 15,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
            Text(
              subtitle,
              style: const TextStyle(color: Color(0xFF3A5A7A), fontSize: 12),
            ),
          ],
        ),
      ],
    );
  }

  // ── Section A fields ────────────────────────────────────────────────────

  Widget _buildOwnerNameField() {
    return TextFormField(
      controller: _ownerNameController,
      textInputAction: TextInputAction.next,
      textCapitalization: TextCapitalization.words,
      style: const TextStyle(color: Color(0xFFEEF4FF), fontSize: 15),
      decoration: const InputDecoration(
        labelText: 'Full name',
        prefixIcon: Icon(Icons.badge_outlined, color: Color(0xFF2E4060), size: 20),
      ),
      validator: (v) =>
      (v == null || v.trim().isEmpty) ? 'Enter your full name' : null,
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      autocorrect: false,
      style: const TextStyle(color: Color(0xFFEEF4FF), fontSize: 15),
      decoration: const InputDecoration(
        labelText: 'Email address',
        prefixIcon:
        Icon(Icons.mail_outline_rounded, color: Color(0xFF2E4060), size: 20),
      ),
      validator: (v) {
        if (v == null || v.trim().isEmpty) return 'Enter your email';
        if (!v.contains('@')) return 'Enter a valid email address';
        return null;
      },
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      textInputAction: TextInputAction.next,
      style: const TextStyle(color: Color(0xFFEEF4FF), fontSize: 15),
      decoration: InputDecoration(
        labelText: 'Password',
        prefixIcon: const Icon(Icons.lock_outline_rounded,
            color: Color(0xFF2E4060), size: 20),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            color: const Color(0xFF2E4060),
            size: 20,
          ),
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
        ),
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Enter a password';
        if (v.length < 8) return 'Password must be at least 8 characters';
        return null;
      },
    );
  }

  Widget _buildConfirmPasswordField() {
    return TextFormField(
      controller: _confirmPasswordController,
      obscureText: _obscureConfirm,
      textInputAction: TextInputAction.next,
      style: const TextStyle(color: Color(0xFFEEF4FF), fontSize: 15),
      decoration: InputDecoration(
        labelText: 'Confirm password',
        prefixIcon: const Icon(Icons.lock_outline_rounded,
            color: Color(0xFF2E4060), size: 20),
        suffixIcon: IconButton(
          icon: Icon(
            _obscureConfirm
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            color: const Color(0xFF2E4060),
            size: 20,
          ),
          onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
        ),
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Confirm your password';
        if (v != _passwordController.text) return 'Passwords do not match';
        return null;
      },
    );
  }

  Widget _buildPhoneField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Phone number',
          style: TextStyle(color: Color(0xFF8AAAC8), fontSize: 13, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            GestureDetector(
              onTap: () => _showCountryPicker(),
              child: Container(
                height: 54,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D1526),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF1E3A5F)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_countryCode,
                        style: const TextStyle(
                            color: Color(0xFFEEF4FF),
                            fontSize: 14,
                            fontWeight: FontWeight.w500)),
                    const SizedBox(width: 4),
                    const Icon(Icons.keyboard_arrow_down_rounded,
                        color: Color(0xFF2E4060), size: 16),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(12),
                ],
                style: const TextStyle(color: Color(0xFFEEF4FF), fontSize: 15),
                decoration: const InputDecoration(hintText: '7X XXX XXXX'),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Enter phone number';
                  if (v.trim().length < 7) return 'Phone number too short';
                  return null;
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Section B fields ────────────────────────────────────────────────────

  Widget _buildStationNameField() {
    return TextFormField(
      controller: _stationNameController,
      textInputAction: TextInputAction.next,
      textCapitalization: TextCapitalization.words,
      style: const TextStyle(color: Color(0xFFEEF4FF), fontSize: 15),
      decoration: const InputDecoration(
        labelText: 'Station name',
        hintText: 'e.g. Green Energy Station Amman',
        prefixIcon:
        Icon(Icons.ev_station_outlined, color: Color(0xFF2E4060), size: 20),
      ),
      validator: (v) =>
      (v == null || v.trim().isEmpty) ? 'Enter a station name' : null,
    );
  }

  Widget _buildLocationPicker() {
    final loc = _pickedLocation;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Station location',
          style: TextStyle(
            color: Color(0xFF8AAAC8),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Material(
          color: const Color(0xFF0D1526),
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: _openLocationPicker,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: loc != null
                      ? const Color(0xFF00D4FF).withAlpha(80)
                      : const Color(0xFF1E3A5F),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.map_rounded,
                    color: loc != null
                        ? const Color(0xFF00D4FF)
                        : const Color(0xFF2E4060),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      loc?.formattedAddress ??
                          'Tap to pin exact location on map',
                      style: TextStyle(
                        color: loc != null
                            ? const Color(0xFFEEF4FF)
                            : const Color(0xFF5A7FA8),
                        fontSize: 14,
                        height: 1.35,
                      ),
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded,
                      color: Color(0xFF2E4060)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _openLocationPicker() async {
    final picked = await Navigator.of(context).push<PickedStationLocation>(
      MaterialPageRoute<PickedStationLocation>(
        builder: (_) => StationLocationPickerScreen(
          initial: _pickedLocation,
        ),
      ),
    );
    if (picked != null && mounted) {
      setState(() => _pickedLocation = picked);
    }
  }

  // ── Section C fields ────────────────────────────────────────────────────

  Widget _buildChargerCountField() {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: _chargerCountController,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(3),
            ],
            style: const TextStyle(color: Color(0xFFEEF4FF), fontSize: 15),
            decoration: const InputDecoration(
              labelText: 'Number of charge points',
              prefixIcon: Icon(Icons.power_rounded,
                  color: Color(0xFF2E4060), size: 20),
            ),
            validator: (v) {
              final n = int.tryParse(v ?? '');
              if (n == null || n < 1) return 'Enter a valid number (min 1)';
              if (n > 500) return 'Maximum 500 charge points';
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPowerSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Max power per point',
              style: TextStyle(
                  color: Color(0xFF8AAAC8),
                  fontSize: 13,
                  fontWeight: FontWeight.w500),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF00D4FF).withAlpha(15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: const Color(0xFF00D4FF).withAlpha(40), width: 1),
              ),
              child: Text(
                '${_powerKw.toStringAsFixed(0)} kW',
                style: const TextStyle(
                    color: Color(0xFF00D4FF),
                    fontSize: 13,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: const Color(0xFF00D4FF),
            inactiveTrackColor: const Color(0xFF1E3A5F),
            thumbColor: const Color(0xFF00D4FF),
            overlayColor: const Color(0xFF00D4FF).withAlpha(30),
            thumbShape:
            const RoundSliderThumbShape(enabledThumbRadius: 10),
          ),
          child: Slider(
            value: _powerKw,
            min: 3.6,
            max: 350,
            divisions: 20,
            onChanged: (v) => setState(() => _powerKw = v),
          ),
        ),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('3.6 kW (slow)',
                style: TextStyle(color: Color(0xFF2E4060), fontSize: 11)),
            Text('350 kW (ultra-fast)',
                style: TextStyle(color: Color(0xFF2E4060), fontSize: 11)),
          ],
        ),
      ],
    );
  }

  Widget _buildConnectorSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Connector types',
          style: TextStyle(
              color: Color(0xFF8AAAC8),
              fontSize: 13,
              fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _connectors.map((c) {
            final selected = _connectorTypes.contains(c);
            return GestureDetector(
              onTap: () {
                setState(() {
                  if (selected) {
                    _connectorTypes.remove(c);
                  } else {
                    _connectorTypes.add(c);
                  }
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: selected
                      ? const Color(0xFF00D4FF).withAlpha(20)
                      : const Color(0xFF0D1526),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: selected
                        ? const Color(0xFF00D4FF).withAlpha(80)
                        : const Color(0xFF1E3A5F),
                    width: 1,
                  ),
                ),
                child: Text(
                  c,
                  style: TextStyle(
                    color: selected
                        ? const Color(0xFF00D4FF)
                        : const Color(0xFF5A7FA8),
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _register,
      child: _isLoading
          ? const SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF080B14)),
        ),
      )
          : const Text('Register station'),
    );
  }

  Widget _buildError() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFF4D6A).withAlpha(15),
        borderRadius: BorderRadius.circular(10),
        border:
        Border.all(color: const Color(0xFFFF4D6A).withAlpha(50), width: 1),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFFF4D6A), size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(
                  color: Color(0xFFFF4D6A), fontSize: 13, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTermsNote() {
    return const Center(
      child: Text(
        'By registering you agree to Chargix Terms of Service.\n'
            'Your station appears on the map immediately after registration.',
        textAlign: TextAlign.center,
        style: TextStyle(color: Color(0xFF2E4060), fontSize: 11, height: 1.6),
      ),
    );
  }

  void _showCountryPicker() {
    const codes = [
      ('+962', 'Jordan'),
      ('+966', 'Saudi Arabia'),
      ('+971', 'UAE'),
      ('+970', 'Palestine'),
      ('+20', 'Egypt'),
      ('+1', 'USA / Canada'),
      ('+44', 'UK'),
    ];
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF0A0F1C),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
                color: const Color(0xFF2E4060),
                borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 12),
          ...codes.map((c) => ListTile(
            title: Text('${c.$2}  ${c.$1}',
                style: const TextStyle(
                    color: Color(0xFFEEF4FF), fontSize: 14)),
            onTap: () {
              setState(() => _countryCode = c.$1);
              Navigator.pop(context);
            },
          )),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}