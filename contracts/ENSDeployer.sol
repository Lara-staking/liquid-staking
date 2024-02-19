// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "forge-std/console.sol";

import {INameWrapper, PublicResolver} from "@ensdomains/ens-contracts/contracts/resolvers/PublicResolver.sol";
import "@ensdomains/ens-contracts/contracts/registry/ENSRegistry.sol";
import "@ensdomains/ens-contracts/contracts/registry/FIFSRegistrar.sol";
import {NameResolver, ReverseRegistrar} from "@ensdomains/ens-contracts/contracts/reverseRegistrar/ReverseRegistrar.sol";

/// @dev https://docs.ens.domains/deploying-ens-on-a-private-chain#deploying-ens-in-a-single-transaction
/// @dev Modified to make it compatible with recent updates however not audited
contract ENSDeployer {
    bytes32 public constant TLD_LABEL = keccak256("tara");
    bytes32 public constant RESOLVER_LABEL = keccak256("resolver");
    bytes32 public constant REVERSE_REGISTRAR_LABEL = keccak256("reverse");
    bytes32 public constant ADDR_LABEL = keccak256("addr");

    ENSRegistry public ens;
    FIFSRegistrar public fifsRegistrar;
    ReverseRegistrar public reverseRegistrar;
    PublicResolver public publicResolver;

    function namehash(
        bytes32 node,
        bytes32 label
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(node, label));
    }

    event NameHashSet(
        bytes32 indexed node,
        bytes32 indexed namehash,
        address indexed owner
    );

    constructor() {
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
            address(this)
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
        emit NameHashSet(
            reverse_namehash,
            addr_subnode,
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

        ens.setSubnodeOwner(bytes32(0), RESOLVER_LABEL, address(this));
        ens.setResolver(resolverNode, address(publicResolver));
        publicResolver.setAddr(resolverNode, address(publicResolver));

        // Set default resolver to PublicResolver
        reverseRegistrar.setDefaultResolver(address(publicResolver));

        // Set owner to deployer
        ens.setOwner(bytes32(0), msg.sender);
    }
}
