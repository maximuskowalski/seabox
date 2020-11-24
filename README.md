# seabox

A cloudbox remote transformer.
Takes a list of sharedrives and creates rclone VFS union mount.

Requires rclone beta 1.53 and above, recommend beta to avoid the cache _stickies_.

You will need a service account file with access to the drives you wish to mount. You can edit your rclone config manually afterwards if you wish to set an account file per mount. Automation not yet built in.

### Minimal instructions.

Set variables. Run with `./seabox.sh sharedrive.set` Gitclone not really needed.

### Install

1. Change to your install dir and git clone:  
   `cd /opt`

`git clone https://github.com/maximuskowalski/seabox.git && cd seabox`

2. Make the `seabox.sh` file executable:

`chmod +x seabox.sh`

3. Open the file and set your variables

`nano seabox.sh`

```
# Variables
USER=seed  # username
GROUP=seed # group
#
SET_DIR=/home/max/seabox/sets  # set files location
SA_FILE=/opt/sa/mount/1.json   # service account file for auth
SA_PATH=/opt/sa/mount          # service account files location
TAG="nc"                       # ro or nc to tag the remote as read only or no create
VFSMAX=100G                    # vfs-cache-max-size limit
CPORT=1                        # not used

#cloudbox defaults
MOUNTNAME=google      # we will be replacing this mount with the union of share drives
MOUNT_DIR=/mnt/remote # mount point of remote
MRG_DIR=/mnt/unionfs  # not used
MPORT=5572            # rc port
```

### Make Setfiles

Copy the sample set before editing:  
`cp /opt/seabox/sets/example.set.sample /opt/seabox/sets/my.set`

Edit the set file to add in the drive names and TD IDs:  
`nano /opt/seabox/sets/my.set`

### Run

Run the script with the set for your mountstyle.

`./seabox.sh aio.set`

## Support on ~~Beerpay~~ Github Sponsors

Hey dude! Help me out for a couple of :beers:!

https://github.com/sponsors/maximuskowalski

[![Buy me a coffee][buymeacoffee-shield]][buymeacoffee]

[buymeacoffee-shield]: https://www.buymeacoffee.com/assets/img/guidelines/download-assets-sm-2.svg
[buymeacoffee]: https://github.com/sponsors/maximuskowalski
