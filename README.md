
# How To Set It All Up

## Run a Puppetserver

### Get the latest Docker image

Download the Docker image for a standalone Puppetserver.

```bash
# docker pull puppet/puppetserver-standalone
```

---

##### Local Docker

This is the process I followed on my local machine (a Macbook Pro) - it uses a lot of cpu on the local fs mounts.

Start the puppetserver, wait for it to boot completely (docker logs -f puppet) and then run puppet to generate the certs. Shut the container down.

```bash
# docker run -d --name=puppet \
-e PUPPETSERVER_JAVA_ARGS="-Xms384m -Xmx384m -XX:MaxPermSize=256m" \
-p 0.0.0.0:8140:8140 -h puppet puppet/puppetserver-standalone
a23d9a4ae20999377fa129e37c754b43ef70d454163f3f0e97f4cd078210b100
```

Wait for the service to be up and accepting requests (you will see the HTTP 200 results in the logs), then stop it.

```bash
# docker stop puppet
```

Create a local directory to keep the service files for Puppet and copy the files from the container to your local filesystem. Remove the container when done.

```bash
# mkdir -p docker/puppet
# docker cp puppet:/etc/puppetlabs docker/puppet/
# docker cp puppet:/opt/puppetlabs/server/data docker/puppet/data
# docker rm -f puppet
```

Run a new instance of the container with these local service files.

```bash
# docker run -d --name=puppet --restart=always -v ${PWD}/docker/puppetlabs:/etc/puppetlabs -v ${PWD}/docker/data:/opt/puppetlabs/server/data -e PUPPETSERVER_JAVA_ARGS="-Xms384m -Xmx384m" -h puppet puppet/puppetserver-standalone
```

#### Alternate - Docker volumes

This worked for me on a stand-alone debian-jessie Docker server.

```bash
# docker run -d --name puppet --publish 8140:84140 --mount source=puppet,target=/etc/puppetlabs  --mount source=puppet-data,target=/opt/puppetlabs/server/data -e PUPPETSERVER_JAVA_ARGS="-Xms384m -Xmx384m -XX:MaxPermSize=256m" -h puppet puppet/puppetserver-standalone
```

---

### r10k

Once the host has completed booting, we will need to install support for r10k and encrypted yaml.

```bash
# docker exec -t puppet bash -c  "gem install r10k"
# docker exec -t puppet bash -c  "gem install hiera-eyaml"
# docker exec -t puppet bash -c  "puppetserver gem install hiera-eyaml"
```

Create a set of keys for this Puppetmaster and stop this container.

```bash
# docker exec -t puppet bash -c "eyaml createkeys --pkcs7-private-key /etc/puppetlabs/puppet/eyaml/private_key.pkcs7.pem --pkcs7-public-key=/etc/puppetlabs/puppet/eyaml/public_key.pkcs7.pem"
# docker stop puppet
```

Create a directory to hold the r10k config.

```bash
mkdir docker/puppet/puppetlabs/r10k
```

Create a config to pull this control repo from Gitlab. This is a throw-away token that can be re-used or other configs can be used (e.g. ssh key).

```bash
---
# The location to use for storing cached Git repos
cachedir: '/var/cache/r10k'

# A list of git repositories to create
sources:
  # This will clone the git repository and instantiate an environment per
  # branch in /etc/puppet/environments
  auto-puppet:
    remote: 'https://github.com/cudgel/splunk-testing.git'
    basedir: /etc/puppetlabs/code/environments
```

```bash
# docker cp r10k.yaml puppet:/etc/puppetlabs/r10k/r10k.yaml
```

Start the container with the r10k config and wait for the service to be ready.

```bash
docker start puppet
```

Have the container update the r10k environments.

```bash
docker exec -t puppet bash -c "r10k deploy environment -p"
```

You now have a Puppetmaster running on your Docker server that is accessible on port 8140 that can be used with a development workflow.
