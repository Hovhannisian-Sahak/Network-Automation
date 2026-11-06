# Two-router OSPF topology

The current Ansible inventory and host variables already describe this topology:

```text
PC1 -- SW1 -- R1 ===== R2 -- SW2 -- SERVER1
                 OSPF area 0
```

`=====` is the point-to-point router link. Each router-to-switch link is an
untagged access link in that site's LAN VLAN; this is not a router-on-a-stick
design.

## Address plan

| Segment/device | Address | Notes |
|---|---|---|
| R1–SW1 / PC LAN | `10.1.20.0/24` | VLAN 20 |
| R1 LAN interface | `10.1.20.1/24` | PC1 default gateway |
| PC1 | `10.1.20.10/24` | Default gateway `10.1.20.1` |
| R1–R2 transit | `10.0.12.0/30` | R1 `10.0.12.1`, R2 `10.0.12.2` |
| R2–SW2 / server LAN | `10.2.30.0/24` | VLAN 30 |
| R2 LAN interface | `10.2.30.1/24` | Server default gateway |
| SERVER1 | `10.2.30.10/24` | Default gateway `10.2.30.1` |
| R1 / R2 OSPF router IDs | `1.1.1.1` / `2.2.2.2` | Loopback0 addresses |

Both LANs and the transit link are advertised in OSPF area 0. The LAN-facing
interfaces are passive for OSPF; the R1–R2 link is the neighbor-forming link.

## Apply this topology in the repository

1. **Confirm the physical ports.** The current variables assume `R1
   GigabitEthernet0/0` connects to `SW1 GigabitEthernet0/2`, PC1 to `SW1
   GigabitEthernet0/1`, and the corresponding R2/SW2 ports are `Gi0/0` to
   `Gi0/2` and server to `Gi0/1`. Change the interface names in
   `ansible/inventory/host_vars/R1.yml`, `R2.yml`, `SW1.yml`, and `SW2.yml` if
   your devices use different names or cabling.
2. **Set management connectivity.** `ansible/inventory/hosts.yml` (or
   `terraform/terraform.tfvars.example` before generating it) uses
   `192.168.100.101`–`.112` as device management addresses. Ensure each router
   and switch already has a reachable management address, and that your
   Ansible machine can connect to it. The current playbooks do not configure
   switch management SVIs or the management network.
3. **Check VLANs and ports.** `ansible/inventory/group_vars/switches.yml`
   defines VLANs 10, 20, 30, and 99. `SW1.yml` places the PC and router-facing
   access ports in VLAN 20; `SW2.yml` places the server and router-facing
   ports in VLAN 30. Update these values if the cabling or VLAN plan differs.
4. **Check router addressing and OSPF.** `R1.yml` and `R2.yml` define the LAN
   and transit IPs, loopbacks, OSPF area 0, and verification ping targets.
   Keep both transit endpoints in the same `/30`; if changing addresses,
   update the matching OSPF networks and `ping_target` values too.
5. **Configure endpoints.** Give PC1 `10.1.20.10/24`, gateway
   `10.1.20.1`; give the server `10.2.30.10/24`, gateway `10.2.30.1`.
   Endpoint IP settings are not managed by the current Ansible playbooks.
6. **Run from the Ansible directory.** Install the `cisco.ios` and
   `ansible.netcommon` collections if they are not installed, check
   `ansible/inventory/group_vars/all/vault.yml` contains the device
   credentials, then run:

   ```powershell
   cd ansible
   ansible-inventory --graph
   ansible-playbook playbooks/site.yml
   ```

   `site.yml` creates switch VLANs, configures switch access ports, applies
   router interfaces and OSPF, and runs verification. Use
   `ansible-playbook playbooks/verify_routers.yml` and
   `ansible-playbook playbooks/verify_switches.yml` to rerun verification.
7. **Verify end-to-end.** Check that R1 and R2 form an OSPF neighbor, each
   router learns the remote LAN route, and the router verification pings
   succeed. Then ping between PC1 and the server. If router pings succeed but
   endpoint pings fail, check endpoint addressing, default gateways, VLAN
   membership, and host firewalls.

The Terraform configuration only generates the Ansible management inventory;
it does not create or configure the routers, switches, PC, or server.
