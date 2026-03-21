# namespaces and cgroups

this is secret sauce for managing/limiting resources and isolating groups of processes. this is what docker and other container runtimes use to achieve isolation from the host system, and many sandboxing solutions are built on top of this. if you have a basic understanding of how these features work, it will make it much easier to configure the various other sandboxing solutions more precisely, and to audit sandboxes to verify their exact configuration or make find-grained modifications.

this mostly just applies to linux hosts, however, because cgroups and user namespaces are a feature of the linux kernel.

VERDICT: use this because it lets you configure fine-grained resource controls and namespace isolation. an agent started in an isolated cgroup means all subprocesses started by the agent inherit the same configuration. you don't need to use this manually, there are a lot of systems and apps that wrap it. if you don't have systemd, you can use a wrapper like bubblewrap. the 2 off-the-shelf solutions, Claude Code Sandbox Mode and OpenSandbox use bubblewrap to implement their sandboxes.

cgroups are a kernel-level feature that can control, limit, and audit resource usage for specific groups of processes. it can prioritize one group of processes over others. 

- `cgroups` (control groups)
- linux feature that limits, monitors, and isolates resource usage (cpu, mem, disk i/o, etc) of a collection of processes
- this is what docker uses, under-the-hood, and the reason you need Docker Desktop on Mac (it basically installs a linux vm to use a kernel with cgroups)
- cgroups v2 removes ability to use multiple process hierarchies
- v1 and v2 can co-exist on the same system
- features:
    * resource limiting:
        + max memory, including FS cache
        + I/O bandwidth
        + CP quota/set limit
        + max open files
    * prioritization:
        + cpu utilization
        + i/o throughput
    * accounting:
        + measure group's resource usage
        + this is one of the things AWS uses for metered billing
    * control:
        + freezing groups of processes
        + check-pointing and restarting
- use:
    * a control group is applied to a collection of processes that should be bound by the same criteria
    * groups can be hierarchical, meaning each group inherits limits from its parent group
    * kernel provides access to multiple controllers (subsystems) through cgroups interface:
        + "memory" controller limits memory usage
        + "cpuacct" accounts CPU usage
        + etc.
    * how to use:
        + TODO: try each of these
        + accessing cgroup virtual file-system manually
        + creating and managing tools with `cgcreate`, `cgexec`, `cgclassify`, etc.
        + through the "rules engine daemon" that can automatically move processes of certain users/groups/commands to cgroups
        + indirectly through other software, like `Docker`, `Firejail`, `Bubblewrap`, etc.
- interfaces:
    * both versions act through a pseudo-filesystem `cgroup`/`cgroup2`, which can be mounted on any path, but convention is `/sys/fs/cgroup`.
    * files are named based on modules they control: `cpu.stat`, `cpu.pressure`, `io.stat`, `memory.stat`, etc.
    * `cgroup.*` files control the cgroup system itself
    * example: to request kernel to reclaim 1G of memory, from anywhere in the system:
        + `echo "1G swappiness=50" > /sys/fs/cgroup/memory.reclaim`
    * to create a sub-group, create a new directory under an existing group (including the top-level group)
    * the corresponding control files get created automatically:
        + EXAMPLE: `mkdir /sys/fs/cgroup/example; ls /sys/fs/cgroup/example`
    * this adds a lot more control files for fine-grain isolation and control (`pids.*`, `memory.high`, etc)
    * these additional controls only make sense on a specific subset of processes, not on the top-level group
    * processes are assigned to subgroups by writing to `/proc/<PID>/cgroup`. the cgroup of a process can be found by reading the same file.
    * on `systemd` systems, a hierarchy of subgroups is pre-defined to encapsulate every process launched (directly or indirectly) by systemd under a subgroup.
    * `systemd-cgtop` can be used to show top cgroups based on their resource usage
- namespace isolation:
    * not technically part of cgroups, but a related kernel feature
    * groups of processes are separated, so they cannot see resources in other groups:
        + `pid namespace` groups can see processes in their own group, isolated from everything else
        + `network namespace` groups get their own interface controllers, iptables firewall, routing tables, etc.:
            + network namespaces can be connected using teh `veth` device
        + `UTS namespace` the groups get their own hostname (hide real hostname)
        + `mount namespace` you can mount directories into arbitrary paths in the cgroup environment to share only required directories, and also mount read-only directories
        + `ipc namespace` isolates the kernel IPC communication channels from the rest of the system
        + `user namespace` isolates the user ids (and group ids) between namespaces
    * namespaces are created using `unshare` command or syscall, or as the "new" flag for a "clone" syscall.
- network namespace controls allow for tagging all packets from the group in a way they can be detected and managed by an external firewall as well
- accounting features are usually disabled by default, but can be turned on for a sub-tree to see what resources a group is using
- the `freezer` allows you to take a snapshot of a particular process and "move" it (like take a default process and move it to a specific cgroup)
- facilitates fine-grained performance tuning, along with `tuned` for your specific workloads
- `systemd` service units start isolated under `system.slice` cgroup, user proceses under `user.slice`, and vm/container processes under `machine.slice`
- run `systemd-cgls` to see the hierarchy of active groups


- managing cgroups with `cpushares`:
    * cpushares (`cpu.shares`):
        + provides tasks in a group with a relative amount of CPU time (`cpu.shares`)
        + cpu time is determined by dividing the cgroup's CPUShares value by the total number of defined CPUShares on the system.


- managing cgroups without any tooling:
    * groups can be created anywhere on the fs, usually in `/sys/fs/cgroup` by default
    * make top-level directory `mkdir -p /my_cgrups`
    * decide which controllers to use, remembering the controller directory hierarchy structure
    * all groups you create are nested separately under each controller type

- systemd starts all units in the `system.slice` group
- you can configure cgroup settings in a systemd unit file (or by `systemd-set-property`) and systemd will manage the cgroups to satisfy the new settings for the affected unit
- systemd also automatically mounts hierarchies for important kernel resources
- systemd unit types:
    * `service` a process or group of processes, which systemd started based on a unit config file. encapsulate teh specified process so they can be started and stopped as one set.
    * `scope` a group of externally created processes. encapsulate processes that are started and stopped by arbitrary processes through the `fork()` function and then registered with systemd a runtime. user sessions, containers, vms, etc.
    * `slice` a group of hierarchically organized units. a slice does not contain processes, they organize a hierarchy in which `services` and `scopes` are placed.
    * all users are assigned an implicit subslice of user.slice
    * the system admin can define new slices and assign services and slices to them.
- TODO: man pages: `systemd.resource-control`, `systemd.unit`, `systemd.slice`, `systemd.scope`, `systemd.service`


- using cgroups with systemd:
    * probably a better way of managing groups than just manually creating files and folders
    * also a more modern solution than using the old `libcgroup` package
    * creating control groups:
        + from systemd's perspective, a cgroup is bound to a system unit configurable with a unit file and managable with systemd's cli utilities
        + depending on the type of application, settings can be transient or persistent
        + to create a transient cgroup for a service:
            + start the service with `systemd-run`
            + this makes it possible to set limits on the service during its runtime
            + create transient cgroups dynamically by using API calls to systemd
            + the transient unit is removed automatically as soon as the service has stopped
            + creating transient cgroups with systemd-run:
                + used to create and start a transient service or scope unit and run a custom command in the unit
                + commands executed in the service units are started async in the background
                + commands run in `scope` units are started directly from `systemd-run` process and inherit execution env of the caller. execution is sync in this case.
                + `systemd-run --unit=name --scope --slice=slice_name command`:
                    + `--unit` is the name. if not specified, one will be generated automatically. choose a descriptive name, because it will represent the unit in `systemctl` output.
                    + `--scope` create a transient `scope` unit, instead of a `service` unit (default)
                    + with `--slice`, make newly created service or scope unit a member of a specific slice. pass name of existing slice, or use a unique name to create a new slice.
                    + by default, services and scopes are created as members of `system.slice`
                    + other parameters:
                        + `--description`
                        + `--remain-after-exit` allows collection of runtime info after a service process terminates
                        + `--machine` executes the command in a confined container:
                            + TODO: more on this ^ (see `systemd-run (1)`)
                        + if you start a unit as a service, it becomes `<UNIT>.service`
        + persistent cgroups:
            + `systemctl enable`
            + automatically creates a unit file in `/usr/lib/systemd/`
            + to make persistent modifications, edit its unit file
    * removing control groups:
        + `systemctl stop name.service`
        + `systemctl kill name.service --kill-who=PID,... --signal=signal`:
            + `--kill-who` selects a process from the cgroup to terminate
            + use comma-separated lists of PIDs to kill multiple processes
            + replace `signal` with the signal you want to send (`SIGTERM`)
            + persistent cgroups are released when the unit is disabled and its configuration file is deleted by running `systemctl disable name.service`
    * modifying control groups:
        + modify unit config file under `/usr/lib/systemd/system`, manually from cli or by using `systemctl set-property` command.
        + `systemctl set-property name parameter=value`:
            + not all params can be changed at runtime, but most related to resource controls may
            + changes applied instantly and written into the unit file so they are preserved after reboot
            + you can change that behavior by using `--runtime` to make the changes transient
        + modifying unit files:
            + managing cpu:
                + cpu controller enabled by default, in kernel, so every system service gets the same amount of cpu time, regardless of how many processes it contains
                + this can be changed with `DefaultControllers` parameter in the service unit file
                + `[Service] CPUShares=value`:
                    + default 1024
                    + increasing the number assigns more cpu time to the unit
                    + automatically turns on `CPUAccounting` for the unit
                    + users can thus monitor cpu usage with `systemd-cgtop`
                    + controls the `cpu.shares` control group parameter
            + to apply changes: `systemctl daemon-reload` then `systemctl restart name.service`
    * getting info about cgroups:
        + `systemctl list-units`, `cgls [name|controller]`, `cgtop`, `systemctl status name`
        + those commands enable monitoring higher-level unit hierarchies, but do not show which resource controllers in linux kernel are actually used by which processes:
            + `cat /proc/PID/cgroup`
            + examine this file to determine if the process has been placed in the correct cgroups

- managing namespaces with unshare (creates cgroups):
    * `unshare [options] [program [arguments]]`
    * `unshare (1)`
    * `unshare` creates new namespaces and executes the specified program
    * by default, new namespace persists only as log as it has member processes
    * new namespace can be made persistent by bind-mounting /proc/pids/ns/type files to a file-system path; can be entered with `nsenter` after the program terminates; can be unmounted later with umount
    * `--fork` for specified program as child process of `unshare`; necessary for PID namespaces
    * `--setgroups deny` deny setgroups(d) syscall in user namespace
    * `--root dir` set root dir (like chroot?)
    * `--mount-proc` mounts the proc filesystem. useful for new PID namespace. implies creating a new mount namespace. new proc filesystem is explicitly mounted as private.
    * persistent mount namespace:
        + `mount --bind /root/namespaces /root/namespaces`
        + `mount --make-private /root/namespaces`
        + `touch /root/namespaces/mnt`
        + `unshare --mount=/root/namespaces/mnt`
    * `unshare --pid --fork --mount-proc -- bash`:
        + `ps aux`

- working with namespaces:
    * `lsns` to list namespaces
    * `nsenter`:
        + run a program with the namespaces of another process
        + `nsenter [options] [program [arguments]]`:
        + `-t, --target PID`
        + namespace specific, example: `-n, --net[=file]` if no file, enter the namespace of the target pid
        + `-c --cgroup[=file]` if no file, enter the cgroup namespace of the target pid
    * `ip netns` manage network namespaces
    * `ipcs` (ipcs in namespace), `ipcmk -Q` (create a message queue), `ipcmk -M` (create a shared memory)

example: `unshare --user --pid --map-root-user --mount-proc --fork chroot $HOME/test /bin/bash`

- network namespaces:
    * https://www.dotlinux.net/linux-networking-guide/linux-network-namespaces-an-introductory-guide/
    * add an ns: `ip netns add ns1`
    * list active ns(es): `ip netns list`
    * run a command in a ns: `ip netns exec COMMAND [ARGS]`
    * `ip netns exec ip link show` (should have only lo by default)
    * enable lo: `sudo ip netns exec ns1 ip link set lo up`
    * delete: `ip netns delete ns1`
    * connect namespaces with `veth` or a bridge device
    * docker's `bridge` network device creates a bridge and veth pairs to connect containers
    * avoid running unprivileged commands in namespaces with root user. use `--user` where possible:
        + `sudo ip netns exec ns1 runuser -u <user> -- <command>`
    * monitor namespace traffic: `sudo ip netns exec ns1 tcpdump -i veth-ns1`
    * i think we can create a ns manually, then use `unshare --net=/path/to/ns/mount`?
    * or else you can run `nsenter` first, or use `ip ns exec -- unshare ... -- cmd`?

- `veth`:
    * virtual network devices that can tunnel between namespaces and connect to physical interfaces
    * always created in interconnected pairs
    * `ip link add <p1-name> type veth peer name <p2-name>`
    * link two netns: `ip link add <p1-name> netns <p1-ns> type veth peer <p2-name> netns <p2-ns>`

this appears to be how to bridge the netns with the system:
```bash
ip link add veth0 type veth peer name veth1 netns test_ns
ip link set veth0 up
ip netns exec test_ns ip link set veth1 up
ip netns exec test_ns ip addr add 192.168.10.1/24 dev veth1
ip addr add 192.168.10.2/24 dev veth0
ip netns exec test_ns ip link set lo up
ip link set lo up
```
then set the default gateway to allow network access:
```bash
ip netns exec test_ns ip route add default via 192.168.10.1
ip netns exec test_ns ip route list
```

bridge multiple veth pairs with bridge:
```bash
ip link add br0 type bridge
ip link set br0 up
ip link set veth0 master br0
ip netns exec test_ns ip link set veth1 master br0
```

# control group application examples

## prioritized db i/o

running each db instance in its own dedicated virtual guest allows you to allocate resources per db based on their priority.

example:
-  a system running 2 dbs inside 2 kvm guests
-  one db is high-priority, the other low-priority
-  when both db servers are run simultaneously, the i/o throughput is decreased to accommodate both dbs equally
-  to prioritize high priority db over low, it can be assigned to a group with a high number of reserved i/o operations, and the low db can be assigned to a group with a low reserve:
    * `systemctl set-property db1.service BlockAccounting=true`
    * `systemctl set-property db2.service BlockAccounting=true`
    * set a ratio of 10:1
    * `systemctl set-property db1.service BlockIOWeight=1000`
    * `systemctl set-property db2.service BlockIOWeight=100`
-  alternatively, block device i/o throttling can be used for low priority db using `blkio` controller

## prioritizing network traffic

assign packets originating from certain services to have higher priority than others.

`net_prio` controller can set network priorities for processes in cgroups, translated into ToS field bits embedded in every packet

# demos

## manual cgroup management

```bash
# in one terminal, start bash and then get the PID with $$
exec bash

# in the bash shell, find the PID of the running shell
echo $$
#   16102

# now run `nproc` to list how many CPU cores are available to use
nproc
#   16
# (depends on your CPU)
```

```bash
# inspect top-level cgroup and nested groups/slices
ls /sys/fs/cgroup
cat /sys/fs/cgroup/cpu.stat
cat /sys/fs/cgroup/system.slice/memory.max

# make a new cgroup
sudo mkdir /sys/fs/cgroup/example
# automatically contains a bunch of controllers you can use
ls /sys/fs/cgroup/example

# set a resource limit: limit to only cpu cores 1+2
# first you have to become super-root.
# use ctrl+d or `exit` to drop back to unprivileged shell as soon as you are done
sudo su -
echo 1,2 > /sys/fs/cgroup/example/cpuset.cpus
# ctrl+d
```

```bash
# checkout the default cgroup for your bash process
cat /proc/16102/cgroup
#   0::/user.slice/user-1001.slice/user@1001.service/tmux-spawn-283a2254-2b90-4511-b2ba-2b82d0277d38.scope
# your result will be different, but should be under `user.slice/user-UID.slice` if you happen to use systemd.

# move the process to another group.
# first you have to become super-root.
# use ctrl+d or `exit` to drop back to unprivileged shell as soon as you are done
sudo su -
echo 16102 > /sys/fs/cgroup/example/cgroup.procs
# ctrl+d

# verify it is in the new group
cat /proc/16102/cgroup
#   0::/example
```

```bash
nproc
#   2

# exit and end the managed bash process
exit
```

## manual namespaces using unshare

https://arianfm.medium.com/namespaces-and-cgroups-in-linux-197a4368bf18

- [x] create and configure a netns
- [ ] start a program with unshare (network and some binds)
- [ ] inspect the cgroup
- [ ] demo effect
- [ ] configure firewall
- [ ] demo effect
- [ ] make a persistent netns

```bash
sudo ip netns add ns1
sudo ip netns list
sudo ip netns exec ns1 ip link show
#   shows only lo: DOWN
sudo ip netns exec ns1 ip link set lo up

sudo ip link add veth0 type veth peer name veth1 netns ns1
# setup the system-side of the pair
sudo ip link set veth0 up
# setup the ns-side of the pair
sudo ip netns exec ns1 ip link set veth1 up
sudo ip netns exec ns1 ip addr add 192.168.2.1/24 dev veth1

# set ns1 default route to veth0
sudo ip netns exec ns1 ip route add default via 192.168.2.2
# add an ip on the system namespace to bridge the connections.
sudo ipaddr add 192.168.2.2/24 dev veth0

# so far, this only lets me connect to host system but not the rest of the network or the internet.

# check if ip-forwarding is enabled:
sudo cat /proc/sys/net/ipv4/ip_forward
#   1 = on
#   0 = off
#   if not, `sudo echo 1 > /proc/sys/net/ipv4/ip_forward`

# at this point, I can ping to/from the ns and the host network, but not beyond that.

# check default policy (probably ACCEPT)
sudo ip netns exec ns1 iptables -L FORWARD
# set default policy to DROP
sudo ip netns exec ns1 iptables -P FORWARD DROP

# check nat rules
sudo iptables -t nat -L
# replace wlp0s20f3 with your actual device name
sudo iptables -t nat -A POSTROUTING -s 192.168.2.0/255.255.255.0 -o wlp0s20f3 -j MASQUERADE
sudo iptables -A FORWARD -i wlp0s20f3 -o veth0 -j ACCEPT
sudo iptables -A FORWARD -o wlp0s20f3 -i veth0 -j ACCEPT

# if it all worked, should be able to ping outside of the network now

# TODO:
# now say you have a service on port 8888 in ns1 and you want it to be reachable from outside
sudo iptables -t nat -A PREROUTING -p tcp -i wlp0s20f3 --dport 8888 -j DNAT --to-destination 192.168.2.1:8888
sudo iptables -A FORWARD -p tcp -d 192.168.2.1 --dport 8888 -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT
```

TODO: persisting namespaces and cgroup
run `unshare` with on of the `--namespace[=file]` arguments, like `--net`, or `--cgroup`.
the namespace will be mounted to that file location so you can re-use it.

```bash
ROOT=/tmp/testroot
# NOTE: mount file must be in /var/run/netns to use `ip netns` and `unshare`
NETNS=/var/run/netnts/daveshield-ns

# TODO: i don't actually know how to manage a mount ns...
mkdir -p "$ROOT"/{chroot,namespaces}
# TODO: why binding a dir to itself? did i get this wrong?
# - mounting a path to itself is just a way to meet the requirement of being a
#   'mount point' for later use.
mount --bind "$ROOT"/namespaces "$ROOT"/namespaces
mount --make-private "$ROOT"/namespaces
touch "$ROOT"/namespaces/mnt

# https://unix.stackexchange.com/questions/456620/how-to-perform-chroot-with-linux-namespaces
unshare --mount="$ROOT"/namespaces/mnt -- bash
cd "$ROOT"/

touch "$NETNS"
unshare --net="$NETNS" -- ip netns list
# setup net ns, nat, and firewall

# TODO move other ns files under "$ROOT"/namespaces

touch "$ROOT"/uts-ns
unshare --uts="$ROOT"/uts-ns hostname SANDBOX

# TODO: not sure how the cgroup binding works
touch "$ROOT"/cgroup

unshare \
    --user \
    --ipc \
    --uts="$ROOT"/uts-ns \
    --net="$NETNS" \
    --cgroup="$ROOT"/cgroup \
    --mount="$ROOT"/namespaces/mnt
    --pid --fork --mount-proc \
    /run/current-system/sw/bin/bash 
```

for agent sandboxing, i'm more interested in white-listing domains than managing iptables. however, this adds another layer of defense. you can use it to black-list/white-list ip ranges, or use it together with an iprep database to block potentially dangerous ips.

TODO: idea for using squid: `agent ns (iptables) => squid ns (domains) => system network`

## use it to run an isolated agent

concerned more with namespace isolation than with resource management.

- pid isolation
- mount namespace
- user namespace
- ipc namespace
- no network / firewall
- tagging network traffic

# pros/cons

# how does it meet the objective requirements?
