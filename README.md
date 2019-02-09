# OpenWRT on a PCEngines APU

Here is my walkthrough for getting [OpenWRT](https://openwrt.org/) installed on a [PC Engines APU2](https://pcengines.ch/apu2d2.htm).  

Materials I used:
- a Macbook with no ethernet jack :-(
- a [USB-to-Serial cable](https://www.amazon.com/Adapter-Chipset-CableCreation-Converter-Register/dp/B0769FY7R7)
- a USB flash drive
- the APU2 itself (with a mSATA drive, and a [Compex wle600vx](https://pcengines.ch/wle600vx.htm) wifi card).

Here is the story of how I got it set up.

### TL;DR

- I used a [Debian netinst](https://www.debian.org/CD/netinst/) installer to create a virtual debian amd64 install on my mac.  This was used to customize the image to add a few drivers, including the wireless driver.  You don't need to compile the image to customize it - you can customize a binary image quickly and easily.

- I wrote that same netinst iso to a USB flash drive, and booted it into rescue mode.  Once in rescue mode, I had a shell where I could `dd` copy my custom OpenWRT image to the mSata drive.

## What I wish I knew going in.

- If you want to have a linux-based home wireless router, **use OpenWRT, not [IPFire](https://www.ipfire.org/)**.  I like secure systems, but I think IPFire's security defaults are so restrictive that you might not get your system running.  If you don't have an ethernet jack on your laptop from which you can configure the system, don't bother with IPFire.  The wireless system starts with all client MACs dropped by default, and no amount of curling the local perl web configuration scripts seemed to convince it otherwise.  [Here's another take](https://teklager.se/en/knowledge-base/choosing-router-operating-system-pfsense-vs-opnsense-vs-openwrt/).  

- **Install to an mSATA drive, not an SD Card**.  I had an old Amazon SDHC Class 10 16GB card that worked nicely on the raspberry pi, so I figured that would be a perfect way to install a tiny distro like OpenWRT or IPFire.  I had planned to avoid wearing it down by making sure that all the logs stayed in a ramdisk, etc.  However, the SD support of APU is much worse. My installations of IPFire and OpenWRT, and debian all crashed trying to write to the SD Card.  There are many other examples of issues similar to mine.  For 14 bucks, don't even think about it, just get an mSATA, and save yourself the hassle.


## Building an OpenWRT image for an APU2 with wifi using the ImageBuilder
The [recommended platform](https://openwrt.org/docs/guide-user/additional-software/imagebuilder) is  64-bit Linux.  That is why I chose to install a minimal debian install.  When ignored the recommendation and tried building on macOS, here's the error I got: `Build dependency: OpenWrt can only be built on a case-sensitive filesystem`.  Fair enough.

I came up with this procedure by combining the [ImageBuilder docs](https://openwrt.org/docs/guide-user/additional-software/imagebuilder), instructions for a source build (much longer and requires a > 10GB virtual hard disk) from [3mdeb](https://3mdeb.com/firmware/installing-openwrt-on-apu3-platform/), and the [OpenWRT APU2 guide](https://openwrt.org/toh/pcengines/apu2).

1. Download the image builder
    ```
    curl -L  https://downloads.openwrt.org/releases/18.06.2/targets/x86/64/openwrt-imagebuilder-18.06.2-x86-64.Linux-x86_64.tar.xz \
    unxz \
    tar -xf -
    ```

1. Make the image.  We'll specify the packages we want to include in the build.  I tried installing `ath10k-firmware-qca988x` from opkg with a generic OpenWRT image, but I wasn't able to.  This is one of the reasons why I'm using the image builder instead of a generic image and downloading the rest on the device.
    ```
    make image PACKAGES="kmod-ath10k ath10k-firmware-qca988x kmod-gpio-button-hotplug kmod-gpio-nct5104d kmod-usb-ohci kmod-usb2 kmod-usb3 kmod-fs-vfat kmod-sp5100_tco kmod-crypto-hw-ccp kmod-leds-gpio kmod-pcspkr kmod-sound-core wget fstools flashrom tcpdump"
    ```
