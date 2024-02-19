// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../interfaces/IApyOracle.sol";
import "../ENSDeployer.sol";
import "../ApyOracle.sol";
import "../mocks/MockDpos.sol";
import "../stTara.sol";
import {INameWrapper, PublicResolver} from "@ensdomains/ens-contracts/contracts/resolvers/PublicResolver.sol";
import "@ensdomains/ens-contracts/contracts/registry/ENSRegistry.sol";
import "@ensdomains/ens-contracts/contracts/registry/FIFSRegistrar.sol";
import {NameResolver, ReverseRegistrar} from "@ensdomains/ens-contracts/contracts/reverseRegistrar/ReverseRegistrar.sol";

contract ENSSetupTest is Test {
    bytes32 public constant TLD_LABEL = keccak256("tara");
    bytes32 public constant RESOLVER_LABEL = keccak256("resolver");
    bytes32 public constant REVERSE_REGISTRAR_LABEL = keccak256("reverse");
    bytes32 public constant ADDR_LABEL = keccak256("addr");
    ENSDeployer ensDeployer;
    ENSRegistry ens;
    PublicResolver publicResolver;
    ReverseRegistrar reverseRegistrar;
    FIFSRegistrar fifsRegistrar;

    function setUp() public {
        setUpEns();
    }

    function namehash(
        bytes32 node,
        bytes32 label
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(node, label));
    }

    function setUpEns() public {
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
            address(this)
        );
        if (subnode != resolverNode) {
            revert("Resolver setup failed");
        }
        ens.setResolver(resolverNode, address(publicResolver));
        publicResolver.setAddr(resolverNode, address(publicResolver));

        // Set default resolver to PublicResolver
        reverseRegistrar.setDefaultResolver(address(publicResolver));

        // Set owner to deployer
        ens.setOwner(bytes32(0), address(this));

        // check if ENS was initialized successfully
        assertEq(
            ens.owner(bytes32(0)),
            address(this),
            "ENS was not initialized successfully"
        );

        // checks the reverse registrar was initialized successfully
        assertEq(
            ens.owner(namehash(bytes32(0), keccak256("reverse"))),
            address(this),
            "Reverse registrar REVERSE_REGISTRAR_LABEL was not initialized successfully"
        );

        assertEq(
            address(reverseRegistrar),
            ens.owner(namehash(reverse_node, ADDR_LABEL)),
            "Reverse registrar ADDR_LABEL was not initialized successfully"
        );

        // register the elod.tara node
        bytes32 elodNodeLabel = namehash(bytes32(0), "elod");
        fifsRegistrar.register(elodNodeLabel, address(this));
        bytes32 subNodelabel = namehash(
            namehash(bytes32(0), TLD_LABEL),
            elodNodeLabel
        );

        // check if elod.eth was registered successfully
        assertEq(
            ens.owner(subNodelabel),
            address(this),
            "elod.eth was not registered successfully"
        );
    }

    function testFuzz_EnsDeployment(address sampleAddress) public {
        //get the first 4 charaters of the address as string
        bytes4 addressString = bytes4(abi.encodePacked(sampleAddress));
        // cobvert the 4 bytes to string
        // register the elod.tara node
        bytes32 newNodeLabel = namehash(bytes32(0), addressString);
        fifsRegistrar.register(newNodeLabel, sampleAddress);
        bytes32 subNodelabel = namehash(
            namehash(bytes32(0), TLD_LABEL),
            newNodeLabel
        );

        // check if elod.eth was registered successfully
        assertEq(
            ens.owner(subNodelabel),
            sampleAddress,
            "FUZZ: sample address was not registered successfully"
        );
    }
}
