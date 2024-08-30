# Compiler versions

The development solidity version is `0.8.20`.

The development evm version is `berlin`.

**Note**: The compiler version must be explicitly set in the `foundry.toml` file for effective management. Please check the [foundry.toml](foundry.toml) file for the exact version as well as for more details.

## Upgradable contracts

We need additional metadata for usage of upgradable contracts and their management with the `openzeppelin-foundry-upgrades` package.

We need to define the `build_info`, `extra_output` and add the `node_modules` under the `libs` key.

```toml
[profile.default]
build_info = true
extra_output = ["storageLayout"]
solc =  "0.8.20"
evm_version = 'berlin'
src = 'contracts'
out = 'out'
libs = ['node_modules', 'lib']
test = 'test'
script = 'scripts/foundry'
cache_path  = 'cache_forge'
fs_permissions = [{ access = "read", path = "./"}]
```
