// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol"; // Importa il contratto FundMe
import {DeployFundMe} from "../../script/DeployFundMe.s.sol"; /* REFACTORING: importa lo sript di deploy  */

contract FundMeTest is Test {
    FundMe fundMe; // Variabile di stato per l'istanza di FundMe
    DeployFundMe deployFundMe; /* REFACTORING: crea variabile di stato per contenere istanza dello script  */
    address alice = makeAddr("alice");
    uint256 constant SEND_VALUE = 0.1 ether;
    uint256 constant STARTING_BALANCE = 10 ether;
    uint256 constant GAS_PRICE = 1;

    function setUp() external {
        deployFundMe = new DeployFundMe(); /* REFACTORING: deploia istanza del contratto di script  */
        fundMe = deployFundMe.run(); /* REFACTORING: chiama direttamente la funzione run che effettivamente deploia il contratto  */
        vm.deal(alice, STARTING_BALANCE);
    }

    function testMinimumDollarIsFive() public {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testOwnerisMsgSender() public {
        console.log("Proprietario del contratto FundMe: ", fundMe.getOwner());
        console.log("msg.sender di quest ocntratto: ", msg.sender);
        //assertEq(fundMe.i_owner(), msg.sender);
        assertEq(fundMe.getOwner(), msg.sender);
    }

    function testPriceFeedVersionIsAccurate() public {
        uint256 version = fundMe.getVersion();
        assertEq(version, 4);
    }

    function testFundFailsWithoutEnoughETH() public {
        vm.expectRevert();
        fundMe.fund();
    }

    modifier funded() {
        vm.prank(alice);
        fundMe.fund{value: SEND_VALUE}();
        assert(address(fundMe).balance > 0);

        _;
    }

    function testFundUpdatesFundDataStructure() public funded {
        uint256 amountFunded = fundMe.getAddressToAmountFounded(alice);
        assertEq(amountFunded, SEND_VALUE);
    }

    function testAddsFounderToArrayOfFunders() public funded {
        address funder = fundMe.getFunder(0);
        assertEq(funder, alice);
    }

    function testOnlyOwnerCanWithdraw() public funded {
        vm.expectRevert();
        vm.prank(alice);
        fundMe.withdraw();
    }

    function testWithdrawFromASingleFunder() public funded {
        // Arrange
        uint256 startingFundMeBalance = address(fundMe).balance;
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        // Act
        vm.txGasPrice(GAS_PRICE);
        uint256 gasStart = gasleft();
        console.log("Withdraw start: %d gas", gasStart);

        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();
        vm.stopPrank();
        uint256 gasEnd = gasleft();
        uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice;
        console.log("Withdraw consumed: %d gas", gasUsed);
        //Assert
        uint256 endingFundMeBalance = address(fundMe).balance;
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        assertEq(endingFundMeBalance, 0);
        assertEq(startingFundMeBalance + startingOwnerBalance, endingOwnerBalance);
    }

    function testWithdrawFromMultipleFunders() public funded {
        uint160 startingFunderIndex = 1;
        uint160 numberOfFunders = 10;

        for (uint160 i = startingFunderIndex; i < startingFunderIndex + numberOfFunders; i++) {
            hoax(address(i), STARTING_BALANCE);
            fundMe.fund{value: SEND_VALUE}();
        }
        uint256 startingFundMeBalance = address(fundMe).balance;
        uint256 startingOwnerBalance = fundMe.getOwner().balance;

        vm.prank(fundMe.getOwner());
        fundMe.withdraw();

        assertEq(address(fundMe).balance, 0);
        assertEq(startingFundMeBalance + startingOwnerBalance, fundMe.getOwner().balance);
        assertEq((numberOfFunders + 1) * SEND_VALUE, fundMe.getOwner().balance - startingOwnerBalance);
    }

    function testWithdrawFromMultipleFundersCheaper() public funded {
        uint160 startingFunderIndex = 1;
        uint160 numberOfFunders = 10;
        for (uint160 i = startingFunderIndex; i < startingFunderIndex + numberOfFunders; i++) {
            hoax(address(i), STARTING_BALANCE);
            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 startFundMeBalance = address(fundMe).balance;
        uint256 startOwnerbalance = fundMe.getOwner().balance;

        vm.startPrank(fundMe.getOwner());
        fundMe.cheaperWithdraw();
        vm.stopPrank();

        assertEq(address(fundMe).balance, 0);
        assertEq(startFundMeBalance + startOwnerbalance, fundMe.getOwner().balance);
        assertEq((numberOfFunders + 1) * SEND_VALUE, fundMe.getOwner().balance - startOwnerbalance);
    }

    function testPrintStorageData() public {
        for (uint256 i = 0; i < 4; i++) {
            bytes32 value = vm.load(address(fundMe), bytes32(i));
            console.log("Value at location", i, ":");
            console.logBytes32(value);
        }
        console.log("PriceFeed address:", address(fundMe.getPriceFeed()));
        console.log("Owner address:", fundMe.getOwner());
    }

    function testPrintStorageDataWithContribution() public funded {
        for (uint256 i = 0; i < 4; i++) {
            bytes32 value = vm.load(address(fundMe), bytes32(i));
            console.log("Value at location", i, ":");
            console.logBytes32(value);
        }
        console.log("PriceFeed address:", address(fundMe.getPriceFeed()));
        console.log("Owner address:", fundMe.getOwner());
    }
}
