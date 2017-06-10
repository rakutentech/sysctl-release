# BOSH sysctl Release

BOSH Release that enables modification of sysctl variables (kernel state)

## Deploying

Upload release:

```
bosh upload-release https://github.com/cloudfoundry-community/sysctl-release/releases/download/v2/release.tgz
```

Then proceed to configure it as appropriate for your use cases.

## Configuring sysctl

In this example, we increase the sysctl variable `net.nf_conntrack_max` to eliminate dropped packets. We believe that [nf_conntrack](https://www.kernel.org/doc/Documentation/networking/nf_conntrack-sysctl.txt) was enabled as a side-effect of running Docker containers (Concourse workers). Coupled with running a public NTP server with hundreds of thousands of clients, this exhausted the kernel's nf_conntrack table. The symptoms were `nf_conntrack: table full, dropping packet` messages in syslog, `connect: Network is unreachable` messages in Concourse jobs, and dropped packets from NTP clients.

```yaml
releases:
  name: sysctl
  version: latest
...
instance_groups:
- release: sysctl
  properties:
    sysctl_conf:
      # fixes: `nf_conntrack: table full, dropping packet`
    - {name: net.nf_conntrack_max, value: 524288}
```

Other common sysctl use cases include:

- Increase `net.core.somaxconn` to avoid dropping incoming TCP connections
- Increase `net.core.rmem_max` and `net.core.rmem_default` to avoid dropping incoming UDP traffic
- Decrease `vm.swappiness` to avoid swapping out memory allocated by running processes

## Duck taping

This release also allows to run arbitrary commands in response to standard bosh lifecycle events (pre-start, post-start, post-deploy, drain).

In the following example we set a custom `/etc/issue` message, which we clear out when the instance is stopped.

Note: The `bash_*_snippet` properties are meant to be used as duct tape to hold things in place long enough for a more robust and permanent solution.

```yaml
instance_groups:
- release: sysctl
  properties:
    bash_pre_start_snippet: |
      echo 'Authorized Users Only' > /etc/issue
    bash_drain_snippet: |
      > /etc/issue
```

## Examples

- a [production BOSH manifest](https://github.com/cunnie/deployments/blob/f6a9fdc6ac3f7bfd514e8ea42175514d4491c3cb/concourse-ntp-pdns-gce.yml) which uses the sysctl BOSH release

## Developer Notes

Restraint and caution should be exercised when using the `bash_*_snippet` properties: consider using custom BOSH releases instead.

By default this release creates a `sysctl` configuration in `/etc/sysctl.d/61-bosh-sysctl-release.conf`; this _should_ override any settings in the stemcell (typically `/etc/sysctl.d/60-*`), but this is a non-contractual dependency (A stemcell may have, for example, a `/etc/sysctl.d/62-*` file which would override any settings in the file created by this release). If required the default file prefix can be changed by specifying a different prefix in the `sysctl_conf_prefix` property.
