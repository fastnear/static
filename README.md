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
