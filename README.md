# HP Elite x2 G4 mute-key LEDs

The yellow dots in the F5 and F8 keys on the HP Elite x2 G4 stay lit under Linux. They are the speaker-mute and microphone-mute indicators. The kernel does not know this model, so the codec leaves the pins floating and the dots glow all the time.

This repository is a userspace workaround. It drives each dot yellow only while that device is muted, and dark while it is on. Confirmed on one machine on 2026-10-07.

The white keyboard backlight is a separate circuit and is left alone.

## Machine

| | |
| --- | --- |
| Model | HP Elite x2 G4, board 85B9, SKU 8FP50EP#AK8 |
| BIOS | R91 01.36.00, KBC 62.62.00 |
| Codec | Realtek ALC285, vendor 0x10ec0285, subsystem **103c:85b9** |
| GPIO | AFG node 0x01, `io=3`. Only bits 0 and 2 exist (mask `0x05`) |

Check your codec before installing:

```sh
grep -m1 -E 'Codec:|Subsystem Id:' /proc/asound/card0/codec#0
```

You want `Codec: Realtek ALC285` and `Subsystem Id: 0x103c85b9`.

## What the pins do

| Pin | Bit | Key | Meaning |
| --- | --- | --- | --- |
| GPIO2 | `0x04` | F5 | Speaker mute. High lights the dot, low turns it off |
| GPIO0 | `0x01` | F8 | Microphone mute. Same polarity |
| GPIO1 | `0x02` | | Left alone. It may be a speaker amplifier |

An undriven pin also lights the dot, which is why both dots are yellow out of the box. Driving the pin low is what turns it off. Coefficient registers `0x0b` bit 3 and `0x19` bit 13 do not control these dots on this machine.

Current kernels have `ALC285_FIXUP_HP_GPIO_LED` for nearby HP SSIDs (`0x854a` and others), but not for `0x85b9`. That fixup uses the same pins and the same polarity: GPIO data high while muted, low while unmuted. A matching quirk would be:

```c
SND_PCI_QUIRK(0x103c, 0x85b9, "HP Elite x2 G4", ALC285_FIXUP_HP_GPIO_LED),
```

That line has not been booted here. The service below does the same GPIO writes without a kernel rebuild. If a kernel with this quirk is later installed, disable the service so the two do not fight over the pins.

`ALC285_FIXUP_HP_MUTE_LED` (the coefficient version) does nothing useful on this codec.

## F8 itself

F5 sends the speaker-mute key and the desktop mute toggle already works. F8 does not send `KEY_MICMUTE`, so pressing it does not mute the microphone. The F8 dot still follows the microphone mute state. Mute the mic from the volume panel, or with:

```sh
wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle
```

## Install

Needs PipeWire (`wpctl`, `pactl`) and root, because opening `/dev/snd/hwC0D0` requires `CAP_SYS_RAWIO`.

```sh
git clone https://github.com/Mumbis/hp-elite-x2-g4-mute-leds.git
cd hp-elite-x2-g4-mute-leds
sudo ./install.sh
```

The service watches the default sink and source and updates the dots within about a second. A sleep hook and a udev rule reapply the pins after wake and after the sound card is reprobed, because the codec releases them.

## Check

With both devices unmuted, both dots should be dark and the codec should show:

```text
IO[0]: enable=1, dir=1, data=0
IO[1]: enable=0, dir=0, data=0
IO[2]: enable=1, dir=1, data=0
```

Mute the speaker. `IO[2]` `data` becomes `1` and the F5 dot turns yellow. Mute the microphone. `IO[0]` `data` becomes `1` and the F8 dot turns yellow. `IO[1]` stays disabled.

```sh
journalctl -u hp-elite-x2-mute-leds.service -n 20
```

## Remove

```sh
sudo systemctl disable --now hp-elite-x2-mute-leds.service
sudo rm /usr/local/sbin/hp-elite-x2-mute-leds \
  /etc/systemd/system/hp-elite-x2-mute-leds.service \
  /etc/systemd/system-sleep/hp-elite-x2-mute-leds \
  /etc/udev/rules.d/90-hp-elite-x2-mute-leds.rules
sudo systemctl daemon-reload
sudo udevadm control --reload-rules
```

After removal the pins float again and both dots come back on. That does not change the white backlight.
