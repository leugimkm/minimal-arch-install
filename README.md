![](assets/archlinux_logo.png)

# Minimal Arch Installation

Simply boot into a live Arch Linux ISO, download the script (using `curl`) and execute `install.sh`.

Feel free to download, edit, clone, fork or open an issue.

---

## Usage

First, get the script by entering the following command on the terminal:

```bash
curl -LO https://github.com/leugimkm/minimal-arch-install/raw/main/install.sh
```

or enter this one:

```bash
curl -LO https://raw.githubusercontent.com/leugimkm/minimal-arch-install/main/install.sh
```

Then, make the downloaded script executable:

```bash
chmod +x install.sh
```

And finally, run the following command (see [Configure](#configure) before):

```bash
./install.sh
```

## Configure

By default the script has the following configuration:

```sh
readonly AUTO=False
readonly HOSTNAME='MinArI'
readonly TIMEZONE='America/Lima'
readonly LOCALE='en_US.UTF-8'
readonly KEYMAP='us'
readonly ROOT_PASSWORD='root'
readonly DISK='/dev/sda'
readonly RESOLUTION='1920x1080'
readonly KERNEL='linux'
USER_NAME='guest'
USER_PASSWORD='guest'
SWAP_SIZE=2
BOOT_LOADER='UEFI'
```

Before running the script, you should edit `install.sh` with `nano` or `vim`:

```sh
vim install.sh
```

and then apply changes, for example:

```bash
readonly AUTO=True
readonly HOSTNAME='ArchBox'
readonly TIMEZONE='America/New_York'
readonly LOCALE='es_ES.UTF-8'
readonly KEYMAP='es'
readonly ROOT_PASSWORD='superstrongpassword'
readonly DISK='/dev/nvme0n1'
readonly RESOLUTION='2560x1440'
readonly KERNEL='linux-lts'
USER_NAME='archlover'
USER_PASSWORD='iusearchbtw'
SWAP_SIZE=4
BOOT_LOADER='BIOS'
readonly EXTRA_PACKAGES=(
  sudo grub networkmanager git wget ttf-sourcecodepro-nerd xclip unzip
)
```

---

For more technical details go to the official site of
[Arch](https://archlinux.org/).
