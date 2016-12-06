# BOSH sysctl Release

BOSH Release that enables modification of sysctl variables (kernel state)

## HOWTO

Upload release:

```
bosh upload-release https://github.com/cloudfoundry-community/sysctl-release/releases/download/v1/sysctl-1.tgz
```

In this example, we increase the sysctl variable `net.nf_conntrack_max` to
eliminate dropped packets. We believe that
[nf_conntrack](https://www.kernel.org/doc/Documentation/networking/nf_conntrack-sysctl.txt)
was enabled as a side-effect of running Docker containers (Concourse workers).
Coupled with running a public NTP server with hundreds of thousands of clients,
this exhausted the kernel's nf_conntrack table. The symptoms were `nf_conntrack:
table full, dropping packet` messages in syslog, `connect: Network is
unreachable` messages in Concourse jobs, and dropped packets from NTP clients.

```yaml
releases:
  name: sysctl
  version: latest
...
instance_groups:
- release: sysctl
  properties:
    sysctl_conf: |
      # fixes: `nf_conntrack: table full, dropping packet`
      net.nf_conntrack_max=524288
```

In this example we also set a custom `/etc/issue` message, which we clear out
when the sysctl job is stopped.

Note: The `bash_start_snippet` and `bash_stop_snippet`
properties are meant to be used as duct tape: hold things in place long enough
for a more robust and permanent solution.

```yaml
instance_groups:
- release: sysctl
  properties:
    bash_start_snippet: |
      echo 'Authorized Users Only' > /etc/issue
    bash_stop_snippet: |
      > /etc/issue
```


## Examples

Here is a [production BOSH manifest](https://github.com/cunnie/deployments/blob/f6a9fdc6ac3f7bfd514e8ea42175514d4491c3cb/concourse-ntp-pdns-gce.yml) which uses the sysctl BOSH release.

## Developer Notes

Restraint and caution should be exercised when using `bash_start_snippet`
and `bash_stop_snippet`: consider using custom BOSH releases instead.

This release creates a `sysctl` configuration in
`/etc/sysctl.d/61-bosh-sysctl-release.conf`;  this _should_ override any
settings in the stemcell (typically `/etc/sysctl.d/60-*`), but this is a
non-contractual dependency (A stemcell may have, for example, a
`/etc/sysctl.d/62-*` file which would override any settings in the file created
by this release).
