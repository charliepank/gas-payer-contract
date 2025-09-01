// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test} from "forge-std/Test.sol";
import {console2} from "forge-std/console2.sol";
import "../src/GasPayerContract.sol";

contract GasPayerContractTest is Test {
    GasPayerContract public gasPayerContract;
    
    address public feeRecipient = address(0x123);
    uint256 public feePercentage = 100; // 1% in basis points
    uint256 public minFee = 0.001 ether;
    
    address public signer = address(0x456);
    address public caller = address(0x789);
    
    event FundAndRelay(address indexed signerAddress, uint256 gasAmount, uint256 feeAmount);
    event FeeCollected(address indexed feeRecipient, uint256 amount);

    function setUp() public {
        gasPayerContract = new GasPayerContract(feePercentage, minFee, feeRecipient);
        
        // Fund test addresses
        vm.deal(caller, 10 ether);
        vm.deal(signer, 1 ether);
    }

    function test_constructor() public {
        assertEq(gasPayerContract.feePercentage(), feePercentage);
        assertEq(gasPayerContract.minFee(), minFee);
        assertEq(gasPayerContract.feeRecipient(), feeRecipient);
    }
    
    function test_constructor_revertsOnZeroFeeRecipient() public {
        vm.expectRevert("Fee recipient cannot be zero address");
        new GasPayerContract(feePercentage, minFee, address(0));
    }
    
    function test_constructor_revertsOnExcessiveFeePercentage() public {
        vm.expectRevert("Fee percentage cannot exceed 100%");
        new GasPayerContract(10001, minFee, feeRecipient);
    }

    function test_fundAndRelay_success() public {
        uint256 gasAmount = 1 ether;
        uint256 fee = gasPayerContract.calculateFee(gasAmount); // Should be 0.01 ETH (1% of 1 ETH)
        uint256 totalRequired = gasAmount + fee;
        
        uint256 signerBalanceBefore = signer.balance;
        uint256 feeRecipientBalanceBefore = feeRecipient.balance;
        
        vm.expectEmit(true, false, false, true);
        emit FundAndRelay(signer, gasAmount, fee);
        
        vm.expectEmit(true, false, false, true);
        emit FeeCollected(feeRecipient, fee);
        
        vm.prank(caller);
        gasPayerContract.fundAndRelay{value: totalRequired}(signer, gasAmount);
        
        assertEq(signer.balance, signerBalanceBefore + gasAmount);
        assertEq(feeRecipient.balance, feeRecipientBalanceBefore + fee);
    }
    
    function test_fundAndRelay_withExcess() public {
        uint256 gasAmount = 1 ether;
        uint256 fee = gasPayerContract.calculateFee(gasAmount);
        uint256 totalRequired = gasAmount + fee;
        uint256 excess = 0.1 ether;
        uint256 totalSent = totalRequired + excess;
        
        uint256 callerBalanceBefore = caller.balance;
        uint256 signerBalanceBefore = signer.balance;
        uint256 feeRecipientBalanceBefore = feeRecipient.balance;
        
        vm.prank(caller);
        gasPayerContract.fundAndRelay{value: totalSent}(signer, gasAmount);
        
        assertEq(signer.balance, signerBalanceBefore + gasAmount);
        assertEq(feeRecipient.balance, feeRecipientBalanceBefore + fee);
        assertEq(caller.balance, callerBalanceBefore - totalRequired);
    }
    
    function test_fundAndRelay_revertsOnInsufficientPayment() public {
        uint256 gasAmount = 1 ether;
        uint256 fee = gasPayerContract.calculateFee(gasAmount);
        uint256 totalRequired = gasAmount + fee;
        uint256 insufficientAmount = totalRequired - 1 wei;
        
        vm.expectRevert(
            abi.encodeWithSelector(
                GasPayerContract.InsufficientPayment.selector,
                totalRequired,
                insufficientAmount
            )
        );
        
        vm.prank(caller);
        gasPayerContract.fundAndRelay{value: insufficientAmount}(signer, gasAmount);
    }
    
    function test_fundAndRelay_revertsOnSignerTransferFail() public {
        // Create a contract that rejects ETH to test transfer failure
        RejectETH rejectContract = new RejectETH();
        
        uint256 gasAmount = 1 ether;
        uint256 fee = gasPayerContract.calculateFee(gasAmount);
        uint256 totalRequired = gasAmount + fee;
        
        vm.expectRevert(
            abi.encodeWithSelector(
                GasPayerContract.TransferFailed.selector,
                address(rejectContract),
                gasAmount
            )
        );
        
        vm.prank(caller);
        gasPayerContract.fundAndRelay{value: totalRequired}(address(rejectContract), gasAmount);
    }
    
    function test_receiveETH() public {
        uint256 amount = 1 ether;
        
        vm.prank(caller);
        (bool success, ) = address(gasPayerContract).call{value: amount}("");
        
        assertTrue(success);
        assertEq(address(gasPayerContract).balance, amount);
    }
    
    function test_fundAndRelay_zeroGasAmount() public {
        uint256 gasAmount = 0;
        uint256 fee = gasPayerContract.calculateFee(gasAmount); // Should be minFee
        uint256 totalRequired = gasAmount + fee;
        
        uint256 signerBalanceBefore = signer.balance;
        uint256 feeRecipientBalanceBefore = feeRecipient.balance;
        
        vm.prank(caller);
        gasPayerContract.fundAndRelay{value: totalRequired}(signer, gasAmount);
        
        assertEq(signer.balance, signerBalanceBefore);
        assertEq(feeRecipient.balance, feeRecipientBalanceBefore + fee);
    }
    
    function test_calculateFee_usesMinimum() public {
        // Test that small amounts use minimum fee
        uint256 smallAmount = 0.05 ether; // 1% would be 0.0005 ETH, less than min
        uint256 fee = gasPayerContract.calculateFee(smallAmount);
        assertEq(fee, minFee);
    }
    
    function test_calculateFee_usesPercentage() public {
        // Test that large amounts use percentage
        uint256 largeAmount = 1 ether; // 1% would be 0.01 ETH, more than min
        uint256 expectedFee = (largeAmount * feePercentage) / 10000;
        uint256 fee = gasPayerContract.calculateFee(largeAmount);
        assertEq(fee, expectedFee);
    }
    
    function testFuzz_fundAndRelay(uint256 gasAmount, uint256 excess) public {
        vm.assume(gasAmount <= 10 ether);
        vm.assume(excess <= 10 ether);
        
        uint256 fee = gasPayerContract.calculateFee(gasAmount);
        uint256 totalRequired = gasAmount + fee;
        uint256 totalSent = totalRequired + excess;
        
        vm.assume(totalSent <= caller.balance);
        
        uint256 signerBalanceBefore = signer.balance;
        uint256 feeRecipientBalanceBefore = feeRecipient.balance;
        uint256 callerBalanceBefore = caller.balance;
        
        vm.prank(caller);
        gasPayerContract.fundAndRelay{value: totalSent}(signer, gasAmount);
        
        assertEq(signer.balance, signerBalanceBefore + gasAmount);
        assertEq(feeRecipient.balance, feeRecipientBalanceBefore + fee);
        assertEq(caller.balance, callerBalanceBefore - totalRequired);
    }
}

contract RejectETH {
    receive() external payable {
        revert("Rejecting ETH");
    }
}