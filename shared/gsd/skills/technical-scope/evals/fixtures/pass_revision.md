Broken draft: HTTP from the k8s ingress. This leaves the short form unexplained. It fails. Revision:

You can check that the installed copy matches the playbook copy.

The checker compares the two copies on this computer. It uses the ordinary web protocol (HTTP) only as a name for that comparison. It does not call the network.

```mermaid
flowchart LR
  playbook[Playbook copy] --> check[Version check]
  hub[Installed copy] --> check
```

| Copy | Where it lives |
| --- | --- |
| Playbook | The repository |
| Installed | The skills folder on this computer |

The check prints whether the two copies match.
