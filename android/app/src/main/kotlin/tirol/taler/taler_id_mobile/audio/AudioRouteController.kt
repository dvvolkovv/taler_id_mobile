package tirol.taler.taler_id_mobile.audio

/**
 * The bits of `AudioManager` the in-call routing touches, behind an interface so
 * the ordering rules in [AudioRouteController] can be unit-tested off-device.
 */
interface AudioRouteDevice {
    var speakerphoneOn: Boolean
    var bluetoothScoOn: Boolean
    fun enterCommunicationMode()
    fun startBluetoothSco()
    fun stopBluetoothSco()
}

/**
 * Owns "where in-call audio comes out" for the whole app.
 *
 * There is exactly one hazard this class exists for: requesting audio focus
 * resets the output route to the earpiece on most devices. Everything that
 * requests focus — call start, mic re-enable, focus regain after an
 * interruption — therefore has to re-apply the route the user last picked
 * instead of hard-coding the earpiece, or the "Speaker" button silently
 * undoes itself.
 */
class AudioRouteController(private val device: AudioRouteDevice) {

    /** The route the user (or the call flow) last asked for. */
    var route: String = ROUTE_EARPIECE
        private set

    /** Switch to [route] and apply it to the hardware. */
    fun select(route: String) {
        this.route = if (route in KNOWN_ROUTES) route else ROUTE_EARPIECE
        apply()
    }

    fun setSpeakerphone(on: Boolean) = select(if (on) ROUTE_SPEAKER else ROUTE_EARPIECE)

    /** Re-assert the current route after something that may have reset it. */
    fun reapply() = apply()

    /** Call ended — the next call starts on the earpiece again. */
    fun reset() {
        route = ROUTE_EARPIECE
    }

    private fun apply() {
        device.enterCommunicationMode()
        when (route) {
            ROUTE_SPEAKER -> {
                device.stopBluetoothSco()
                device.bluetoothScoOn = false
                device.speakerphoneOn = true
            }
            ROUTE_BLUETOOTH -> {
                device.speakerphoneOn = false
                device.startBluetoothSco()
                device.bluetoothScoOn = true
            }
            else -> { // earpiece, headphones
                device.stopBluetoothSco()
                device.bluetoothScoOn = false
                device.speakerphoneOn = false
            }
        }
    }

    companion object {
        const val ROUTE_EARPIECE = "earpiece"
        const val ROUTE_SPEAKER = "speaker"
        const val ROUTE_BLUETOOTH = "bluetooth"
        const val ROUTE_HEADPHONES = "headphones"

        private val KNOWN_ROUTES = setOf(
            ROUTE_EARPIECE, ROUTE_SPEAKER, ROUTE_BLUETOOTH, ROUTE_HEADPHONES,
        )
    }
}
