// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract GasPayerContract {
    uint256 public immutable feePercentage; // In basis points (100 = 1%)
    uint256 public immutable minFee;        // Minimum fee in wei
    address public immutable feeRecipient;
    
    event FundAndRelay(address indexed signerAddress, uint256 gasAmount, uint256 feeAmount);
    event FeeCollected(address indexed feeRecipient, uint256 amount);
    
    error InsufficientPayment(uint256 required, uint256 provided);
    error TransferFailed(address recipient, uint256 amount);
    
    constructor(uint256 _feePercentage, uint256 _minFee, address _feeRecipient) {
        require(_feeRecipient != address(0), "Fee recipient cannot be zero address");
        require(_feePercentage <= 10000, "Fee percentage cannot exceed 100%");
        feePercentage = _feePercentage;
        minFee = _minFee;
        feeRecipient = _feeRecipient;
    }
    
    function calculateFee(uint256 gasAmount) public view returns (uint256) {
        uint256 percentageFee = (gasAmount * feePercentage) / 10000;
        return percentageFee > minFee ? percentageFee : minFee;
    }
    
    function fundAndRelay(address signerAddress, uint256 gasAmount) external payable {
        uint256 fee = calculateFee(gasAmount);
        uint256 totalRequired = gasAmount + fee;
        
        if (msg.value < totalRequired) {
            revert InsufficientPayment(totalRequired, msg.value);
        }
        
        // Transfer gas amount to signer
        (bool success, ) = signerAddress.call{value: gasAmount}("");
        if (!success) {
            revert TransferFailed(signerAddress, gasAmount);
        }
        
        // Transfer fee to fee recipient
        (bool feeSuccess, ) = payable(feeRecipient).call{value: fee}("");
        if (!feeSuccess) {
            revert TransferFailed(feeRecipient, fee);
        }
        
        emit FundAndRelay(signerAddress, gasAmount, fee);
        emit FeeCollected(feeRecipient, fee);
        
        // Return any excess payment
        uint256 excess = msg.value - totalRequired;
        if (excess > 0) {
            (bool refundSuccess, ) = payable(msg.sender).call{value: excess}("");
            if (!refundSuccess) {
                revert TransferFailed(msg.sender, excess);
            }
        }
    }
    
    receive() external payable {
        // Allow contract to receive ETH
    }
}