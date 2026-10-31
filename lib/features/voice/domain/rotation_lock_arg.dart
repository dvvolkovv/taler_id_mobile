/// Reads the `locked` argument of the in-call assistant's
/// `set_screen_rotation_lock` tool. Strict on purpose: anything but a boolean
/// or its string form is null and the call is refused — a garbled argument
/// must not silently unlock rotation and store that for the next calls.
bool? parseRotationLockArg(Object? raw) => switch (raw) {
      true || 'true' => true,
      false || 'false' => false,
      _ => null,
    };
