import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taler_id_mobile/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/widgets.dart';
import '../../../../core/utils/countries.dart';
import '../../../../core/utils/error_keys.dart';
import '../bloc/profile_bloc.dart';
import '../bloc/profile_event.dart';
import '../bloc/profile_state.dart';
import '../../domain/entities/user_entity.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _middleNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();
  final _countryCtrl = TextEditingController();
  final _statusCtrl = TextEditingController();
  final _aiTwinPromptCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? _selectedCountry;
  DateTime? _dateOfBirth;
  bool _initialized = false;
  bool _aiTwinEnabled = false;
  int _aiTwinTimeoutSeconds = 30;

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _middleNameCtrl.dispose();
    _phoneCtrl.dispose();
    _dateCtrl.dispose();
    _countryCtrl.dispose();
    _statusCtrl.dispose();
    _aiTwinPromptCtrl.dispose();
    super.dispose();
  }

  void _initialize(UserEntity user) {
    if (_initialized) return;
    _firstNameCtrl.text = user.firstName ?? '';
    _lastNameCtrl.text = user.lastName ?? '';
    _middleNameCtrl.text = user.middleName ?? '';
    _phoneCtrl.text = user.phone ?? '';
    _selectedCountry = user.country;
    if (_selectedCountry != null) {
      final locale = Localizations.localeOf(context).languageCode;
      _countryCtrl.text = countryName(_selectedCountry, locale) ?? _selectedCountry!;
    }
    if (user.dateOfBirth != null) {
      _dateOfBirth = DateTime.tryParse(user.dateOfBirth!);
      if (_dateOfBirth != null) {
        _dateCtrl.text = _formatDate(_dateOfBirth!);
      }
    }
    _statusCtrl.text = user.status ?? '';
    _aiTwinEnabled = user.aiTwinEnabled;
    _aiTwinTimeoutSeconds = user.aiTwinTimeoutSeconds;
    _aiTwinPromptCtrl.text = user.aiTwinPrompt ?? '';
    _initialized = true;
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(2000, 1, 1),
      firstDate: DateTime(1920),
      lastDate: now,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.dark(
            primary: AppColors.of(context).primary,
            onPrimary: Colors.white,
            surface: AppColors.of(context).card,
            onSurface: AppColors.of(context).textPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _dateOfBirth = picked;
        _dateCtrl.text = _formatDate(picked);
      });
    }
  }

  void _showCountryPicker() {
    final locale = Localizations.localeOf(context).languageCode;
    final l10n = AppLocalizations.of(context)!;
    final searchCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.of(context).card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (ctx, scrollController) => StatefulBuilder(
          builder: (ctx, setModalState) {
            final query = searchCtrl.text.toLowerCase();
            final filtered = allCountries.where((c) {
              if (query.isEmpty) return true;
              return c.nameEn.toLowerCase().contains(query) ||
                  c.nameRu.toLowerCase().contains(query) ||
                  c.code.toLowerCase().contains(query);
            }).toList();

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                  child: Text(
                    l10n.country,
                    style: TextStyle(
                      color: AppColors.of(context).textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: TextField(
                    controller: searchCtrl,
                    style: TextStyle(color: AppColors.of(context).textPrimary),
                    decoration: InputDecoration(
                      hintText: l10n.search,
                      hintStyle: TextStyle(color: AppColors.of(context).textSecondary),
                      prefixIcon: Icon(Icons.search, color: AppColors.of(context).textSecondary),
                      filled: true,
                      fillColor: AppColors.of(context).background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (_) => setModalState(() {}),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: filtered.length,
                    itemBuilder: (_, i) {
                      final country = filtered[i];
                      final isSelected = country.code == _selectedCountry;
                      return ListTile(
                        title: Text(
                          country.name(locale),
                          style: TextStyle(
                            color: isSelected ? AppColors.of(context).primary : AppColors.of(context).textPrimary,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                        trailing: isSelected
                            ? Icon(Icons.check, color: AppColors.of(context).primary, size: 20)
                            : Text(
                                country.code,
                                style: TextStyle(color: AppColors.of(context).textSecondary, fontSize: 13),
                              ),
                        onTap: () {
                          setState(() {
                            _selectedCountry = country.code;
                            _countryCtrl.text = country.name(locale);
                          });
                          Navigator.pop(ctx);
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildAiTwinSection(BuildContext context, AppLocalizations l10n) {
    final colors = AppColors.of(context);
    return Container(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border, width: 1),
      ),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 4),
            child: Row(
              children: [
                Icon(Icons.smart_toy_outlined, color: colors.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  l10n.aiTwinSection,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              l10n.aiTwinEnabled,
              style: TextStyle(color: colors.textPrimary, fontSize: 15),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                l10n.aiTwinEnabledDesc,
                style: TextStyle(color: colors.textSecondary, fontSize: 12),
              ),
            ),
            value: _aiTwinEnabled,
            activeColor: colors.primary,
            onChanged: (v) => setState(() => _aiTwinEnabled = v),
          ),
          if (_aiTwinEnabled) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.aiTwinTimeout,
                  style: TextStyle(color: colors.textPrimary, fontSize: 14),
                ),
                Text(
                  l10n.aiTwinTimeoutValue(_aiTwinTimeoutSeconds),
                  style: TextStyle(color: colors.primary, fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: colors.primary,
                inactiveTrackColor: colors.border,
                thumbColor: colors.primary,
                overlayColor: colors.primary.withOpacity(0.2),
              ),
              child: Slider(
                value: _aiTwinTimeoutSeconds.toDouble(),
                min: 15,
                max: 60,
                divisions: 9,
                onChanged: (v) => setState(() => _aiTwinTimeoutSeconds = v.round()),
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _aiTwinPromptCtrl,
              maxLines: 4,
              maxLength: 2000,
              style: TextStyle(color: colors.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                labelText: l10n.aiTwinPrompt,
                hintText: l10n.aiTwinPromptHint,
                hintStyle: TextStyle(color: colors.textSecondary, fontSize: 13),
                alignLabelWithHint: true,
                counterStyle: TextStyle(color: colors.textSecondary),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, size: 14, color: colors.textSecondary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    l10n.aiTwinComingSoon,
                    style: TextStyle(color: colors.textSecondary, fontSize: 11),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.of(context).background,
      appBar: AppBar(
        title: Text(l10n.editProfile),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: AppColors.of(context).textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: BlocConsumer<ProfileBloc, ProfileState>(
        listener: (context, state) {
          if (state is ProfileLoaded && _initialized) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.profileUpdated), backgroundColor: AppColors.of(context).primary),
            );
            context.pop();
          } else if (state is ProfileError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(resolveErrorMessage(l10n, state.message)), backgroundColor: AppColors.of(context).error),
            );
          }
        },
        builder: (context, state) {
          final user = state is ProfileLoaded
              ? state.user
              : state is ProfileUpdating
                  ? state.user
                  : null;

          if (user != null) _initialize(user);
          final loading = state is ProfileUpdating;
          final kycDone = user?.kycStatus == KycStatus.verified;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _firstNameCtrl,
                    readOnly: kycDone,
                    style: TextStyle(color: kycDone ? AppColors.of(context).textSecondary : AppColors.of(context).textPrimary),
                    decoration: InputDecoration(
                      labelText: l10n.firstName,
                      suffixIcon: kycDone ? Icon(Icons.lock_outline, size: 16, color: AppColors.of(context).textSecondary) : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _lastNameCtrl,
                    readOnly: kycDone,
                    style: TextStyle(color: kycDone ? AppColors.of(context).textSecondary : AppColors.of(context).textPrimary),
                    decoration: InputDecoration(
                      labelText: l10n.lastName,
                      suffixIcon: kycDone ? Icon(Icons.lock_outline, size: 16, color: AppColors.of(context).textSecondary) : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _middleNameCtrl,
                    readOnly: kycDone,
                    style: TextStyle(color: kycDone ? AppColors.of(context).textSecondary : AppColors.of(context).textPrimary),
                    decoration: InputDecoration(
                      labelText: l10n.editProfilePatronymic,
                      suffixIcon: kycDone ? Icon(Icons.lock_outline, size: 16, color: AppColors.of(context).textSecondary) : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: _pickDate,
                    child: AbsorbPointer(
                      child: TextFormField(
                        controller: _dateCtrl,
                        style: TextStyle(color: AppColors.of(context).textPrimary),
                        decoration: InputDecoration(
                          labelText: l10n.dateOfBirth,
                          prefixIcon: Icon(Icons.calendar_today_outlined, color: AppColors.of(context).textSecondary),
                          hintText: 'DD.MM.YYYY',
                          hintStyle: TextStyle(color: AppColors.of(context).textSecondary),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    style: TextStyle(color: AppColors.of(context).textPrimary),
                    decoration: InputDecoration(
                      labelText: l10n.phone,
                      prefixIcon: Icon(Icons.phone_outlined, color: AppColors.of(context).textSecondary),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _statusCtrl,
                    style: TextStyle(color: AppColors.of(context).textPrimary),
                    maxLength: 70,
                    decoration: InputDecoration(
                      labelText: 'Статус',
                      hintText: 'Что у вас нового?',
                      hintStyle: TextStyle(color: AppColors.of(context).textSecondary),
                      prefixIcon: Icon(Icons.mood_outlined, color: AppColors.of(context).textSecondary),
                      counterStyle: TextStyle(color: AppColors.of(context).textSecondary),
                    ),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: _showCountryPicker,
                    child: AbsorbPointer(
                      child: TextFormField(
                        controller: _countryCtrl,
                        style: TextStyle(color: AppColors.of(context).textPrimary),
                        decoration: InputDecoration(
                          labelText: l10n.country,
                          prefixIcon: Icon(Icons.flag_outlined, color: AppColors.of(context).textSecondary),
                          suffixIcon: Icon(Icons.arrow_drop_down, color: AppColors.of(context).textSecondary),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  _buildAiTwinSection(context, l10n),
                  const SizedBox(height: 32),
                  LoadingButton(
                    text: l10n.save,
                    loading: loading,
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        final data = <String, dynamic>{
                          'firstName': _firstNameCtrl.text.trim(),
                          'lastName': _lastNameCtrl.text.trim(),
                          'middleName': _middleNameCtrl.text.trim(),
                          'status': _statusCtrl.text.trim(),
                          if (_phoneCtrl.text.trim().isNotEmpty) 'phone': _phoneCtrl.text.trim(),
                          if (_selectedCountry != null) 'country': _selectedCountry,
                          if (_dateOfBirth != null) 'dateOfBirth': _dateOfBirth!.toIso8601String().split('T').first,
                          'aiTwinEnabled': _aiTwinEnabled,
                          'aiTwinTimeoutSeconds': _aiTwinTimeoutSeconds,
                          'aiTwinPrompt': _aiTwinPromptCtrl.text.trim().isEmpty
                              ? null
                              : _aiTwinPromptCtrl.text.trim(),
                        };
                        context.read<ProfileBloc>().add(ProfileUpdateSubmitted(data));
                      }
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
