# File Variables ################################################
############################################################
BASH_PROFILE=\
\# Begin .bash_profile\n\
exec env -i HOME=$${HOME} TERM=$${TERM} PS1="\u:\w\$$ " /bin/bash\n\
\# End .bash_profile

BASHRC=\
\# Begin .bashrc\n\
set +h\n\
umask 022\n\
CLFS=$(CLFS)\n\
LC_ALL=POSIX\n\
PATH=$(CLFS_CTOOLS)/bin:/bin:/usr/bin\n\
export CLFS LC_ALL PATH\n\
unset CFLAGS\n\n\
export CLFS_FLOAT=$(CLFS_FLOAT)\n\
export CLFS_FPU=$(CLFS_FPU)\n\
export CLFS_HOST=$(CLFS_HOST)\n\
export CLFS_TARGET=$(CLFS_TARGET)\n\
export CLFS_ARCH=$(CLFS_ARCH)\n\
export CLFS_ARM_ARCH=$(CLFS_ARM_ARCH)\n\
\# End .bashrc

BASHRC_CROSS=\
\# Begin .bashrc + cross-vars\n\
export CC=$(CLFS_TARGET)-gcc\n\
export AR=$(CLFS_TARGET)-ar\n\
export AS=$(CLFS_TARGET)-as\n\
export LD=$(CLFS_TARGET)-ld\n\
export RANLIB=$(CLFS_TARGET)-ranlib\n\
export READELF=$(CLFS_TARGET)-readelf\n\
export STRIP=$(CLFS_TARGET)-strip\n\
\# End .bashrc + cross-vars

FSTAB=\
\# Begin /etc/fstab\n\
\# FileSystem	MountPoint	Type	Options		Dump Fsck\n\
/dev/mmcblk0p1	/boot		vfat	defaults	1	2\n\
/dev/mmcblk0p2	/		ext4	defaults	0	1\n\
/dev/mmcblk0p3	none		swap	sw		0	0\n\
tmpfs /tmp      tmpfs defaults,noatime,nosuid,size=30m            0 0\n\
tmpfs /var/run  tmpfs nodev,nosuid                                0 0\n\
tmpfs /var/log  tmpfs defaults,noatime,nosuid,mode=0755,size=100m 0 0\n\
tmpfs /var/run  tmpfs defaults,noatime,nosuid,mode=0755,size=2m   0 0\n\
\# End /etc/fstab

PASSWD=\
\# Begin /etc/passwd\n\
root::0:0:root:/bin:ash\n\
\# End /etc/passwd

GROUP=\
\# Begin /etc/group\n\
root:x:0:\n\
bin:x:1:\n\
sys:x:2:\n\
kmem:x:3:\n\
tty:x:4:\n\
tape:x:5:\n\
daemon:x:6:\n\
floppy:x:7:\n\
disk:x:8:\n\
lp:x:9:\n\
dialout:x:10:\n\
audio:x:11:\n\
video:x:12:\n\
utmp:x:13:\n\
usb:x:14:\n\
cdrom:x:15:\n\
\# End /etc/group

PROFILE=\
\# /etc/profile\n\
\# Set the initial path\n\
export PATH=/bin:/usr/bin\n\
if [ \`id -u\` -eq 0 ] ; then\n\
\tPATH=/bin:/sbin:/usr/bin:/usr/sbin\n\
\tunset HISTFILE\n\
fi\n\
\# Setup some environment variables.\n\
export USER=\`id -un\`\n\
export LOGNAME=\$$USER\n\
export HOSTNAME=\`/bin/hostname\`\n\
export HISTSIZE=1000\n\
export HISTFILESIZE=1000\n\
export PAGER=/bin/more\n\
export EDITOR=/bin/vi\n\
\# End /etc/profile

INITTAB=\
\# Begin /etc/inittab\n\
::sysinit:/etc/init.d/rcS\n\
tty1::askfirst:/sbin/getty 38400 tty1\n\
::respawn:/sbin/getty -L ttyAMA0 115200 vt100\n\
::restart:/sbin/init\n\
::ctrlaltdel:/sbin/reboot\n\
::shutdown:/etc/init.d/rcK\n\
\# End /etc/inittab

# /etc/init.d/functions
FUNCTIONS=\
status(){\n\
\tif [ \$$1 -eq 0 ]; then\n\
\t\techo \"[SUCCESS]\"\n\
\telse\n\
\t\techo \"[FAILED]\"\n\
\t\tif [ \$$2 -eq 1 ]; then\n\
\t\t\techo \"... System init aborted.\"\n\
\t\t\texit 1\n\
\t\tfi\n\
\tfi\n\
}\n\

# /etc/init.d/rcS
RCS=\
\#!/bin/ash\n\
export PATH=/bin:/sbin:/usr/bin:/usr/sbin\n\
. /etc/init.d/functions\n\
echo -n \"Mounting /proc             : \"\n\
mount -n -t proc /proc /proc\n\
status \$$? 1\n\
echo -n \"Mounting /sys              : \"\n\
mount -n -t sysfs sysfs /sys\n\
status \$$? 1\n\
echo -n \"Mounting /dev              : \"\n\
mount -n -t tmpfs mdev /dev\n\
status \$$? 1\n\
echo -n \"Mounting /dev/pts          : \"\n\
mkdir /dev/pts\n\
mount -t devpts devpts /dev/pts\n\
status \$$? 1\n\
echo -n \"Mounting Shared Memory     : \"\n\
mkdir /dev/shm\n\
mount -t tmpfs none /dev/shm\n\
status \$$? 1\n\
echo -n \"Enabling Hot-Plug          : \"\n\
echo \"/sbin/mdev\" > /proc/sys/kernel/hotplug\n\
status \$$? 0\n\
echo -n \"Populating /dev            : \"\n\
mkdir /dev/input\n\
mkdir /dev/snd\n\
mdev -s\n\
status \$$? 0\n\
echo -n \"Checking Local Filesystems : \"\n\
fsck -A -C -R -T -t nonnfs,nosmbfs\n\
status \$$? 0\n\
echo -n \"Remounting Root RW         : \"\n\
mount -o remount,rw /\n\
status \$$? 0\n\
echo -n \"Mounting Other Filesystems : \"\n\
mount -a\n\
status \$$? 0\n\
echo -n \"Setting Hostname           : \"\n\
hostname -F /etc/hostname\n\
status \$$? 0\n\
echo -n \"Cleaning Up System         : \"\n\
ln -s ../tmp /var/tmp\n\
touch /var/run/utmp\n\
touch /var/log/btmp\n\
touch /var/log/wtmp\n\
touch /var/log/lastlog\n\
touch /var/log/messages\n\
chmod 0664 /var/run/utmp\n\
chmod 0664 /var/log/wtmp\n\
chmod 0664 /var/log/btmp\n\
chmod 0664 /var/log/lastlog\n\
chmod 0660 /var/log/messages\n\
status \$$? 0\n\
echo -n \"Setting up interface lo   : \"\n\
ifconfig lo up 127.0.0.1\n\
status \$$? 0\n\
echo -n \"Running start scripts     : \"\n\
for i in /etc/init.d/start/*\n\
do\n\
\tif [ -x \$$i ]; then\n\
\t\t\$$i start\n\
\tfi\n\
done\n\
exit 0\n\
\# End /etc/init.d/rcS

# /etc/init.d/rcK
RCK=\
\#!/bin/ash\n\
. /etc/init.d/functions\n\
echo -e \"\\\nSystem is going down for reboot or halt now.\\\n\"\n\
echo \"Starting stop scripts.\"\n\
for i in /etc/init.d/stop/*\n\
do\n\
\tif [ -x \$$i ]; then\n\
\t\t\$$i stop\n\
\tfi\n\
done\n\
echo -n \"Syncing all filesystems    : \"\n\
sync\n\
status \$$? 0\n\
echo -n \"Unmounting all filesystems : \"\n\
umount -a -r

# /etc/init.d/syslog
SYSLOG=\
\#!/bin/ash\n\
. /etc/init.d/functions\n\
case \"\$$1\" in\n\
start)\n\
\techo -n \"Starting syslogd : \"\n\
\tsyslogd -s 0 -L\n\
\tstatus \$$? 0\n\
\techo -n \"Starting klogd   : \"\n\
\tklogd\n\
\tstatus \$$? 0\n\
\t;;\n\
stop)\n\
\techo -n \"Stopping klogd   : \"\n\
\tkillall klogd\n\
\tstatus \$$? 0\n\
\techo -n \"Stopping syslogd : \"\n\
\tkillall syslogd\n\
\tstatus \$$? 0\n\
\t;;\n\
restart)\n\
\t\$$0 stop\n\
\t\$$0 start\n\
\t;;\n\
*)\n\
\techo \"Usage: \$$0 {start|stop|restart}\"\n\
\texit 1\n\
esac\n\
\# End /etc/init.d/syslog

HOSTS=\
\# Begin /etc/hosts\n\
127.0.0.1 localhost\n\
\# End /etc/hosts

INTERFACES=\
auto eth0\n\
iface eth0 inet dhcp

UDHCPC=\
\#!/bin/sh\n\
\# udhcpc Interface Configuration\n\
\# Based on http://lists.debian.org/debian-boot/2002/11/msg00500.html\n\
\# udhcpc script edited by Tim Riker <Tim@Rikers.org>\n\n\
[ -z \"\$$1\" ] && echo \"Error: should be called from udhcpc\" && exit 1\n\n\
RESOLV_CONF=\"/etc/resolv.conf\"\n\
[ -n \"\$$broadcast\" ] && BROADCAST=\"broadcast \$$broadcast\"\n\
[ -n \"\$$subnet\" ] && NETMASK=\"netmask \$$subnet\"\n\n\
case \"\$$1\" in\n\
deconfig)\n\
/sbin/ifconfig \$$interface 0.0.0.0\n\
;;\n\n\
renew|bound)\n\
/sbin/ifconfig \$$interface \$$ip \$$BROADCAST \$$NETMASK\n\n\
if [ -n \"\$$router\" ] ; then\n\
while route del default gw 0.0.0.0 dev \$$interface ; do\n\
true\n\
done\n\n\
for i in \$$router ; do\n\
route add default gw \$$i dev \$$interface\n\
done\n\
fi\n\n\
echo -n > \$$RESOLV_CONF\n\
[ -n \"\$$domain\" ] && echo search \$$domain >> \$$RESOLV_CONF\n\
for i in \$$dns ; do\n\
echo nameserver \$$i >> \$$RESOLV_CONF\n\
done\n\
;;\n\
esac\n\n\
exit 0\n\

# /etc/mdev.conf
MDEV=\
\# Begin /etc/mdev.conf\n\
null\t\troot:root 666 @chmod 666 \$$MDEV\n\
zero\t\troot:root 666\n\
full\t\troot:root 666\n\
random\t\troot:root 444\n\
urandom\t\troot:root 444\n\
mem\t\troot:root 644\n\
console\t\troot:tty  600 @chmod 600 \$$MDEV\n\
ptmx\t\troot:root 666\n\
tty\t\troot:tty  666\n\
tty[0-9]*\troot:tty  660\n\
ttyAMA0\t\troot:tty  660\n\
\# End /etc/mdev.conf

CMDLINE=\
dwc_otg.lpm_enable=0 console=ttyAMA0,115200 console=tty1 \
root=/dev/mmcblk0p2 rootfstype=ext4 elevator=deadline rootwait

############################################################
print-bash-profile : ; @echo -e "$(BASH_PROFILE)" | sed -e 's/^[ ]//'
print-bashrc       : ; @echo -e "$(BASHRC)"       | sed -e 's/^[ ]//'
print-bashrc-cross : ; @echo -e "$(BASHRC_CROSS)" | sed -e 's/^[ ]//'
print-fstab        : ; @echo -e "$(FSTAB)"        | sed -e 's/^[ ]//'
print-group        : ; @echo -e "$(GROUP)"        | sed -e 's/^[ ]//'
print-passwd       : ; @echo -e "$(PASSWD)"       | sed -e 's/^[ ]//'
print-profile      : ; @echo -e "$(PROFILE)"      | sed -e 's/^[ ]//'
print-inittab      : ; @echo -e "$(INITTAB)"      | sed -e 's/^[ ]//'
print-hosts        : ; @echo -e "$(HOSTS)"        | sed -e 's/^[ ]//'
print-udhcpc       : ; @echo -e "$(UDHCPC)"       | sed -e 's/^[ ]//'
print-interfaces   : ; @echo -e "$(INTERFACES)"   | sed -e 's/^[ ]//'
print-mdev         : ; @echo -e "$(MDEV)"         | sed -e 's/^[ ]//'
print-cmdline      : ; @echo -e "$(CMDLINE)"      | sed -e 's/^[ ]//'
print-functions    : ; @echo -e "$(FUNCTIONS)"    | sed -e 's/^[ ]//'
print-rcs          : ; @echo -e "$(RCS)"          | sed -e 's/^[ ]//'
print-rck          : ; @echo -e "$(RCK)"          | sed -e 's/^[ ]//'
print-syslog       : ; @echo -e "$(SYSLOG)"       | sed -e 's/^[ ]//'
