# FastNear Static scripts

## Update boot nodes

To update boot nodes for the **mainnet**, run the following command (replace `~/.near/config.json` with the path to your `config.json` file):

```bash
curl --proto '=https' --tlsv1.2 -sSf https://raw.githubusercontent.com/fastnear/static/refs/heads/main/update_boot_nodes.sh | bash -s -- mainnet ~/.near/config.json
```

To update boot nodes for the **testnet**, run the following command (replace `~/.near/config.json` with the path to your `config.json` file):

```bash
curl --proto '=https' --tlsv1.2 -sSf https://raw.githubusercontent.com/fastnear/static/refs/heads/main/update_boot_nodes.sh | bash -s -- testnet ~/.near/config.json
```

## Snapshots (retired)

Self-serve snapshot downloads were discontinued on **2025-06-01**, and the
snapshot host the scripts here pointed at (`snapshot.fastnear.xyz`) no longer
exists. RPC and archival snapshots are available **on request** at
[fastnear.com/snapshots](https://fastnear.com/snapshots) or
snapshots@fastnear.com.

`down_rclone.sh` and `down_rclone_archival.sh` now print that notice and exit;
their final versions are preserved under [`deprecated/`](./deprecated/) for
reference.
