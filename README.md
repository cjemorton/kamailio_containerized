# kamailio_containerized

This project is for standing up a kamailio instance in a Rocky 8 linux installation inside of a lxe container.

### The project is under development. ###



# Install LXC On system.
```bash
curl -sSL https://raw.githubusercontent.com/cjemorton/kamailio_containerized/main/install_lxc.sh | bash
```
-------------------------

# Run.
- This is the script that stands up a container, creates a snapshot, then installs kamailio in that snapshot.
- You may have to download the script and pass it parameters, or edit the string with the correct flags for what you want to do.
```bash
curl -sSL https://raw.githubusercontent.com/cjemorton/kamailio_containerized/main/run.sh | bash
```

-------------------------


# NOTES: 

While I trust my own code enought to run it directly from a curl like this, it is always best practice to not. This is just here for my own convenience, use it if you want.
