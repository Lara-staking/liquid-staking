// SPDX-License-Identifier: MIT
// Security contact: elod@apeconsulting.xyz
pragma solidity 0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {ILara} from "./interfaces/ILara.sol";
import {IApyOracle} from "./interfaces/IApyOracle.sol";
import {IstTara} from "./interfaces/IstTara.sol";
import {DposInterface} from "./interfaces/IDPOS.sol";
import {ILaraFactory} from "./interfaces/ILaraFactory.sol";
import "./Lara.sol";

contract LaraFactory is Ownable, ILaraFactory {
    // Duration of an epoch in seconds, initially 1000 blocks
    uint256 public epochDuration = 1000;

    // Maximum staking capacity for a validator
    uint256 public maxValidatorStakeCapacity = 80000000 ether;

    // Minimum amount allowed for staking
    uint256 public minStakeAmount = 1000 ether;

    uint256 public commission;

    uint32 public laraInstanceCount;

    uint32 public activeLaraInstanceCount;

    address public treasuryAddress;

    // StTARA token contract
    IstTara public stTaraToken;

    // DPOS contract
    DposInterface public dposContract;

    // APY oracle contract
    IApyOracle public apyOracle;
    // List of delegators of the protocol
    address[] public delegators;

    address[] public laraAddresses;

    mapping(address => address) public laraInstances;
    mapping(address => bool) public laraActive;

    constructor(
        address _sttaraToken,
        address _dposContract,
        address _apyOracle,
        address _treasuryAddress
    ) Ownable(msg.sender) {
        stTaraToken = IstTara(_sttaraToken);
        dposContract = DposInterface(_dposContract);
        apyOracle = IApyOracle(_apyOracle);
        treasuryAddress = _treasuryAddress;
    }

    /**
     * @notice Setter for epochDuration
     * @param _epochDuration new epoch duration (in seconds)
     */
    function setEpochDuration(uint256 _epochDuration) public onlyOwner {
        epochDuration = _epochDuration;
    }

    /**
     * @notice Setter for commission
     * @param _commission new commission
     */
    function setCommission(uint256 _commission) public onlyOwner {
        commission = _commission;
        emit CommissionChanged(_commission);
    }

    /**
     * @notice Setter for treasuryAddress
     * @param _treasuryAddress new treasuryAddress
     */
    function setTreasuryAddress(address _treasuryAddress) public onlyOwner {
        treasuryAddress = _treasuryAddress;
        emit TreasuryChanged(_treasuryAddress);
    }

    /**
     * @notice onlyOwner Setter for maxValidatorStakeCapacity
     * @param _maxValidatorStakeCapacity new maxValidatorStakeCapacity
     */
    function setMaxValidatorStakeCapacity(
        uint256 _maxValidatorStakeCapacity
    ) external onlyOwner {
        maxValidatorStakeCapacity = _maxValidatorStakeCapacity;
    }

    /**
     * @notice onlyOwner Setter for minStakeAmount
     * @param _minStakeAmount the new minStakeAmount
     */
    function setMinStakeAmount(uint256 _minStakeAmount) external onlyOwner {
        minStakeAmount = _minStakeAmount;
    }

    function createLara() external returns (address payable) {
        require(
            laraInstances[msg.sender] == address(0),
            "LaraFactory: Lara already created"
        );
        Lara lara = new Lara(
            address(stTaraToken),
            address(dposContract),
            address(apyOracle),
            treasuryAddress,
            msg.sender,
            owner(),
            commission
        );
        laraInstances[msg.sender] = address(lara);
        laraAddresses.push(address(lara));
        laraActive[address(lara)] = true;
        laraInstanceCount++;
        activeLaraInstanceCount++;
        emit LaraCreated(address(lara), msg.sender);
        return payable(address(lara));
    }

    function deactivateLara(address delegator) external {
        address laraAddress;
        if (msg.sender != owner()) {
            require(
                laraInstances[msg.sender] != address(0),
                "LaraFactory: Lara not created"
            );
            laraAddress = laraInstances[msg.sender];
        } else {
            require(
                laraInstances[delegator] != address(0),
                "LaraFactory: Lara not created"
            );
            laraAddress = laraInstances[delegator];
        }
        laraActive[laraAddress] = false;
        activeLaraInstanceCount--;
        emit LaraDeactivated(laraAddress, msg.sender);
    }

    function activateLara(address delegator) external {
        address laraAddress;
        if (msg.sender != owner()) {
            require(
                laraInstances[msg.sender] != address(0),
                "LaraFactory: Lara not created"
            );
            laraAddress = laraInstances[msg.sender];
        } else {
            require(
                laraInstances[delegator] != address(0),
                "LaraFactory: Lara not created"
            );
            laraAddress = laraInstances[delegator];
        }
        laraActive[laraAddress] = true;
        activeLaraInstanceCount++;
        emit LaraActivated(laraAddress, msg.sender);
    }
}
