// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";
import "../src/GasPayerContract.sol";

contract DeploymentScript is Script {
    function run() external {
        // Load environment variables
        uint256 deployerPrivateKey = vm.envUint("RELAYER_WALLET_PRIVATE_KEY");
        address feeRecipient = vm.envAddress("FEE_RECIPIENT"); // Fee recipient from environment variable
        uint256 feePercentage = vm.envUint("FEE_PERCENTAGE"); // Fee percentage in basis points
        uint256 minFee = vm.envUint("MIN_FEE"); // Minimum fee in wei
        
        console2.log("Deploying with the following parameters:");
        console2.log("Fee Percentage (basis points):", feePercentage);
        console2.log("Minimum Fee (wei):", minFee);
        console2.log("Fee Recipient:", feeRecipient);
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy the GasPayerContract
        GasPayerContract gasPayerContract = new GasPayerContract(feePercentage, minFee, feeRecipient);
        
        console2.log("=================================================");
        console2.log("🚀 DEPLOYMENT COMPLETE");
        console2.log("=================================================");
        console2.log("GasPayerContract deployed at:", address(gasPayerContract));
        console2.log("Fee Percentage:", gasPayerContract.feePercentage(), "basis points");
        console2.log("Minimum Fee:", gasPayerContract.minFee(), "wei");
        console2.log("Fee Recipient:", gasPayerContract.feeRecipient());
        console2.log("=================================================");
        console2.log("CONTRACT ADDRESS FOR UI CONFIG:", address(gasPayerContract));
        console2.log("=================================================");
        
        vm.stopBroadcast();
    }
}