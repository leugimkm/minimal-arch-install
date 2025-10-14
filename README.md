![](assets/archlinux_logo.png)

# Minari

(Min)imal (Ar)ch (I)nstallation is a simple installation script design to set up
your system with minimal user interaction.

Simply boot into a live Arch Linux ISO, download the script (using `curl`), edit
the script if needed, and run it to install a minimal base system.

Feel free to download, edit, clone, fork or open an issue.

## Usage

1. Download the script:

   ```sh
   curl -LO https://github.com/leugimkm/minimal-arch-install/raw/dev/minari.sh
   ```

   or:

   ```sh
   curl -LO https://raw.githubusercontent.com/leugimkm/minimal-arch-install/dev/minari.sh
   ```

2. Make the script executable:

   ```sh
   chmod +x minari.sh
   ```

3. (***Optional***) Edit the configuration:

   The script contains defaults settings that
   you can customize using your preferred text editor:

   ```sh
   vim minari.sh
   ```

4. Run the installer:

   Modify values as needed (see [Configure](#configure) section below):

   ```bash
   ./minari.sh
   ```

   You may also provide additional flags (see more using `--help`):

   - Automatic mode with preset configuration:
     ```bash
     ./minari.sh --auto
     ```

   - Interactive configuration mode
     ```bash
     ./minari.sh --config
     ```

   - Force BIOS mode
     ```bash
     ./minari.sh --auto --bios
     ```

   - Force UEFI mode
     ```bash
     ./minari.sh --auto --uefi
     ```

## Configure

By default, the script is preconfigured as follows:

```sh
readonly AUTO=false
readonly TIMEZONE='America/Lima'
readonly LOCALE='en_US.UTF-8'
readonly KEYMAP='us'
readonly ROOT_PASSWORD='root'
readonly DISK='/dev/sda'
readonly RESOLUTION='1920x1080'
readonly KERNEL='linux'
HOSTNAME='MinArI'
USER_NAME='guest'
USER_PASSWORD='guest'
SWAP_SIZE=2
BOOT_LOADER='UEFI'
```

Before running the script, edit `minari.sh` with an editor like `nano` or `vim`
to adjust these settings. For example:

```bash
readonly AUTO=true
readonly TIMEZONE='America/New_York'
readonly LOCALE='es_ES.UTF-8'
readonly KEYMAP='es'
readonly ROOT_PASSWORD='superstrongpassword'
readonly DISK='/dev/nvme0n1'
readonly RESOLUTION='2560x1440'
readonly KERNEL='linux-lts'
HOSTNAME='ArchBox'
USER_NAME='archlover'
USER_PASSWORD='iusearchbtw'
SWAP_SIZE=4
BOOT_LOADER='BIOS'
readonly EXTRA_PACKAGES=(
  sudo grub networkmanager git wget ttf-sourcecodepro-nerd xclip unzip
)
```

## Rollback Funcionality

If you cancel the installation or an error occurs, the rollback function will:
- Disable active swap
- Unmount all mounted partitions
- Flush pending writes with `sync`
- Erase residual filesystem signatures (using `wipefs`)
- Wipe the partition table (using `sgdisk --zap-all` or `dd`)
- Trigger the kernel to re-read the partition table via `partprobe`.

This ensures that the disk is completely clean, avoiding errors before
re-running the installation.

---

For further technical details, check out the [official Arch Linux websie](https://archlinux.org/).
