## A Magisk module for changing audio samplerates at the system-wide mixer for the best Hi-Fi experience

This module has been developed for casual music lovers to be able to experience the essence of my root script ["USB SampleRate Changer"](https://github.com/yzyhk904/USB_SampleRate_Changer) by the automation of Magisk.

Its features:
<ol>
    <li>Setting the samplerate of the USB HAL audio driver to be maximum automatically (up to 768 kHz & 32 bits; but 192 kHz & 32 bits for Tensor devices only)</li>
    <li>Setting its USB data transfer period to be 2000 usec for reducing jitter, instead of usual 5000 usec</li>
    <li>Setting the samplerate of the AOSP Bluetooth audio driver automatically depending upon a selected codec without double re-sampling unlike offload drivers</li>
    <li>Setting the samplerate of internal speakers to be maximum; 384 kHz & 32 bits for Qcom devices, 48 kHz & 32 bits for others</li>
    <li>Default re-sampling parameters are the same as <a href="https://github.com/Magisk-Modules-Alt-Repo/resampling-for-cheapies">"Resampling for cheapies"</a> (can be overridden by other modules)</li>
    <li>Optimizing I/O kernel tunables for reducing jitter (most effective and almost safe as kernel tuning)</li>
    <li>Designed for using <a href="https://github.com/Magisk-Modules-Alt-Repo/audio-misc-settings">"Audio Msic. Settings"</a> or <a href="https://github.com/yzyhk904/hifi-maximizer-mod">"Hifi maximizer"</a> together, but can be used by itself only</li>
    <li>Since the above two modules override re-sampling parameters, use <a href="https://github.com/Magisk-Modules-Alt-Repo/resampling-for-cheapies">"Resampling for cheapies"</a> in addition if you use cheapie devices (Bluetooth LDAC earphones, cheap USB DAC's, and internal speakers, etc.)</li>
    <li>Including <a href="https://github.com/Magisk-Modules-Alt-Repo/drc-remover">"DRC remover"</a> and <a href="https://github.com/Magisk-Modules-Alt-Repo/usb-samplerate-unlocker">"USB Samplerate Unlocker"</a>; Don't try installing them together</li>
</ol>
<br/>
<br/>

Notes:
* This module can run only on devices using a 7.0 audio policy configuration prevailing since Android 14 or so including custom ROM's supporting relatively old ones.
* This module has been tested on LineageOS and crDroid ROM's, and phh GSI's (Android 14, and Qualcomm SoC & MediaTek SoC & Tensors combinations). 
* Don't forget to install ["Audio jitter silencer"](https://github.com/Magisk-Modules-Alt-Repo/audio-jitter-silencer) together and uninstall "Digital Wellbeing" app (for reducing very large jitters which this module cannot reduce by itself)!
* Almost all equalizers and some apps (using an internal re-sampler to output; e.g. Am@zon music, some VOIP apps, etc.) cannot work for greater than 192kHz audio outputs (but of which quality is far better sometimes). If you prefer such ones, modify "384000" to "190000" or even "48000" in "customize.sh" in a ZIP file of this module and install (or update) the modified one


## DISCLAIMER

* I am not responsible for any damage that may occur to your device, so it is your own choice whether to attempt this module or not.

##
