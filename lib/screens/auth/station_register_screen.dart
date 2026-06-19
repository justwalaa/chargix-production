import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../models/picked_station_location.dart';
import 'station_location_picker_screen.dart';

const _green        = Color(0xFF22C55E);
const _greenDark    = Color(0xFF16A34A);
const _greenSurface = Color(0xFFDCFCE7);
const _canvas       = Color(0xFFF8F9FA);
const _white        = Color(0xFFFFFFFF);
const _ink          = Color(0xFF101828);
const _slate        = Color(0xFF6B7280);
const _border       = Color(0xFFE5E7EB);

TextStyle _sg(double size, FontWeight w,
    {Color color = _ink, double ls = 0}) =>
    GoogleFonts.spaceGrotesk(
        fontSize: size, fontWeight: w, color: color, letterSpacing: ls);

TextStyle _dm(double size, FontWeight w, {Color color = _ink, double? h}) =>
    GoogleFonts.dmSans(fontSize: size, fontWeight: w, color: color, height: h);

class StationRegisterScreen extends StatefulWidget {
  const StationRegisterScreen({super.key});

  @override
  State<StationRegisterScreen> createState() =>
      _StationRegisterScreenState();
}

class _StationRegisterScreenState extends State<StationRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();

  final _ownerNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();
  String _countryCode = '+962';

  final _stationNameController = TextEditingController();
  PickedStationLocation? _pickedLocation;

  final _chargerCountController = TextEditingController(text: '1');
  double _powerKw = 22.0;
  final Set<String> _connectorTypes = {'Type 2'};

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String? _errorMessage;

  static const _connectors = [
    'Type 1', 'Type 2', 'CCS', 'CHAdeMO', 'Tesla/NACS', 'GB/T',
  ];

  @override
  void dispose() {
    _scrollController.dispose();
    for (final c in [
      _ownerNameController, _emailController, _passwordController,
      _confirmPasswordController, _phoneController,
      _stationNameController, _chargerCountController,
    ]) { c.dispose(); }
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) {
      _scrollController.animateTo(0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut);
      return;
    }
    if (_connectorTypes.isEmpty) {
      setState(
          () => _errorMessage = 'Select at least one connector type.');
      return;
    }
    if (_pickedLocation == null) {
      setState(() => _errorMessage = 'Pin your station on the map.');
      return;
    }

    setState(() { _isLoading = true; _errorMessage = null; });

    try {
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      final uid = credential.user!.uid;
      final phoneE164 =
          '$_countryCode${_phoneController.text.trim().replaceAll(RegExp(r'[^0-9]'), '')}';
      final firestore = FirebaseFirestore.instance;
      final stationName = _stationNameController.text.trim();
      final location = _pickedLocation!;

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
        'chargersCount':
            int.tryParse(_chargerCountController.text) ?? 1,
        'connectorTypes': _connectorTypes.toList(),
        'powerKw': _powerKw,
        'availablePorts': 1,
        'totalPorts':
            int.tryParse(_chargerCountController.text) ?? 1,
        'pricePerKwh': 0.42,
        'rating': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Station registered. Please sign in.',
            style: _dm(13, FontWeight.w500, color: Colors.white),
          ),
          backgroundColor: _greenDark,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
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

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.paddingOf(context).top;
    final bottomPad = MediaQuery.paddingOf(context).bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: _canvas,
        body: Column(
          children: [
            Container(
              color: _white,
              padding: EdgeInsets.fromLTRB(8, topPad + 8, 16, 10),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(PhosphorIconsRegular.arrowLeft,
                        color: _ink, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Expanded(
                    child: Text('Register your station',
                        style: _sg(17, FontWeight.w700)),
                  ),
                ],
              ),
            ),
            Container(height: 0.8, color: _border),

            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  controller: _scrollController,
                  padding: EdgeInsets.fromLTRB(
                      16, 16, 16, 20 + bottomPad),
                  children: [
                    // Info banner
                    _InfoBanner(
                      'Your station will be reviewed after registration. '
                      'Complete pricing and bookings in your dashboard.',
                    ),
                    const SizedBox(height: 20),

                    // ── Owner account ─────────────────────────────────
                    _SectionHeader(
                      icon: PhosphorIconsRegular.userCircle,
                      title: 'Owner account',
                      subtitle: 'Your personal login credentials',
                    ),
                    const SizedBox(height: 14),

                    _FormField(
                      controller: _ownerNameController,
                      label: 'Full name',
                      icon: PhosphorIconsRegular.identificationCard,
                      textCapitalization: TextCapitalization.words,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Enter your full name'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    _FormField(
                      controller: _emailController,
                      label: 'Email address',
                      icon: PhosphorIconsRegular.envelope,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Enter your email';
                        }
                        if (!v.contains('@')) {
                          return 'Enter a valid email address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    _FormField(
                      controller: _passwordController,
                      label: 'Password',
                      icon: PhosphorIconsRegular.lock,
                      obscureText: _obscurePassword,
                      onToggleObscure: () => setState(
                          () => _obscurePassword = !_obscurePassword),
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return 'Enter a password';
                        }
                        if (v.length < 8) {
                          return 'Password must be at least 8 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    _FormField(
                      controller: _confirmPasswordController,
                      label: 'Confirm password',
                      icon: PhosphorIconsRegular.lock,
                      obscureText: _obscureConfirm,
                      onToggleObscure: () => setState(
                          () => _obscureConfirm = !_obscureConfirm),
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return 'Confirm your password';
                        }
                        if (v != _passwordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildPhoneField(),

                    const SizedBox(height: 24),
                    Divider(color: _border),
                    const SizedBox(height: 20),

                    // ── Station info ──────────────────────────────────
                    _SectionHeader(
                      icon: PhosphorIconsRegular.chargingStation,
                      title: 'Station details',
                      subtitle: 'Basic information about your station',
                    ),
                    const SizedBox(height: 14),

                    _FormField(
                      controller: _stationNameController,
                      label: 'Station name',
                      icon: PhosphorIconsRegular.chargingStation,
                      hint: 'e.g. Green Energy Station Amman',
                      textCapitalization: TextCapitalization.words,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty)
                              ? 'Enter a station name'
                              : null,
                    ),
                    const SizedBox(height: 12),
                    _buildLocationPicker(),

                    const SizedBox(height: 24),
                    Divider(color: _border),
                    const SizedBox(height: 20),

                    // ── Charger info ──────────────────────────────────
                    _SectionHeader(
                      icon: PhosphorIconsRegular.plugsConnected,
                      title: 'Charger information',
                      subtitle:
                          'Details help drivers find compatible chargers',
                    ),
                    const SizedBox(height: 14),

                    _FormField(
                      controller: _chargerCountController,
                      label: 'Number of charge points',
                      icon: PhosphorIconsRegular.lightning,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(3),
                      ],
                      validator: (v) {
                        final n = int.tryParse(v ?? '');
                        if (n == null || n < 1) {
                          return 'Enter a valid number (min 1)';
                        }
                        if (n > 500) {
                          return 'Maximum 500 charge points';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildPowerSlider(),
                    const SizedBox(height: 16),
                    _buildConnectorSelector(),

                    if (_errorMessage != null) ...[
                      const SizedBox(height: 16),
                      _ErrorBanner(message: _errorMessage!),
                    ],

                    const SizedBox(height: 24),

                    // Submit
                    GestureDetector(
                      onTap: _isLoading ? null : _register,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        height: 56,
                        decoration: BoxDecoration(
                          color: _isLoading
                              ? const Color(0xFFE5E7EB)
                              : _green,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: _isLoading
                              ? []
                              : [
                                  BoxShadow(
                                    color:
                                        _green.withValues(alpha: 0.32),
                                    blurRadius: 18,
                                    spreadRadius: -4,
                                    offset: const Offset(0, 7),
                                  ),
                                ],
                        ),
                        alignment: Alignment.center,
                        child: _isLoading
                            ? SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(
                                          _green.withValues(alpha: 0.7)),
                                ),
                              )
                            : Text('Register station',
                                style: _sg(15, FontWeight.w700,
                                    color: Colors.white)),
                      ),
                    )
                        .animate()
                        .fadeIn(delay: 40.ms, duration: 280.ms),

                    const SizedBox(height: 16),
                    Center(
                      child: Text(
                        'By registering you agree to Chargix Terms of Service.',
                        textAlign: TextAlign.center,
                        style: _dm(11, FontWeight.w400,
                            color: const Color(0xFFD1D5DB), h: 1.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhoneField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Phone number',
            style: _dm(13, FontWeight.w600, color: _slate)),
        const SizedBox(height: 8),
        Row(
          children: [
            GestureDetector(
              onTap: _showCountryPicker,
              child: Container(
                height: 54,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: _white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _border, width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_countryCode,
                        style:
                            _dm(15, FontWeight.w500)),
                    const SizedBox(width: 4),
                    const Icon(PhosphorIconsRegular.caretDown,
                        color: _slate, size: 14),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(12),
                ],
                style: _dm(15, FontWeight.w500),
                decoration: InputDecoration(
                  hintText: '7X XXX XXXX',
                  hintStyle: _dm(14, FontWeight.w400,
                      color: const Color(0xFFD1D5DB)),
                  filled: true,
                  fillColor: _white,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 14),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide:
                          const BorderSide(color: _border, width: 1)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide:
                          const BorderSide(color: _border, width: 1)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                          color: _green, width: 1.5)),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Enter phone number';
                  }
                  if (v.trim().length < 7) {
                    return 'Phone number too short';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLocationPicker() {
    final loc = _pickedLocation;
    return GestureDetector(
      onTap: _openLocationPicker,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: loc != null ? _green : _border,
            width: loc != null ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(
              PhosphorIconsRegular.mapTrifold,
              size: 18,
              color: loc != null ? _green : _slate,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                loc?.formattedAddress ??
                    'Tap to pin exact location on map',
                style: _dm(14, FontWeight.w400,
                    color: loc != null ? _ink : _slate),
              ),
            ),
            const Icon(PhosphorIconsRegular.caretRight,
                size: 16, color: _slate),
          ],
        ),
      ),
    );
  }

  Future<void> _openLocationPicker() async {
    final picked =
        await Navigator.of(context).push<PickedStationLocation>(
      MaterialPageRoute<PickedStationLocation>(
        builder: (_) =>
            StationLocationPickerScreen(initial: _pickedLocation),
      ),
    );
    if (picked != null && mounted) {
      setState(() => _pickedLocation = picked);
    }
  }

  Widget _buildPowerSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Max power per point',
                style: _dm(13, FontWeight.w600, color: _slate)),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _greenSurface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: _green.withValues(alpha: 0.3), width: 1),
              ),
              child: Text('${_powerKw.toStringAsFixed(0)} kW',
                  style: _dm(13, FontWeight.w700, color: _greenDark)),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: _green,
            inactiveTrackColor: _border,
            thumbColor: _green,
            overlayColor: _green.withValues(alpha: 0.12),
            thumbShape:
                const RoundSliderThumbShape(enabledThumbRadius: 10),
            trackHeight: 4,
          ),
          child: Slider(
            value: _powerKw,
            min: 3.6,
            max: 350,
            divisions: 20,
            onChanged: (v) => setState(() => _powerKw = v),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('3.6 kW (slow)',
                style: _dm(11, FontWeight.w400, color: _slate)),
            Text('350 kW (ultra-fast)',
                style: _dm(11, FontWeight.w400, color: _slate)),
          ],
        ),
      ],
    );
  }

  Widget _buildConnectorSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Connector types',
            style: _dm(13, FontWeight.w600, color: _slate)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _connectors.map((c) {
            final selected = _connectorTypes.contains(c);
            return GestureDetector(
              onTap: () => setState(() {
                if (selected) {
                  _connectorTypes.remove(c);
                } else {
                  _connectorTypes.add(c);
                }
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: selected
                      ? _greenSurface
                      : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: selected ? _green : _border,
                    width: selected ? 1.5 : 1.0,
                  ),
                ),
                child: Text(
                  c,
                  style: _dm(13, FontWeight.w600,
                      color: selected ? _greenDark : _slate),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  void _showCountryPicker() {
    const codes = [
      ('+962', 'Jordan 🇯🇴'),
      ('+966', 'Saudi Arabia 🇸🇦'),
      ('+971', 'UAE 🇦🇪'),
      ('+970', 'Palestine 🇵🇸'),
      ('+20', 'Egypt 🇪🇬'),
      ('+1', 'USA / Canada 🇺🇸'),
      ('+44', 'UK 🇬🇧'),
    ];
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: _white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
                color: _border,
                borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Select country code',
                  style: _sg(15, FontWeight.w700)),
            ),
          ),
          ...codes.map((c) => ListTile(
                leading: Text(c.$1,
                    style: _sg(15, FontWeight.w700, color: _green)),
                title: Text(c.$2,
                    style: _dm(14, FontWeight.w400)),
                onTap: () {
                  setState(() => _countryCode = c.$1);
                  Navigator.pop(context);
                },
              )),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

// ── Section header ────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _greenSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: _green.withValues(alpha: 0.3), width: 1.5),
          ),
          child: Icon(icon, size: 18, color: _greenDark),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: GoogleFonts.spaceGrotesk(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _ink)),
            Text(subtitle,
                style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: _slate)),
          ],
        ),
      ],
    );
  }
}

// ── Form field ────────────────────────────────────────────────────────────────
class _FormField extends StatelessWidget {
  const _FormField({
    required this.controller,
    required this.label,
    required this.icon,
    this.hint,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.obscureText = false,
    this.onToggleObscure,
    this.inputFormatters,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String? hint;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final bool obscureText;
  final VoidCallback? onToggleObscure;
  final List<TextInputFormatter>? inputFormatters;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      obscureText: obscureText,
      inputFormatters: inputFormatters,
      style: GoogleFonts.dmSans(
          fontSize: 15, fontWeight: FontWeight.w500, color: _ink),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.dmSans(
            fontSize: 13, fontWeight: FontWeight.w500, color: _slate),
        hintText: hint,
        hintStyle: GoogleFonts.dmSans(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: const Color(0xFFD1D5DB)),
        prefixIcon: Icon(icon, size: 18, color: _slate),
        suffixIcon: onToggleObscure != null
            ? IconButton(
                icon: Icon(
                  obscureText
                      ? PhosphorIconsRegular.eye
                      : PhosphorIconsRegular.eyeSlash,
                  size: 18,
                  color: _slate,
                ),
                onPressed: onToggleObscure,
              )
            : null,
        filled: true,
        fillColor: _white,
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _border, width: 1)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _border, width: 1)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
                const BorderSide(color: _green, width: 1.5)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
                color: Color(0xFFDC2626), width: 1)),
        focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
                color: Color(0xFFDC2626), width: 1.5)),
      ),
      validator: validator,
    );
  }
}

// ── Info banner ───────────────────────────────────────────────────────────────
class _InfoBanner extends StatelessWidget {
  const _InfoBanner(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _greenSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: _green.withValues(alpha: 0.25), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(PhosphorIconsRegular.info, size: 14,
              color: _greenDark),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: _greenDark,
                    height: 1.5)),
          ),
        ],
      ),
    );
  }
}

// ── Error banner ──────────────────────────────────────────────────────────────
class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: const Color(0xFFDC2626).withValues(alpha: 0.3),
            width: 1),
      ),
      child: Row(
        children: [
          const Icon(PhosphorIconsRegular.warningCircle,
              color: Color(0xFFDC2626), size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message,
                style: GoogleFonts.dmSans(
                    fontSize: 13,
                    color: const Color(0xFFDC2626),
                    height: 1.4)),
          ),
        ],
      ),
    );
  }
}
