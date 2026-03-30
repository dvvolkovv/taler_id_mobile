import 'package:flutter/material.dart';
import 'package:taler_id_mobile/l10n/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/widgets.dart';
import '../../domain/entities/sumsub_applicant_entity.dart';

class SumsubDataCard extends StatelessWidget {
  final SumsubApplicantEntity data;
  const SumsubDataCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = AppColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Personal info
        if (data.info != null) ...[
          _sectionTitle(l10n.verifiedPersonalInfo, colors),
          const SizedBox(height: 8),
          AppCard(
            child: Column(
              children: _buildPersonInfoRows(data.info!, l10n, colors),
            ),
          ),
          const SizedBox(height: 16),
        ],
        // Documents
        if (data.idDocs.isNotEmpty) ...[
          _sectionTitle(l10n.documents, colors),
          const SizedBox(height: 8),
          ...data.idDocs.map((doc) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: AppCard(
                  child: Column(
                    children: _buildDocRows(doc, l10n, colors),
                  ),
                ),
              )),
        ],
        // Addresses
        if (data.addresses.isNotEmpty) ...[
          _sectionTitle(l10n.address, colors),
          const SizedBox(height: 8),
          ...data.addresses.map((addr) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: AppCard(
                  child: Text(
                    _formatAddress(addr, l10n),
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ),
              )),
        ],
      ],
    );
  }

  Widget _sectionTitle(String title, AppColorsExtension colors) {
    return Text(
      title,
      style: TextStyle(
        color: colors.textPrimary,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  List<Widget> _buildPersonInfoRows(SumsubPersonInfo info, AppLocalizations l10n, AppColorsExtension colors) {
    final rows = <_FieldData>[];
    if (info.lastName != null) rows.add(_FieldData(l10n.lastName, info.lastName!));
    if (info.firstName != null) rows.add(_FieldData(l10n.firstName, info.firstName!));
    if (info.middleName != null) rows.add(_FieldData(l10n.middleName, info.middleName!));
    if (info.dob != null) rows.add(_FieldData(l10n.dateOfBirth, _formatDate(info.dob!)));
    if (info.placeOfBirth != null) rows.add(_FieldData(l10n.placeOfBirth, info.placeOfBirth!));
    if (info.nationality != null) rows.add(_FieldData(l10n.nationality, info.nationality!));
    if (info.gender != null) {
      final genderLabel = info.gender == 'M' ? l10n.genderMale : l10n.genderFemale;
      rows.add(_FieldData(l10n.gender, genderLabel));
    }
    if (info.country != null) rows.add(_FieldData(l10n.country, info.country!));

    return _buildInfoRowWidgets(rows, colors);
  }

  List<Widget> _buildDocRows(SumsubIdDoc doc, AppLocalizations l10n, AppColorsExtension colors) {
    final rows = <_FieldData>[];
    if (doc.idDocType != null) rows.add(_FieldData(l10n.documentType, _docTypeName(doc.idDocType!, l10n)));
    if (doc.number != null) rows.add(_FieldData(l10n.docNumber, doc.number!));
    if (doc.firstName != null || doc.lastName != null) {
      final name = [doc.lastName, doc.firstName].where((s) => s != null).join(' ');
      rows.add(_FieldData(l10n.firstName, name));
    }
    if (doc.issuedDate != null) rows.add(_FieldData(l10n.docIssuedDate, _formatDate(doc.issuedDate!)));
    if (doc.validUntil != null) rows.add(_FieldData(l10n.docValidUntil, _formatDate(doc.validUntil!)));
    if (doc.issuedBy != null) rows.add(_FieldData(l10n.docIssuedBy, doc.issuedBy!));
    if (doc.country != null) rows.add(_FieldData(l10n.country, doc.country!));

    return _buildInfoRowWidgets(rows, colors);
  }

  List<Widget> _buildInfoRowWidgets(List<_FieldData> rows, AppColorsExtension colors) {
    final widgets = <Widget>[];
    for (int i = 0; i < rows.length; i++) {
      widgets.add(_verifiedRow(rows[i].label, rows[i].value, colors));
      if (i < rows.length - 1) {
        widgets.add(Divider(color: colors.border, height: 1));
      }
    }
    return widgets;
  }

  Widget _verifiedRow(String label, String value, AppColorsExtension colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(Icons.verified, color: colors.primary, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(color: colors.textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(color: colors.textPrimary, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String date) {
    try {
      final dt = DateTime.parse(date);
      return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
    } catch (_) {
      return date;
    }
  }

  String _formatAddress(SumsubAddress addr, AppLocalizations l10n) {
    final parts = <String>[];
    if (addr.street != null) {
      var line = addr.street!;
      if (addr.buildingNumber != null) line += ', ${addr.buildingNumber}';
      if (addr.flatNumber != null) line += ', ${l10n.addressApartment(addr.flatNumber!)}';
      parts.add(line);
    }
    if (addr.town != null) parts.add(addr.town!);
    if (addr.state != null) parts.add(addr.state!);
    if (addr.postCode != null) parts.add(addr.postCode!);
    if (addr.country != null) parts.add(addr.country!);
    return parts.join(', ');
  }

  String _docTypeName(String type, AppLocalizations l10n) {
    switch (type) {
      case 'PASSPORT':
        return l10n.docTypePassport;
      case 'ID_CARD':
        return l10n.docTypeIdCard;
      case 'DRIVERS':
      case 'DRIVING_LICENSE':
        return l10n.docTypeDriverLicense;
      case 'RESIDENCE_PERMIT':
        return l10n.docTypeResidencePermit;
      default:
        return type;
    }
  }
}

class _FieldData {
  final String label;
  final String value;
  const _FieldData(this.label, this.value);
}
