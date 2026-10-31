/// Whether a file message shows its text as a caption under the file.
///
/// A file message's text is the caption the sender typed. Without one, a
/// document carries its own file name and a photo or video an empty string,
/// so neither is repeated under the file. Audio is left out: a voice
/// message's text is not a caption.
bool showsFileCaption({
  required String content,
  required String? fileName,
  required String fileType,
}) =>
    fileType != 'audio' && content.isNotEmpty && content != fileName;
