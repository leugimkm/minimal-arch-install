# Minimal Arch Installation

Simply boot into a live Arch Linux ISO, download the script (using `curl`) and execute `install.sh`.

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
```bash
readonly HOSTNAME='arch'
readonly TIMEZONE='America/Lima'
readonly KEYMAP='us'
readonly ROOT_PASSWORD='root'
readonly USER_NAME='bot'
readonly USER_PASSWORD='bot'

# readonly SHOW=false
readonly SHOW=true
# readnly ASK=false
readonly ASK=true
```

Before running the script, you should edit `install.sh` with `nano` (`vim` isn't shipped)
```bash
nano install.sh
```

---

For more technical details go to the official site of
[Arch](https://archlinux.org/).
