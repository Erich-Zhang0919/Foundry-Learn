// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;


import { Test, console } from "forge-std/Test.sol";
import { FundMe } from "../src/FundMe.sol";
import { DeployFundMe } from "../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundMe;

    address USER = makeAddr("user");
    uint256 public constant SEND_VALUE = 0.1 ether; // just a value to make sure we are sending enough!
    uint256 public constant STARTING_USER_BALANCE = 10 ether;
    // uint256 public constant SEND_VALUE = 1e18;
    // uint256 public constant SEND_VALUE = 1_000_000_000_000_000_000;
    // uint256 public constant SEND_VALUE = 1000000000000000000;

    function setUp() external {
        // if (!isZkSyncChain()) {
            DeployFundMe deployer = new DeployFundMe();
            // fundMe = deployer.run();
            (fundMe,) = deployer.deployFundMe();
        // } else {
        //     MockV3Aggregator mockPriceFeed = new MockV3Aggregator(DECIMALS, INITIAL_PRICE);
        //     fundMe = new FundMe(address(mockPriceFeed));
        // }
        vm.deal(USER, STARTING_USER_BALANCE);
    }
    
    // function testMinimumDollarIsFive() public {
    //     assertEq(fundMe.MINIMUM_USD, 5e18);
    // }

    // function testOwnerIsMsgSender() public {
    //     assertEq(fundMe.i_owner == msg.sender);
    // }

    // function testPriceFeedSetCorrectly() public {
    //     address retreivedPriceFeed = address(fundMe.getPriceFeed());
    //     // (address expectedPriceFeed) = helperConfig.activeNetworkConfig();
    //     address expectedPriceFeed = helperConfig.getConfigByChainId(block.chainid).priceFeed;
    //     assertEq(retreivedPriceFeed, expectedPriceFeed);
    // }

    function testFundFailsWithoutEnoughETH() public {
        vm.expectRevert();
        // assert(this tx failed)
        fundMe.fund();
    }

    function testFundUpdatesFundedDataStructure() public {
        vm.startPrank(USER);
        fundMe.fund{value: SEND_VALUE}();
        vm.stopPrank();

        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
        assertEq(amountFunded, SEND_VALUE);
    }

    function testAddsFunderToArrayOfFunders() public {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();

        address funder = fundMe.getFunder(0);
        assertEq(funder, USER);
    }

    // 测试仅众筹的人才能进行提现操作

    // 这里的修饰器是为了防止代码冗余
    modifier funded {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        _;
    }

    function testOnlyOwnerCanWithdraw() public funded {
        vm.prank(USER);
        vm.expectRevert();
        fundMe.withdraw();
    }

    function testWithdrawFromASingleFunder() public funded {
        // Arrange
        uint256 startingFundMeBalance = address(fundMe).balance;
        uint256 startingOwnerBalance = fundMe.getOwner().balance;

        // vm.txGasPrice(GAS_PRICE);
        // uint256 gasStart = gasleft();
        // // Act
        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();
        vm.stopPrank();

        // uint256 gasEnd = gasleft();
        // uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice;

        // Assert
        uint256 endingFundMeBalance = address(fundMe).balance;
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        assertEq(endingFundMeBalance, 0);
        assertEq(
            startingFundMeBalance + startingOwnerBalance,
            endingOwnerBalance // + gasUsed
        );
    }

    // Can we do our withdraw function a cheaper way?
    function testWithdrawFromMultipleFunders() public funded {
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 2;
        for (uint160 i = startingFunderIndex; i < numberOfFunders + startingFunderIndex; i++) {
            // we get hoax from stdcheats
            // prank + deal
            hoax(address(i), STARTING_USER_BALANCE);
            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 startingFundMeBalance = address(fundMe).balance;
        uint256 startingOwnerBalance = fundMe.getOwner().balance;

        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();
        vm.stopPrank();

        assert(address(fundMe).balance == 0);
        assert(startingFundMeBalance + startingOwnerBalance == fundMe.getOwner().balance); // 合约初始余额 + 合约持有者余额 
        assert((numberOfFunders + 1) * SEND_VALUE == fundMe.getOwner().balance - startingOwnerBalance);
    }


}