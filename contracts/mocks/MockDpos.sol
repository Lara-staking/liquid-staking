// (c) 2023-2024, Taraxa, Inc. All rights reserved.
// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "./MockIDPOS.sol";

contract MockDpos is MockIDPOS {
    struct Undelegation {
        uint256 id;
        address delegator;
        uint256 amount;
        uint256 blockNumberClaimable;
    }

    uint256 public undelegationId = 1;
    mapping(address => MockIDPOS.ValidatorData) public validators;
    mapping(address => uint256) public totalDelegations;
    MockIDPOS.ValidatorData[] validatorDatas;
    mapping(address => mapping(uint256 => Undelegation)) public undelegations;

    uint256 public constant UNDELEGATION_DELAY_BLOCKS = 5000;

    constructor(address[] memory _internalValidators) payable {
        for (uint256 i = 0; i < _internalValidators.length; ++i) {
            MockIDPOS.ValidatorBasicInfo memory info = MockIDPOS.ValidatorBasicInfo(
                0, 0, 100, uint64(block.number), 0, msg.sender, "Sample description", "https://endpoint.some"
            );
            MockIDPOS.ValidatorData memory validatorData = MockIDPOS.ValidatorData(_internalValidators[i], info);
            validators[_internalValidators[i]] = validatorData;
            validatorDatas.push(validatorData);
        }
        require(
            validators[_internalValidators[_internalValidators.length - 1]].account != address(0),
            "Failed to set own validators"
        );
    }

    function isValidatorRegistered(address validator) external view returns (bool) {
        return validators[validator].account != address(0);
    }

    function getTotalDelegation(address delegator) external view returns (uint256 total_delegation) {
        return totalDelegations[delegator];
    }

    function getValidator(address validator) external view returns (MockIDPOS.ValidatorBasicInfo memory) {
        return validators[validator].info;
    }

    function getValidators(uint32 batch) external view returns (ValidatorData[] memory validatorsOut, bool end) {
        if (batch == 0) {
            if (validatorDatas.length < 100) {
                batch = uint32(validatorDatas.length);
            } else {
                batch = 100;
            }
        }
        ValidatorData[] memory _validators = new ValidatorData[](batch);
        for (uint8 i = 0; i < batch;) {
            _validators[i] = ValidatorData(validatorDatas[i].account, validatorDatas[i].info);
            unchecked {
                ++i;
            }
        }
        return (_validators, false);
    }

    function getValidatorsFor(address owner, uint32 batch)
        external
        view
        returns (ValidatorData[] memory validatorsOut, bool end)
    {
        if (batch == 0) {
            if (validatorDatas.length < 100) {
                batch = uint32(validatorDatas.length);
            } else {
                batch = 100;
            }
        }
        ValidatorData[] memory _validators = new ValidatorData[](batch);
        for (uint8 i = 0; i < batch;) {
            if (validatorDatas[i].info.owner == owner) {
                _validators[i] = ValidatorData(validatorDatas[i].account, validatorDatas[i].info);
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

        totalDelegations[msg.sender] += msg.value;
        validatorData.info.total_stake += msg.value;
        require(validators[validator].info.total_stake >= msg.value, "Validator stake not reigstered");
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
        require(validators[validator].account == address(0), "DPOS: Validator already registered");
        require(msg.value >= 1000000000000000000000, "Base delegation value not provided");

        MockIDPOS.ValidatorBasicInfo memory info = MockIDPOS.ValidatorBasicInfo(
            msg.value, 0, commission, uint64(block.number), 0, msg.sender, description, endpoint
        );
        MockIDPOS.ValidatorData memory validatorData = MockIDPOS.ValidatorData(validator, info);
        validators[validator] = validatorData;
        totalDelegations[msg.sender] += msg.value;
        validatorDatas.push(validatorData);

        emit ValidatorRegistered(validator);
    }

    function undelegate(address validator, uint256 amount) external override returns (uint256 id) {
        require(validators[validator].account != address(0), "Validator doesn't exist");
        uint256 totalStake = validators[validator].info.total_stake;
        if (totalStake < amount) {
            revert("Validator has less stake than requested");
        }
        if (totalStake == amount) {
            validators[validator].info.total_stake = 0;
        } else {
            validators[validator].info.total_stake -= amount;
        }
        undelegations[validator][undelegationId] = Undelegation({
            id: undelegationId,
            delegator: msg.sender,
            amount: amount,
            blockNumberClaimable: block.number + UNDELEGATION_DELAY_BLOCKS
        });
        ++undelegationId;
        totalDelegations[msg.sender] -= amount;
        // simulate rewards
        payable(msg.sender).transfer(333 ether);
        emit Undelegated(undelegationId, msg.sender, validator, amount);
        return undelegationId;
    }

    event DelegationRewards(uint256 totalStakes, uint256 totalRewards);

    function claimAllRewards() external {
        uint256 totalStakes = 0;
        for (uint256 i = 0; i < validatorDatas.length; i++) {
            totalStakes += validators[validatorDatas[i].account].info.total_stake;
        }
        // give out 1% of the total stakes as rewards + 100 ETH
        uint256 rewards = totalStakes / 100;
        emit DelegationRewards(totalStakes, rewards);
        payable(msg.sender).transfer(100 ether + rewards);
    }

    function reDelegate(address validator_from, address validator_to, uint256 amount) external {
        require(validators[validator_from].account != address(0), "Validator doesn't exist");
        require(validators[validator_to].account != address(0), "Validator doesn't exist");
        require(validators[validator_from].info.total_stake >= amount, "Not enough stake");
        validators[validator_from].info.total_stake -= amount;
        validators[validator_to].info.total_stake += amount;
        emit Redelegated(msg.sender, validator_from, validator_to, amount);
    }

    // Confirms undelegate request
    function confirmUndelegateV2(address validator, uint256 id) external override {
        Undelegation memory undelegation = undelegations[validator][id];
        require(undelegation.delegator == msg.sender, "Only delegator can confirm undelegate");
        require(undelegation.blockNumberClaimable <= block.number, "Undelegation not yet claimable");
        delete undelegations[validator][id];
        payable(msg.sender).transfer(undelegation.amount);
        emit UndelegateConfirmed(id, msg.sender, validator, undelegation.amount);
    }

    // Cancel undelegate request
    function cancelUndelegateV2(address validator, uint256 id) external override {
        Undelegation memory undelegation = undelegations[validator][id];
        require(undelegation.delegator == msg.sender, "Only delegator can cancel undelegate");
        delete undelegations[validator][id];
        if (validators[validator].account == address(0)) {
            // we need to readd the validator
            MockIDPOS.ValidatorBasicInfo memory info = MockIDPOS.ValidatorBasicInfo(
                undelegation.amount,
                0,
                100,
                uint64(block.number),
                0,
                msg.sender,
                "Sample description",
                "https://endpoint.some"
            );
            validators[validator] = MockIDPOS.ValidatorData(validator, info);
        } else {
            validators[validator].info.total_stake += undelegation.amount;
        }
        totalDelegations[msg.sender] += undelegation.amount;
        emit UndelegateCanceled(id, msg.sender, validator, undelegation.amount);
    }

    function getUndelegationV2(address delegator, address validator, uint64 undelegation_id)
        external
        view
        returns (MockIDPOS.UndelegationV2Data memory undelegation_v2)
    {
        Undelegation memory und = undelegations[validator][undelegation_id];
        if (und.id == 0) {
            revert("Undelegation not found");
        }

        MockIDPOS.UndelegationData memory undData =
            MockIDPOS.UndelegationData(und.amount, uint64(block.number), validator, true);
        undelegation_v2 = MockIDPOS.UndelegationV2Data(undData, uint64(und.id));
    }
}
