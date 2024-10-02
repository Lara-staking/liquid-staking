// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {
    Initializable, ITokenStake, CurrencyTransferLib
} from "@thirdweb-dev/contracts/prebuilts/staking/TokenStake.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Staking20Base} from "@contracts/Staking20Base.sol";

contract LaraStaking is Initializable, OwnableUpgradeable, UUPSUpgradeable, Staking20Base, ITokenStake {
    struct Claim {
        uint256 amount;
        uint64 blockNumber;
    }

    bytes32 private constant MODULE_TYPE = bytes32("LaraStaking");
    uint256 private constant VERSION = 1;

    /// @dev ERC20 Reward Token address. See {_mintRewards} below.
    address public rewardToken;

    /// @dev Total amount of reward tokens in the contract.
    uint256 private rewardTokenBalance;

    uint256 public MATURITY_BLOCK_COUNT; // (2,629,746 * 6) / 3.6s => 6 months

    uint64 public CURRENT_CLAIM_ID;

    mapping(address => mapping(uint64 => Claim)) public claims;

    /// @dev Gap for future upgrades. In case of new storage variables, they should be added before this gap and the array length should be reduced
    uint256[49] __gap;

    event Redeemed(address indexed user, uint64 indexed claimId, uint256 indexed amount);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }
    /// @dev Initializes the contract, like a constructor.

    function initialize(
        address _rewardToken,
        address _stakingToken,
        uint80 _timeUnit,
        uint256 _rewardRatioNumerator,
        uint256 _rewardRatioDenominator,
        uint256 _newMaturityBlockCount
    ) public initializer {
        require(_rewardToken != _stakingToken, "Reward Token and Staking Token can't be same.");
        rewardToken = _rewardToken;

        uint16 _stakingTokenDecimals = _getTokenDecimals(_stakingToken);
        uint16 _rewardTokenDecimals = _getTokenDecimals(_rewardToken);

        __Ownable_init_unchained(_msgSender());
        __UUPSUpgradeable_init_unchained();
        __Staking20_init(_stakingToken, _stakingTokenDecimals, _rewardTokenDecimals);
        _setStakingCondition(_timeUnit, _rewardRatioNumerator, _rewardRatioDenominator);

        MATURITY_BLOCK_COUNT = _newMaturityBlockCount;
        CURRENT_CLAIM_ID = 1;
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    function _getTokenDecimals(address _token) internal view returns (uint16) {
        return ERC20(_token).decimals();
    }

    /// @dev Returns the module type of the contract.
    function contractType() external pure virtual returns (bytes32) {
        return MODULE_TYPE;
    }

    /// @dev Returns the version of the contract.
    function contractVersion() external pure virtual returns (uint8) {
        return uint8(VERSION);
    }

    /// @dev Lets the contract receive ether to unwrap native tokens.
    receive() external payable {
        require(msg.sender == nativeTokenWrapper, "caller not native token wrapper.");
    }

    /// @dev Fallback function to receive Ether.
    fallback() external payable {}

    function calculateRedeemableAmount(address user, uint64 claimId) public view returns (uint256) {
        Claim memory claim = claims[user][claimId];
        if (claim.amount == 0) {
            return 0;
        }

        // Calculate the percentage of the vesting period that has passed
        uint256 currentBlock = block.number;
        uint256 blocksPassed = currentBlock - claim.blockNumber;
        uint256 vestingPercentage = 0;
        if (blocksPassed > MATURITY_BLOCK_COUNT) {
            vestingPercentage = 1e18;
        } else {
            vestingPercentage = (blocksPassed * 1e18) / MATURITY_BLOCK_COUNT;
        }

        // Calculate the vested amount of the underlying Lara tokens
        uint256 redeemableAmount = (claim.amount * vestingPercentage) / 1e18;
        return redeemableAmount;
    }

    function redeem(uint64 claimId) external {
        Claim memory claim = claims[msg.sender][claimId];
        require(claim.amount > 0, "No rewards to redeem or already redeemed");

        // Transfer the claim's amount of reward tokens to the staking contract
        CurrencyTransferLib.transferCurrency(rewardToken, msg.sender, address(this), claim.amount);

        // Burn the transferred reward tokens
        CurrencyTransferLib.transferCurrency(
            rewardToken, address(this), address(0x000000000000000000000000000000000000dEaD), claim.amount
        );

        // Calculate the percentage of the vesting period that has passed
        uint256 redeemableAmount = calculateRedeemableAmount(msg.sender, claimId);
        require(redeemableAmount > 0, "No rewards to redeem or already redeemed");
        // Update the claim to mark it as redeemed
        claim.amount = 0;
        claims[msg.sender][claimId] = claim;

        // Transfer the vested amount of Lara tokens to the user
        CurrencyTransferLib.transferCurrency(stakingToken, address(this), msg.sender, redeemableAmount);

        emit Redeemed(msg.sender, claimId, redeemableAmount);
    }

    /// @dev Admin deposits reward tokens.
    function depositRewardTokens(uint256 _amount) external payable nonReentrant {
        require(owner() == _msgSender(), "Not authorized");

        address _rewardToken = rewardToken == CurrencyTransferLib.NATIVE_TOKEN ? nativeTokenWrapper : rewardToken;

        uint256 balanceBefore = ERC20(_rewardToken).balanceOf(address(this));
        CurrencyTransferLib.transferCurrencyWithWrapper(
            rewardToken, _msgSender(), address(this), _amount, nativeTokenWrapper
        );
        uint256 actualAmount = ERC20(_rewardToken).balanceOf(address(this)) - balanceBefore;

        rewardTokenBalance += actualAmount;

        emit RewardTokensDepositedByAdmin(actualAmount);
    }

    /// @dev Admin can withdraw excess reward tokens.
    function withdrawRewardTokens(uint256 _amount) external nonReentrant {
        require(owner() == _msgSender(), "Not authorized");

        // to prevent locking of direct-transferred tokens
        rewardTokenBalance = _amount > rewardTokenBalance ? 0 : rewardTokenBalance - _amount;

        CurrencyTransferLib.transferCurrencyWithWrapper(
            rewardToken, address(this), _msgSender(), _amount, nativeTokenWrapper
        );

        // The withdrawal shouldn't reduce staking token balance. `>=` accounts for any accidental transfers.
        address _stakingToken = stakingToken == CurrencyTransferLib.NATIVE_TOKEN ? nativeTokenWrapper : stakingToken;
        require(ERC20(_stakingToken).balanceOf(address(this)) >= stakingTokenBalance, "Staking token balance reduced.");

        emit RewardTokensWithdrawnByAdmin(_amount);
    }

    /// @notice View total rewards available in the staking contract.
    function getRewardTokenBalance() external view override returns (uint256) {
        return rewardTokenBalance;
    }

    /*///////////////////////////////////////////////////////////////
                        Transfer Staking Rewards
    //////////////////////////////////////////////////////////////*/

    /// @dev Mint/Transfer ERC20 rewards to the staker.
    function _mintRewards(address _staker, uint256 _rewards) internal override {
        require(_rewards <= rewardTokenBalance, "Not enough reward tokens");
        rewardTokenBalance -= _rewards;
        CurrencyTransferLib.transferCurrencyWithWrapper(
            rewardToken, address(this), _staker, _rewards, nativeTokenWrapper
        );
    }

    /*///////////////////////////////////////////////////////////////
                        Internal functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Returns whether staking related restrictions can be set in the given execution context.
    function _canSetStakeConditions() internal view override returns (bool) {
        return owner() == _msgSender();
    }

    /*///////////////////////////////////////////////////////////////
                            Miscellaneous
    //////////////////////////////////////////////////////////////*/

    function _stakeMsgSender() internal view virtual override returns (address) {
        return _msgSender();
    }

    function _claimRewards() internal override {
        uint256 rewards = _availableRewards(msg.sender);
        uint64 claimId = CURRENT_CLAIM_ID;
        CURRENT_CLAIM_ID++;
        claims[msg.sender][claimId] = Claim(rewards, uint64(block.number));
        super._claimRewards();
    }
}
