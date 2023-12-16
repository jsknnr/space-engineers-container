# space-engineers-container
It is painful to run Space Engineers dedicated in a container but here we are. Image is Debian 12 with Wine 8 and Winetricks.

## Usage
The container does not run as the root user, it runs as the user steam (uid/gid 1000:1000). Mounted directories should have the correct ownership. Really you should use a volume though. 

**Before** running the container you will need to generate new world files and config from the Windows version of the dedicated server utility. There is no way around this unless I include a stub in this repo which I am not going to do because that would be poor practice. There are guides out there for doing this already, so I won't do that here. The files should be mounted into the container at `/home/steam/space-engineers/world` with the `SpaceEngineers-Dedicated.cfg` and the `Saves` directory both present in `world`. The world directory is the only directory that is persistent, so just 1 volume is needed. 

I have also included some logic in the startup that if you provide the variable `WORLD_ZIP_URL` it will reach out to the url (Dropbox, Google Drive, S3, etc) and download a zip file (must be a zip) that contains your world config and Saves that you have generated. Providing the optional variable `OVERWRITE` and setting to string `true` will overwrite the contents of `world` if it detects an existing world. I built this functionality for myself as I use Kubernetes to orchestrate all of my containers and I don't want to mess around with manually putting files in container volumes.

### Ports

| Port | Protocol | Default |
| ---- | -------- | ------- |
| Game Port | UDP | 27016 |

### Environment Variables

| Name | Description | Default | Required |
| ---- | ----------- | ------- | -------- |
| WORLD_ZIP_URL | Unauthenticated URL to ZIP file contents of previously created world | None | False |
| OVERWRITE | When using WORLD_ZIP_URL overwrite contents of world directory if existing | False | False |

### Docker

To run the container in Docker, run the following command:

```bash
mkdir se-persistent-data
docker run \
  --detach \
  --name space-engineers-server \
  --mount type=bind,source=$(pwd)/se-persistent-data,target=/home/steam/space-engineers/world \
  --publish 27016:27016/udp \
  sknnr/space-engineers-dedicated-server:latest
```
Optional environment variables not included in above example as most users will probably not use them.

Where ever you create the `se-persistent-data` directory is where the world save is going to go. If you delete that directory you will lose your save. That directory will be mounted into the container.

**Notice:**
The above example uses a bind mount. From my research you may get better performance if you create a docker volume and then attach that volume to the container on run time. Documentation for that is here: https://docs.docker.com/engine/reference/commandline/volume_create/ and a StackOverflow thread on seeding a volume here: https://stackoverflow.com/questions/37468788/what-is-the-right-way-to-add-data-to-an-existing-named-volume-in-docker

### Kubernetes

I've built a Helm chart and have included it in the `helm` directory within this repo. Modify the `values.yaml` file to your liking and install the chart into your cluster. Be sure to create and specify a namespace as I did not include a template for provisioning a namespace.
