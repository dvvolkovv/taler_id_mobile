import 'package:flutter/material.dart';
import 'package:taler_id_mobile/l10n/app_localizations.dart';

import '../../domain/entities/mail_folder_entity.dart';

/// Localized display name for a mail folder (special roles get l10n names,
/// custom folders keep their server-side name).
String mailFolderDisplayName(MailFolderEntity folder, AppLocalizations l10n) {
  return switch (folder.role) {
    'inbox' => l10n.mailFolderInbox,
    'sent' => l10n.mailFolderSent,
    'drafts' => l10n.mailFolderDrafts,
    'junk' => l10n.mailFolderJunk,
    'trash' => l10n.mailFolderTrash,
    _ => folder.name,
  };
}

IconData mailFolderIcon(MailFolderEntity folder) {
  return switch (folder.role) {
    'inbox' => Icons.inbox_outlined,
    'sent' => Icons.send_outlined,
    'drafts' => Icons.edit_note_outlined,
    'junk' => Icons.report_gmailerrorred_outlined,
    'trash' => Icons.delete_outline,
    _ => Icons.folder_outlined,
  };
}
