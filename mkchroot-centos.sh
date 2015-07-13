#!/bin/bash -e

# See https://zaufi.github.io/administration/2014/06/10/howto-make-a-centos-chroot/

# Needs,
#    sudo apt-get install yum rpm

function usage() {
    echo "Usage: ARCH=[i386|amd64] $0 [dest]"
}

arch=$ARCH
case $arch in
    amd64|x86_64)
        centos_release="http://mirror.centos.org/centos/6/os/x86_64/Packages/centos-release-6-6.el6.centos.12.2.x86_64.rpm "
        ;;
    i386)
        centos_release="http://mirror.centos.org/centos/6/os/i386/Packages/centos-release-6-6.el6.centos.12.2.i686.rpm"
        ;;
    *)
        echo "Unknown architecture $arch"
        usage
        exit 1
        ;;
esac

if [ -z "$1" ]; then
    usage
    exit 1
fi

dest=$(realpath $1)
user=$(id -un)

mkdir $dest
rpm --root=$dest --rebuilddb

curl $centos_release > $dest/centos-release.rpm
sudo rpm --root=$dest --nodeps --install $dest/centos-release.rpm

sudo yum --installroot=$dest --nogpg update
sudo yum --installroot=$dest --nogpg -y install yum

sudo chown $user $dest
sudo chmod u+rwx $dest
cat >$dest/activate <<EOF
#!/bin/bash
MY_CHROOT=$dest
sudo systemd-nspawn -D\$MY_CHROOT \$@
EOF
chmod ugo+rx $dest/activate

# RPM installed by Debian may not be the same version wanted by CentOS
# Rebuild the package database with the CentOS RPM
$dest/activate bash -e <<EOF
rm -rf /var/lib/rpm
rpm --rebuilddb
rpm --nodeps -i /centos-release.rpm
rm /centos-release.rpm
yum install -y yum file git sudo

adduser --uid=`id -u` -G wheel $user
sed -i '/requiretty/d' /etc/sudoers
echo "%wheel ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
mkdir -p /opt/ghc
chown $user /opt/ghc
EOF

$dest/activate sudo -u $user -- bash -e <<EOF
cd
git clone https://bgamari@github.com/bgamari/ghc-utils.git
cd ghc-utils
./setup-chroot
EOF
