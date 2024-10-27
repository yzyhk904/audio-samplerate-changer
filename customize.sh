#!/system/bin/sh

# A gurd for devices of pre 7.0 audio policy implementation
# Busybox cannot execute {,64} expansion properly unlike mksh, so manually expanded
if [ -z "`ls /vendor/lib64/android.hardware.audio@7.?.so 2>/dev/null`"  -a  -z "`ls /vendor/lib/android.hardware.audio@7.?.so 2>/dev/null`" ]; then
    abort "  ***
  Aborted: no 7.0 audio policy implementation; this module doesn't support old devices based on pre 7.0 audio implementations
  ***"
fi

[ -z "$(magisk --path)" ] && alias magisk='ksu-magisk'

. "$MODPATH/customize-functions.sh"

if ! isMagiskMountCompatible; then
    abort '  ***
  Aborted by no Magisk-mirrors:
    try again either
      a.) with official Magisk v27.0 (mounting mirrors), or
      b.) after installing "compatible Magisk-mirroring" Magisk module and rebooting
  ***'
fi

MAGISKTMP="$(magisk --path)/.magisk"

REPLACE=""
REPLACEFILES=""

# Note: almost all equalizers and some apps cannot work for greater than 192kHz audio outputs, but their quality is far better sometimes
SampleRatePrimary="384000"
AudioFormatPrimary="AUDIO_FORMAT_PCM_32_BIT"

DRC_enabled="false"
USB_module="usb"
BT_module="bluetooth"
templateFile="$MODPATH/templates/bypass_offload_template.xml"

# Check if on a specific device or not
case "`getprop ro.board.platform`" in
    gs* | zuma* )
        # A conflicting gurd for "Hifi maximizer" on Tensor devices
        if [ -e "${MODDIR%/*/*}/modules/hifi-maximizer-mod" ]; then
            abort '  ***
  Aborted: detecting Hifi maximizer already containing this feature on Tensor devices
  ***'
        
        fi
        # Tensor's max. samplerate for internal speakers
        SampleRatePrimary="48000"
        USB_module="usbv2"
        templateFile="$MODPATH/templates/offload_hifi_playback_template.xml"
        ;;
    "pineapple" )
        # POCO F6 cannot output AOSP "bluetooth" driver, but "bluetooth_qti" driver can except its offload driver
        BT_module="bluetooth_qti"
        ;;
    mt* )
        # MTK devices max. samplerate for internal speakers
        SampleRatePrimary="48000"
        ;;
    * )
        ;;
esac

# Set the active configuration file name retrieved from the audio policy server
configXML="`getActivePolicyFile`"

# configXML is usually placed under "/vendor/etc" (or "/vendor/etc/audio"), but
# "/my_product/etc" and "/odm/etc" are used on ColorOS (RealmeUI) and OxygenOS(?)
case "$configXML" in
    /vendor/etc/* | /my_product/etc/* | /odm/etc/* | /system/etc/* | /product/etc/* )
        case "${configXML}" in
            /system/* )
                configXML="${configXML#/system}"
            ;;
        esac
        modConfigXML="$MODPATH/system${configXML}"
        
        mkdir -p "${modConfigXML%/*}"
        touch "$modConfigXML"
        
        sed -e "s/%DRC_ENABLED%/$DRC_enabled/" -e "s/%USB_MODULE%/$USB_module/" -e "s/%BT_MODULE%/$BT_module/" \
            -e "s/%SAMPLING_RATE%/$SampleRatePrimary/" -e "s/%AUDIO_FORMAT%/$AudioFormatPrimary/" \
                "$templateFile" >"$modConfigXML"
        
        chmod 644 "$modConfigXML"
        chcon u:object_r:vendor_configs_file:s0 "$modConfigXML"
        chown root:root "$modConfigXML"
        chmod -R a+rX "${modConfigXML%/*}"
        if [ -z "${REPLACEFILES}" ]; then
            REPLACEFILES="/system${configXML}"
        else
            REPLACEFILES="${REPLACEFILES} /system${configXML}"
        fi
        
        # If "${configXML}" isn't symbolically linked to "$/system/{configXML}", 
        #   disable Magisk's "magic mount" and mount "${configXML}" by this module itself in "service.sh"
        if [ ! -e "/system${configXML}" ]; then
            touch "$MODPATH/skip_mount"
        fi
        ;;
    * )
        ;;
esac

# Note: Don't use "${MAGISKTMP}/mirror/system/vendor/*" instaed of "${MAGISKTMP}/mirror/vendor/*".
# In some cases, the former may link to overlaied "/system/vendor" by Magisk itself (not mirrored original one).

#   "full" below this line means "up to 386kHz unlock";
#    for "up to 768kHz unlock", replace "full" with "max" below this line;
#    for "up to 192kHz unlock", replace "full" with "default" below this line.

for ld in "lib" "lib64"; do
    d="/system/vendor/${ld}"
    for lname in "libalsautils.so" "libalsautilsv2.so"; do
        if [ -r "${MAGISKTMP}/mirror/vendor/${ld}/${lname}"  -a  -r "${d}/${lname}" ]; then
            mkdir -p "${MODPATH}${d}"
            patchClearLock "${MAGISKTMP}/mirror/vendor/${ld}/${lname}" "${MODPATH}${d}/${lname}" "full"

            chmod 644 "${MODPATH}${d}/${lname}"
            chcon u:object_r:vendor_file:s0 "${MODPATH}${d}/${lname}"
            chown root:root "${MODPATH}${d}/${lname}"
            chmod -R a+rX "${MODPATH}${d}"
            if [ -z "${REPLACEFILES}" ]; then
                REPLACEFILES="${d}/${lname}"
            else
                REPLACEFILES="${REPLACEFILES} ${d}/${lname}"
            fi
        fi
    done
    
    for lname in "audio_usb_aoc.so"; do
        if [ -r "${MAGISKTMP}/mirror/vendor/${ld}/${lname}"  -a  -r "${d}/${lname}" ]; then
            mkdir -p "${MODPATH}${d}"
            patchClearTensorOffloadLock "${MAGISKTMP}/mirror/vendor/${ld}/${lname}" "${MODPATH}${d}/${lname}"

            chmod 644 "${MODPATH}${d}/${lname}"
            chcon u:object_r:vendor_file:s0 "${MODPATH}${d}/${lname}"
            chown root:root "${MODPATH}${d}/${lname}"
            chmod -R a+rX "${MODPATH}${d}"
            if [ -z "${REPLACEFILES}" ]; then
                REPLACEFILES="${d}/${lname}"
            else
                REPLACEFILES="${REPLACEFILES} ${d}/${lname}"
            fi
        fi
    done
    
done

fname="/system/vendor/etc/audio_platform_configuration.xml"
if [ -r "$fname" ]; then
    mkdir -p "${MODPATH}${fname%/*}"
    sed -e 's/min_rate="[1-9][0-9]*"/min_rate="44100"/g' \
        -e 's/"MaxSamplingRate=[1-9][0-9]*,/"MaxSamplingRate=192000,/' <"${MAGISKTMP}/mirror${fname#/system}" >"${MODPATH}${fname}"
    touch "${MODPATH}${fname}"
    chmod 644 "${MODPATH}${fname}"
    chcon u:object_r:vendor_configs_file:s0 "${MODPATH}${fname}"
    chown root:root "${MODPATH}${fname}"
    chmod -R a+rX "${MODPATH}${fname%/*}"
    if [ -z "${REPLACEFILES}" ]; then
        REPLACEFILES="${fname}"
    else
        REPLACEFILES="${REPLACEFILES} ${fname}"
    fi
fi

rm -f "$MODPATH/customize-functions.sh" "$MODPATH/LICENSE" "$MODPATH/README.md" "$MODPATH/changelog.md"
rm -rf "$MODPATH/templates"
ui_print_replacelist "${REPLACEFILES}"

if [ -e "${MODPATH%/*/*}/modules/drc-remover" ]; then
    ui_print ""
    ui_print "****************************************************************"
    ui_print " Uninstall \"DRC remover\" manually later; this module includes all its features"
    ui_print "****************************************************************"
    ui_print ""
fi
if [ -e "${MODPATH%/*/*}/modules/usb-samplerate-unlocker" ]; then
    ui_print ""
    ui_print "****************************************************************"
    ui_print " Uninstall \"USB Samplerate Unlocker\" manually later; this module includes all its features"
    ui_print "****************************************************************"
    ui_print ""
fi
