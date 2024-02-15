// SPDX-License-Identifier: MIT
// Security contact: elod@apeconsulting.xyz
pragma solidity 0.8.20;

import {IFactoryGoverned} from "./interfaces/IFactoryGoverned.sol";
import {LaraFactory} from "./LaraFactory.sol";

abstract contract FactoryGoverned is IFactoryGoverned {
    LaraFactory public laraFactory;

    /**
     * @dev Modifier to make a function callable only by active Lara contracts.
     */
    modifier onlyLara() {
        require(
            address(laraFactory) != address(0),
            "Lara factory not initialized. Please call setLaraFactory first."
        );
        bool isActiveLaraContract = laraFactory.laraActive(msg.sender);
        require(
            isActiveLaraContract,
            "Only an active Lara contract instance can call this function"
        );
        _;
    }

    /**
     * @dev Sets the Lara factory contract address.
     * @param _laraFactory The address of the Lara factory contract.
     */
    function setLaraFactory(address _laraFactory) external virtual override {
        laraFactory = LaraFactory(_laraFactory);
    }
}
