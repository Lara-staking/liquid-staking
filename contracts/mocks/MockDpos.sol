// (c) 2023-2024, Taraxa, Inc. All rights reserved.
// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./MockIDPOS.sol";

contract MockDpos is MockIDPOS {
    mapping(address => MockIDPOS.ValidatorData) public validators;
    MockIDPOS.ValidatorData[] validatorDatas;

    constructor(address[] memory _internalValidators) payable {
        for (uint256 i = 0; i < _internalValidators.length; ++i) {
            MockIDPOS.ValidatorBasicInfo memory info = MockIDPOS
                .ValidatorBasicInfo(
                    0,
                    0,
                    100,
                    uint64(block.number),
                    msg.sender,
                    "Sample description",
                    "https://endpoint.some"
                );
            MockIDPOS.ValidatorData memory validatorData = MockIDPOS
                .ValidatorData(_internalValidators[i], info);
            validators[_internalValidators[i]] = validatorData;
            validatorDatas.push(validatorData);
        }
        require(
            validators[_internalValidators[_internalValidators.length - 1]]
                .account != address(0),
            "Failed to set own validators"
        );
    }

    function isValidatorRegistered(
        address validator
    ) external view returns (bool) {
        return validators[validator].account != address(0);
    }

    function getValidator(
        address validator
    ) external view returns (MockIDPOS.ValidatorBasicInfo memory) {
        return validators[validator].info;
    }

    function getValidators(
        uint32 batch
    ) external view returns (ValidatorData[] memory validatorsOut, bool end) {
        if (batch == 0) {
            if (validatorDatas.length < 100) {
                batch = uint32(validatorDatas.length);
            } else {
                batch = 100;
            }
        }
        ValidatorData[] memory _validators = new ValidatorData[](batch);
        for (uint8 i = 0; i < batch; ) {
            _validators[i] = ValidatorData(
                validatorDatas[i].account,
                validatorDatas[i].info
            );
            unchecked {
                ++i;
            }
        }
        return (_validators, false);
    }

    function getValidatorsFor(
        address owner,
        uint32 batch
    ) external view returns (ValidatorData[] memory validatorsOut, bool end) {
        if (batch == 0) {
            if (validatorDatas.length < 100) {
                batch = uint32(validatorDatas.length);
            } else {
                batch = 100;
            }
        }
        ValidatorData[] memory _validators = new ValidatorData[](batch);
        for (uint8 i = 0; i < batch; ) {
            if (validatorDatas[i].info.owner == owner) {
                _validators[i] = ValidatorData(
                    validatorDatas[i].account,
                    validatorDatas[i].info
                );
            }
            unchecked {
                ++i;
            }
        }
        return (_validators, false);
    }

    function delegate(address validator) external payable override {
        MockIDPOS.ValidatorData storage validatorData = validators[validator];
        require(validatorData.account != address(0), "Validator doesn't exist");
        require(msg.value > 0, "Delegation value not provided");

        validatorData.info.total_stake += msg.value;
        require(
            validators[validator].info.total_stake >= msg.value,
            "Validator stake not reigstered"
        );
        emit Delegated(msg.sender, validatorData.account, msg.value);
    }

    function registerValidator(
        address validator,
        bytes memory proof,
        bytes memory vrf_key,
        uint16 commission,
        string calldata description,
        string calldata endpoint
    ) external payable override {
        require(proof.length != 0, "Invalid proof");
        require(vrf_key.length != 0, "VRF Public key not porvided");
        require(
            validators[validator].account == address(0),
            "DPOS: Validator already registered"
        );
        require(
            msg.value >= 1000000000000000000000,
            "Base delegation value not provided"
        );

        MockIDPOS.ValidatorBasicInfo memory info = MockIDPOS.ValidatorBasicInfo(
            msg.value,
            0,
            commission,
            uint64(block.number),
            msg.sender,
            description,
            endpoint
        );
        MockIDPOS.ValidatorData memory validatorData = MockIDPOS.ValidatorData(
            validator,
            info
        );
        validators[validator] = validatorData;
        validatorDatas.push(validatorData);

        emit ValidatorRegistered(validator);
    }

    function undelegate(address validator, uint256 amount) external override {
        require(
            validators[validator].account != address(0),
            "Validator doesn't exist"
        );
        delete validators[validator];
        payable(msg.sender).transfer(amount / validatorDatas.length);
        emit Undelegated(msg.sender, validator, amount);
    }

    event DelegationRewards(uint256 totalStakes, uint256 totalRewards);

    function claimAllRewards(uint32 batch) external returns (bool end) {
        uint256 totalStakes = 0;
        for (uint256 i = 0; i < validatorDatas.length; i++) {
            totalStakes += validators[validatorDatas[i].account]
                .info
                .total_stake;
        }
        // give out 1% of the total stakes as rewards + 100 ETH
        uint256 rewards = totalStakes / 100;
        emit DelegationRewards(totalStakes, rewards);
        payable(msg.sender).transfer(100 ether + rewards);
        return true;
    }

    function reDelegate(
        address validator_from,
        address validator_to,
        uint256 amount
    ) external {
        require(
            validators[validator_from].account != address(0),
            "Validator doesn't exist"
        );
        require(
            validators[validator_to].account != address(0),
            "Validator doesn't exist"
        );
        require(
            validators[validator_from].info.total_stake >= amount,
            "Not enough stake"
        );
        validators[validator_from].info.total_stake -= amount;
        validators[validator_to].info.total_stake += amount;
        emit Redelegated(msg.sender, validator_from, validator_to, amount);
    }
}
