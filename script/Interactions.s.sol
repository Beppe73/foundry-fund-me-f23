// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Script, console} from "forge-std/Script.sol";
import {FundMe} from "../src/FundMe.sol";
import {DevOpsTools} from "foundry-devops/src/DevOpsTools.sol"; // Importa la libreria DevOpsTools

// Script per finanziare il contratto FundMe
contract FundFundMe is Script {
    uint256 SEND_VALUE = 0.1 ether; // Valore da inviare (0.1 ETH)

    // Funzione per finanziare il contratto
    function fundFundMe(address mostRecentlyDeployed) public {
        vm.startBroadcast(); // Inizia la "trasmissione" delle transazioni
        // Crea un'istanza del contratto FundMe all'indirizzo specificato e chiama la funzione fund
        FundMe(payable(mostRecentlyDeployed)).fund{value: SEND_VALUE}();
        vm.stopBroadcast(); // Ferma la trasmissione
        console.log("Funded FundMe with %s", SEND_VALUE); // Logga il successo dell'operazione
    }

    // Funzione principale che viene eseguita da forge script
    function run() external {
        // Ottiene l'indirizzo del contratto FundMe deployato più di recente sulla chain corrente
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment("FundMe", block.chainid);
        fundFundMe(mostRecentlyDeployed); // Chiama la funzione per finanziare
    }
}

// Script per prelevare dal contratto FundMe
contract WithdrawFundMe is Script {
    // Funzione per prelevare
    function withdrawFundMe(address mostRecentlyDeployed) public {
        vm.startBroadcast(); // Inizia la trasmissione
        // Crea un'istanza del contratto FundMe e chiama la funzione withdraw
        FundMe(payable(mostRecentlyDeployed)).withdraw();
        vm.stopBroadcast(); // Ferma la trasmissione
        console.log("Withdraw FundMe balance!"); // Logga il successo dell'operazione
    }

    // Funzione principale che viene eseguita da forge script
    function run() external {
        // Ottiene l'indirizzo del contratto FundMe deployato più di recente
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment("FundMe", block.chainid);
        withdrawFundMe(mostRecentlyDeployed); // Chiama la funzione per prelevare
    }
}
