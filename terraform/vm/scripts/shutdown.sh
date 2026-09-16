#!/bin/bash
# Save the world cleanly before the disk detaches. Nothing else: preemption is
# announced by /opt/scripts/watch_preemption.sh, which reacts the moment Google
# flips the metadata flag instead of racing systemd here. Keeping the notify out
# of this script means one notifier, and leaves the whole shutdown budget for
# the save -- rcon stop blocks until the world is written, and a preempted Spot
# instance only gets about 30 seconds.

sudo docker exec mc rcon-cli stop
