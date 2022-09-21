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

By default the script has the following configuration (also +2G for swap partition):
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

Before running the script, you should edit `install.sh` with `nano` (`vim` isn't shipped):
```bash
nano install.sh
```

and then apply changes, for example:

```bash
readonly HOSTNAME='awesome-arch'
readonly TIMEZONE='America/California'
readonly KEYMAP='us'
readonly ROOT_PASSWORD='superstrongpassword'
readonly USER_NAME='archlover'
readonly USER_PASSWORD='iusearchbtw'

readonly SHOW=false
# readonly SHOW=true
readonly ASK=false
# readonly ASK=true
```

To change the size of the swap partition to +8G for example, edit line 122:
```bash
  +2G # 2 GB swap partition by default
```

to this (you can delete the comment):
```bash
  +8G # 8 GB swap partition
```


---

For more technical details go to the official site of
[Arch](https://archlinux.org/).
