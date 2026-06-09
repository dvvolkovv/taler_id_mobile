import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import '../bloc/voice_enrollment_bloc.dart';
import '../bloc/voice_enrollment_event.dart';
import '../bloc/voice_enrollment_state.dart';

class OwnerEnrollmentSheet extends StatefulWidget {
  const OwnerEnrollmentSheet({super.key});

  @override
  State<OwnerEnrollmentSheet> createState() => _OwnerEnrollmentSheetState();
}

class _OwnerEnrollmentSheetState extends State<OwnerEnrollmentSheet> {
  static const int _targetSec = 20;
  final _recorder = AudioRecorder();
  Timer? _ticker;
  int _elapsedSec = 0;
  String? _wavPath;

  @override
  void dispose() {
    _ticker?.cancel();
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    if (!await _recorder.hasPermission()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Микрофон не разрешён')),
        );
      }
      return;
    }
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/owner_enroll_${DateTime.now().millisecondsSinceEpoch}.wav';
    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.wav, sampleRate: 16000, numChannels: 1),
      path: path,
    );
    setState(() {
      _wavPath = path;
      _elapsedSec = 0;
    });
    context.read<VoiceEnrollmentBloc>().add(const StartRecording());
    _ticker = Timer.periodic(const Duration(seconds: 1), (t) async {
      if (_elapsedSec >= _targetSec) {
        t.cancel();
        await _stopAndSubmit();
        return;
      }
      setState(() => _elapsedSec += 1);
    });
  }

  Future<void> _stopAndSubmit() async {
    final path = _wavPath;
    await _recorder.stop();
    if (path != null && mounted) {
      context.read<VoiceEnrollmentBloc>().add(Submit(path));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<VoiceEnrollmentBloc, VoiceEnrollmentState>(
      listener: (ctx, state) {
        if (state is Enrolled) Navigator.of(ctx).pop(true);
      },
      builder: (ctx, state) {
        final isRecording = state is Recording;
        final isSubmitting = state is Submitting;
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Запиши свой голос',
                style: Theme.of(ctx).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              const Text(
                'Это нужно, чтобы ассистент реагировал только на тебя. '
                'Скажи что-то на 20 секунд — например, прочитай '
                'два предложения из новостей или опиши свой день.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              if (isRecording)
                Column(children: [
                  const Icon(Icons.mic, size: 48, color: Colors.red),
                  Text('$_elapsedSec / $_targetSec сек'),
                ])
              else if (isSubmitting)
                const Column(children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 8),
                  Text('Отправляю…'),
                ])
              else if (state is Failed)
                Text('Ошибка: ${state.message}', style: const TextStyle(color: Colors.red))
              else
                IconButton(
                  icon: const Icon(Icons.mic, size: 64),
                  onPressed: _startRecording,
                ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Отмена'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}
