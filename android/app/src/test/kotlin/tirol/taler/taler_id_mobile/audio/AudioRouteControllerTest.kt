package tirol.taler.taler_id_mobile.audio

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * Routing rules for in-call audio output.
 *
 * The regression these guard: requesting audio focus resets the output route to
 * the earpiece on most devices, so anything that requests focus has to re-apply
 * the route the user picked — otherwise "Speaker" turns itself off again.
 */
class AudioRouteControllerTest {

    private class FakeDevice : AudioRouteDevice {
        override var speakerphoneOn = false
        override var bluetoothScoOn = false
        var communicationMode = false
        var scoStarts = 0
        var scoStops = 0

        override fun enterCommunicationMode() {
            communicationMode = true
        }

        override fun startBluetoothSco() {
            scoStarts++
        }

        override fun stopBluetoothSco() {
            scoStops++
        }
    }

    private val device = FakeDevice()
    private val controller = AudioRouteController(device)

    @Test
    fun `calls start on the earpiece`() {
        controller.reapply()
        assertEquals(AudioRouteController.ROUTE_EARPIECE, controller.route)
        assertFalse(device.speakerphoneOn)
        assertTrue(device.communicationMode)
    }

    @Test
    fun `selecting speaker turns the loudspeaker on`() {
        controller.select(AudioRouteController.ROUTE_SPEAKER)
        assertTrue(device.speakerphoneOn)
    }

    @Test
    fun `audio focus request does not knock the call off the speaker`() {
        controller.select(AudioRouteController.ROUTE_SPEAKER)
        // Stand-in for MainActivity.requestAudioFocus(): the AudioManager resets
        // the route, then we re-apply. Before the fix this left the call on the
        // earpiece and "Speaker" could never be turned on at all.
        device.speakerphoneOn = false
        controller.reapply()
        assertTrue("speaker must survive an audio focus request", device.speakerphoneOn)
    }

    @Test
    fun `selecting bluetooth starts SCO and leaves the loudspeaker off`() {
        controller.select(AudioRouteController.ROUTE_BLUETOOTH)
        assertFalse(device.speakerphoneOn)
        assertTrue(device.bluetoothScoOn)
        assertEquals(1, device.scoStarts)
    }

    @Test
    fun `switching from bluetooth to speaker stops SCO`() {
        controller.select(AudioRouteController.ROUTE_BLUETOOTH)
        controller.select(AudioRouteController.ROUTE_SPEAKER)
        assertTrue(device.speakerphoneOn)
        assertFalse(device.bluetoothScoOn)
        assertEquals(1, device.scoStops)
    }

    @Test
    fun `headphones route behaves like the earpiece`() {
        controller.select(AudioRouteController.ROUTE_SPEAKER)
        controller.select(AudioRouteController.ROUTE_HEADPHONES)
        assertFalse(device.speakerphoneOn)
        assertFalse(device.bluetoothScoOn)
    }

    @Test
    fun `unknown route falls back to the earpiece`() {
        controller.select(AudioRouteController.ROUTE_SPEAKER)
        controller.select("carrier-pigeon")
        assertEquals(AudioRouteController.ROUTE_EARPIECE, controller.route)
        assertFalse(device.speakerphoneOn)
    }

    @Test
    fun `the next call starts on the earpiece again`() {
        controller.select(AudioRouteController.ROUTE_SPEAKER)
        controller.reset()
        controller.reapply()
        assertEquals(AudioRouteController.ROUTE_EARPIECE, controller.route)
        assertFalse(device.speakerphoneOn)
    }
}
