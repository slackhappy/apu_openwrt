# OpenWRT on a PCEngines APU

Here is my walkthrough for getting [OpenWRT](https://openwrt.org/) installed on a [PC Engines APU2](https://pcengines.ch/apu2d2.htm).  

Materials I used:
- a Macbook with no ethernet jack :-(
- a [USB-to-Serial cable](https://www.amazon.com/Adapter-Chipset-CableCreation-Converter-Register/dp/B0769FY7R7)
- a USB flash drive
- the APU2 itself (with a mSATA drive, a [Compex wle600vx](https://pcengines.ch/wle600vx.htm) wifi card for 5Ghz, and a USB [Panda Wireless PAU06](http://www.pandawireless.com/Products%20|%20Panda%20Wireless.html) dongle for 2.4Ghz - the wle600vx cannot do simultaneous dual-band, it has one radio).

Here is the story of how I got it set up.

### TL;DR

- I used a [Debian netinst](https://www.debian.org/CD/netinst/) installer to create a virtual debian amd64 install on my mac.  This was used to customize the image to add a few drivers, including the wireless driver using OpenWRT's [Image Builder](https://openwrt.org/docs/guide-user/additional-software/imagebuilder).  You don't need to compile the image's packages and kernel to customize it - you can customize a binary image quickly and easily.

- I wrote that same Debian netinst iso to a USB flash drive, and booted it into rescue mode.  Once in rescue mode, I had a shell where I could `dd` copy my custom OpenWRT image to the mSATA drive.

## What I wish I knew going in

- If you want to have a linux-based home wireless router, **use OpenWRT, not [IPFire](https://www.ipfire.org/)**.  I like secure systems, but I think IPFire's security defaults are so restrictive that you might not get your system running.  If you don't have an ethernet jack on your laptop from which you can configure the system, don't bother with IPFire.  The wireless system starts with all client MACs dropped by default, and no amount of curling the local perl web configuration scripts seemed to convince it otherwise.  [Here's another take](https://teklager.se/en/knowledge-base/choosing-router-operating-system-pfsense-vs-opnsense-vs-openwrt/).  

- **Install to an mSATA drive, not an SD Card**.  I had an old Amazon SDHC Class 10 16GB card that worked nicely on the raspberry pi, so I figured that would be a perfect way to install a tiny distro like OpenWRT or IPFire.  I had planned to avoid wearing it down by making sure that all the logs stayed in a ramdisk, etc.  However, the SD support of APU is much worse. My installations of IPFire and OpenWRT, and debian all crashed trying to write to the SD Card.  There are many other examples of issues similar to mine.  For 14 bucks, don't even think about it, just get an mSATA, and save yourself the hassle.


## Building an OpenWRT image for an APU2 with wifi using the ImageBuilder
The [recommended platform](https://openwrt.org/docs/guide-user/additional-software/imagebuilder) is  64-bit Linux.  That is why I chose to install a minimal debian install.  When ignored the recommendation and tried building on macOS, here's the error I got: `Build dependency: OpenWrt can only be built on a case-sensitive filesystem`.  Fair enough.

I came up with this procedure by combining the [ImageBuilder docs](https://openwrt.org/docs/guide-user/additional-software/imagebuilder), instructions for a source build (much longer and 12GB of space just for the compilation - a 13GB vhd should suffice) from [3mdeb](https://3mdeb.com/firmware/installing-openwrt-on-apu3-platform/), and the [OpenWRT APU2 guide](https://openwrt.org/toh/pcengines/apu2).

1. Run an amd64 linux.  I downloaded [VirtualBox](https://www.virtualbox.org/) on my mac, and created Debian 64-bit system and used the defaults (1G ram, 8G Virtual HD) using the [Debian netinst](https://www.debian.org/CD/netinst/) amd64 iso.  1G ram, 8G hd seemed to be good defaults for this use case.  I ended up needing about 4GB for the minimal install (no graphical environment - just SSH server + base system, and the ImageBuilder deps).  I set the network config to be Bridged, so that I could ssh to the to the VM to run commands, and the VM itself could download stuff from the internet.

1. On your linux machine/VM, download the OpenWRT ImageBuilder
    ```
    $ curl -L  https://downloads.openwrt.org/releases/18.06.2/targets/x86/64/openwrt-imagebuilder-18.06.2-x86-64.Linux-x86_64.tar.xz | unxz | tar -xf -
    ```

1. Make the image.  We'll specify the packages we want to include in the build.  I wanted to download  `ath10k-firmware-qca988x` from opkg with a generic OpenWRT image, but I wasn't able to.  This is one of the reasons why I'm using the image builder instead of a generic image and downloading the rest on the device.  You may want to change the list of packages (e.g remove adblock).
    ```
    $ cd openwrt-imagebuilder-18.06.2-x86-64.Linux-x86_64/
    $ make image PACKAGES="adblock ath10k-firmware-qca988x block-mount ca-bundle collectd collectd-mod-sensors flashrom fstools hostapd kmod-ath10k kmod-crypto-hw-ccp kmod-fs-vfat kmod-gpio-button-hotplug kmod-gpio-nct5104d kmod-leds-gpio kmod-pcspkr kmod-rt2800-lib kmod-rt2800-usb kmod-rt2x00-lib kmod-rt2x00-usb kmod-sound-core kmod-sp5100_tco kmod-usb-ohci kmod-usb-storage kmod-usb-storage-uas kmod-usb2 kmod-usb3 luci luci-app-statistics rt2800-usb-firmware tcpdump sysfsutils usbutils wget" EXTRA_IMAGE_NAME="apu2_ath10k_qca988x"
    ```

1. Upload the image to a public location - we'll download it from the Debian rescue stick.  The image output will be here:  `bin/targets/x86/64/openwrt-18.06.2-apu2-ath10k-qca988x-x86-64-combined-ext4.img.gz`.  I'm using this git repo as my public download source.  You can transfer it some other way, but instead of trying to mount an image in the rescue OS, i thought this would be easier.


## Apply your image to the mSATA drive (initial bootstrap)
[Teklager.se](https://teklager.se/en/knowledge-base/openwrt-installation-instructions/) has a route that I like.  You boot into a live linux that can 1) download an image 2) apply to the mSATA drive 3) fix up the partioning (optional).  The Debian netinst USB can do that, so thats what I'll use.

1. Download the [Debian netinst](https://www.debian.org/CD/netinst/) amd64 iso.  Using `dd`, copy it to a USB drive. 
    Insert the drive, use diskutil list to find and unmount the drive device node /dev/diskX .  Be extra sure you have the right one!
    ```
    $ diskutil list
    $ diskutil unmountDisk /dev/diskX
    ```
    
    Directly apply the image to the drive.  This will **erase everything** on the device! Note the 'r' in rdiskX here.
    ```
    $ sudo dd bs=8m of=/dev/rdiskX if=debian-9.7.0-amd64-netinst.iso
    ```

1. Plug the USB drive into the APU, connect the serial cable, and a LAN cable in the port closest to the serial port.  Power up!  You should be greeted with the installer boot menu.  Your goal is to set the boot prompt to `boot: rescue console=ttyS0,115200n8`.  To do this, press `H` for Help, then `F5` for "special boot parameters"  You should now see a boot prompt below.  Enter `rescue console=ttyS0,115200n8`.  You will see a video mode error, press space to continue.

1. You are now in the rescue setup.  You should see `Rescue mode` at the time.  It looks like an install, but its not, just keep going!  Choose your language, country, etc.  Skip loading any firmware, and choose `enp0s1` as your primary ethernet, if it asks.  When it asks if you want to choose a root filesystem device, *scroll down* and choose "Do not use a root file system".  After all, we are here to overwrite it!  Finally, you should be able to execute the rescue shell.  Whew!

1. In the rescue shell, we'll proceed similar to the [Teklager.se](https://teklager.se/en/knowledge-base/openwrt-installation-instructions/) route.  1) Download the image using wget, extract if needed. 2) `dd` the image to the mSATA drive, and 3) use gparted to fix the partition size so that the full capacity of the mSATA drive is usable.

    Download and unzip:
    ```
    ~ # wget https://github.com/slackhappy/apu_openwrt/raw/master/openwrt-18.06.2-apu2-ath10k-qca988x-x86-64-combined-ext4.img.gz
    ~ # gunzip openwrt-18.06.2-apu2-ath10k-qca988x-x86-64-combined-ext4.img.gz 
    ```
    
    Apply the image:
    ```
    ~ # dd if=openwrt-18.06.2-apu2-ath10k-qca988x-x86-64-combined-ext4.img of=/dev/sda bs=4M; sync
    68+1 records in
    68+1 records out
    ```
    
    Confirm the image application - should look like this:
    ```
    ~ # parted /dev/sda print
    Number  Start   End     Size    Type     File system  Flags
     1      262kB   17.0MB  16.8MB  primary  ext2         boot
     2      17.3MB  286MB   268MB   primary  ext2
    ```

    If you want, expand the 286MB partition to the rest of the disk size (mine is 60G).  Note that upgrading to new OpenWRT images will reset this though.
    ```  
    ~ #  parted /dev/sda resizepart 2 60G
    Information: You may need to update /etc/fstab.
    
    ~# resize2fs /dev/sda2 
    ```
1. All done! Remove the USB boot disk, cross your fingers, and `reboot`.



## Enabling the wireless, and other post configuration

1. run `passwd` to set a password
1. enable the wireless by editing `/etc/config/wireless` to set disabled from `'1'` to `'0'`
1. to switch the device to use 2.4ghz bands instead of 5ghz bands, edit `/etc/config/wireless` to set `hwmode` to `11g` instead of `11a` (don't worry, it will use 2.4ghz N if your device has it), and delete the `htmode` line - it will be autodiscovered.
1. `reboot`
