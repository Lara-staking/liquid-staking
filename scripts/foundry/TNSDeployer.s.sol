// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import {INameWrapper, PublicResolver} from "@ensdomains/ens-contracts/contracts/resolvers/PublicResolver.sol";
import "@ensdomains/ens-contracts/contracts/registry/ENSRegistry.sol";
import "@ensdomains/ens-contracts/contracts/registry/FIFSRegistrar.sol";
import {NameResolver, ReverseRegistrar} from "@ensdomains/ens-contracts/contracts/reverseRegistrar/ReverseRegistrar.sol";

contract TNSDeployer is Script {
    bytes32 public constant TLD_LABEL = keccak256("tara");
    bytes32 public constant RESOLVER_LABEL = keccak256("resolver");
    bytes32 public constant REVERSE_REGISTRAR_LABEL = keccak256("reverse");
    bytes32 public constant ADDR_LABEL = keccak256("addr");
    ENSRegistry ens;
    PublicResolver publicResolver;
    ReverseRegistrar reverseRegistrar;
    FIFSRegistrar fifsRegistrar;

    function namehash(
        bytes32 node,
        bytes32 label
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(node, label));
    }

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_KEY");
        address deployerAddress = vm.envAddress("DEPLOYER_ADDR");
        vm.startBroadcast(deployerPrivateKey);
        ens = new ENSRegistry();
        // Create a FIFS registrar for the TLD
        fifsRegistrar = new FIFSRegistrar(ens, namehash(bytes32(0), TLD_LABEL));

        bytes32 tld_node = ens.setSubnodeOwner(
            bytes32(0),
            TLD_LABEL,
            address(fifsRegistrar)
        );
        if (tld_node != namehash(bytes32(0), TLD_LABEL)) {
            revert("FIFS registrar setup failed");
        }

        // Construct a new reverse registrar and point it at the public resolver
        reverseRegistrar = new ReverseRegistrar(ens);

        // Set up the reverse registrar
        bytes32 reverse_node = ens.setSubnodeOwner(
            bytes32(0),
            REVERSE_REGISTRAR_LABEL,
            deployerAddress
        );
        if (reverse_node != namehash(bytes32(0), REVERSE_REGISTRAR_LABEL)) {
            revert("Reverse registrar setup failed");
        }
        bytes32 reverse_namehash = namehash(
            bytes32(0),
            REVERSE_REGISTRAR_LABEL
        );
        bytes32 addr_subnode = ens.setSubnodeOwner(
            reverse_namehash,
            ADDR_LABEL,
            address(reverseRegistrar)
        );
        if (addr_subnode != namehash(reverse_node, ADDR_LABEL)) {
            revert("Reverse registrar ADDR_LABEL setup failed");
        }

        publicResolver = new PublicResolver(
            ens,
            INameWrapper(address(0)),
            address(0),
            address(reverseRegistrar)
        );

        // Set up the resolver
        bytes32 resolverNode = namehash(bytes32(0), RESOLVER_LABEL);

        bytes32 subnode = ens.setSubnodeOwner(
            bytes32(0),
            RESOLVER_LABEL,
            deployerAddress
        );
        if (subnode != resolverNode) {
            revert("Resolver setup failed");
        }
        ens.setResolver(resolverNode, address(publicResolver));
        publicResolver.setAddr(resolverNode, address(publicResolver));

        // Set default resolver to PublicResolver
        reverseRegistrar.setDefaultResolver(address(publicResolver));

        // Set owner to deployer
        ens.setOwner(bytes32(0), deployerAddress);

        // check if ENS was initialized successfully
        require(
            ens.owner(bytes32(0)) == deployerAddress,
            "ENS was not initialized successfully"
        );

        // checks the reverse registrar was initialized successfully
        require(
            ens.owner(namehash(bytes32(0), keccak256("reverse"))) ==
                deployerAddress,
            "Reverse registrar REVERSE_REGISTRAR_LABEL was not initialized successfully"
        );

        require(
            address(reverseRegistrar) ==
                ens.owner(namehash(reverse_node, ADDR_LABEL)),
            "Reverse registrar ADDR_LABEL was not initialized successfully"
        );

        // register the TNSDeployer.tara node
        bytes32 TNSNodeLabel = namehash(bytes32(0), "TNSDeployer");
        fifsRegistrar.register(TNSNodeLabel, deployerAddress);
        bytes32 subNodelabel = namehash(
            namehash(bytes32(0), TLD_LABEL),
            TNSNodeLabel
        );

        // check if TNSDeployer.eth was registered successfully
        require(
            ens.owner(subNodelabel) == deployerAddress,
            "elod.tara was not registered successfully"
        );
    }
}
