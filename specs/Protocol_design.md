// cycle after cycle

// stake -> delegate -> startEpoch -> claimRewards from validators -> spreadRewardsToDelegators -> compound -> delegate(add the rewards to the user's stake)
// delegation[address] = { total }
// delegation[address] = { total + new rewards }
// contract balance = stake to be delegated + treasury
// treasury => claim via DAO votes || delegate to mint stTARA => providing liquidity
// AMM => pool of TARA <=> stTARA 50%/50% => if unbalanced => arbitrage => rebalance via treasury delegation
// TVL = LARA contract balance + delegated total stake + unclaimed rewards in the DPOS contract
// undelegation = claim rewards until time t + create undelegation request -> claimable in 30 days
// compounding = current epoch ends + claim rewards => instantly push rewards back
// -> undelegate -> claim delegation rewards + undelegate stake
