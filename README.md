
# How To Set It All Up

## Run a Puppetserver

### Get the latest Docker image

Download the Docker image for a standalone Puppetserver.

```bash
# docker pull puppet/puppetserver
```

---

### Docker volumes

This worked for me on a stand-alone debian-jessie Docker server.

```bash
# docker run -d --name puppet --publish 8140:8140 --mount source=puppet,target=/etc/puppetlabs  --mount source=puppet-data,target=/opt/puppetlabs/server/data -e PUPPETSERVER_JAVA_ARGS="-Xms384m -Xmx384m -XX:MaxPermSize=256m" -h puppet puppet/puppetserver
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
```

Create a directory to hold the r10k config.

```bash
# docker exec -t puppet bash -c "mkdir /etc/puppetlabs/r10k"
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

Have the container update the r10k environments.

```bash
# docker exec -t puppet bash -c "r10k deploy environment -p"
```

You now have a Puppetmaster running on your Docker server that is accessible on port 8140 that can be used with a development workflow.
