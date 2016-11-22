# BOSH sysctl Release

BOSH Release that enables modification of sysctl variables (kernel state)

## HOWTO

Upload release:

```
bosh upload-release FIXME
```

In this example, we increase the sysctl variable `net.nf_conntrack_max` to
eliminate dropped packets. We believe that [nf_conntrack](https://www.kernel.org/doc/Documentation/networking/nf_conntrack-sysctl.txt)
was enabled as a side-effect of running Docker containers (Concourse workers). Coupled with
running a public NTP server with hundreds of thousands of clients, this exhausted
the kernel's nf_conntrack table. The symptoms were `nf_conntrack: table full, dropping packet`
in syslog and

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

## Developer Notes

This release creates a `sysctl` configuration in
`/etc/sysctl.d/61-bosh-sysctl-release.conf`;  this _should_ override any
settings in the stemcell (typically `/etc/sysctl.d/60-*`), but this is a
non-contractual dependency (A stemcell may have, for example, an
`/etc/sysctl.d/62-*` file which would override any settings in the file created
by this release).
