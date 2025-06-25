// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {DeployFundMe} from "../../script/DeployFundMe.s.sol"; // Importa lo script di deploy
import {FundFundMe, WithdrawFundMe} from "../../script/Interactions.s.sol"; // Importa gli script di interazione
import {FundMe} from "../../src/FundMe.sol"; // Importa il contratto FundMe
import {Test, console} from "forge-std/Test.sol"; // Importa le utility di test di Forge

contract InteractionsTest is Test {
    FundMe public fundMe; // Istanza del contratto FundMe
    DeployFundMe deployFundMe; // Istanza dello script di deploy

    uint256 public constant SEND_VALUE = 0.1 ether; // Valore da inviare per il finanziamento
    uint256 public constant STARTING_USER_BALANCE = 10 ether; // Saldo iniziale per l'utente Alice

    address alice = makeAddr("alice"); // Crea un indirizzo fittizio per Alice

    // Funzione di setup, eseguita prima di ogni test
    function setUp() external {
        deployFundMe = new DeployFundMe(); // Deploys dello script di deploy
        fundMe = deployFundMe.run(); // Esegue lo script di deploy per ottenere un'istanza del contratto FundMe
        vm.deal(alice, STARTING_USER_BALANCE); // Assegna un saldo iniziale ad Alice

        // *** PUNTO CHIAVE SUL PROPRIETARIO ***
        // Quando deployFundMe.run() viene chiamato, il msg.sender è il contratto di test stesso (InteractionsTest).
        // Il costruttore di FundMe imposta i_owner = msg.sender.
        // Quindi, il contratto InteractionsTest (questo contratto di test) diventa il proprietario di fundMe.
        // console.log("Proprietario di FundMe (i_owner):", fundMe.getOwner());
        // console.log("Indirizzo del contratto di test (msg.sender di setUp):", address(this));
        // Queste due stampe mostrerebbero lo stesso indirizzo.
    }

    // Test di integrazione: l'utente finanzia e il proprietario preleva
    function testUserCanFundAndOwnerWithdraw() public {
        // 1. Arrange (Preparazione)
        uint256 preUserBalance = address(alice).balance; // Saldo di Alice prima del finanziamento
        uint256 preOwnerBalance = address(fundMe.getOwner()).balance; // Saldo del proprietario prima del prelievo

        // 2. Act (Azione) - Finanziamento da parte di Alice
        // Usiamo vm.prank(alice) per simulare che la prossima transazione provenga da Alice.
        // Questo è necessario perché Alice non è il proprietario del contratto.
        vm.prank(alice);
        fundMe.fund{value: SEND_VALUE}(); // Alice finanzia il contratto FundMe

        // 2. Act (Azione) - Prelievo da parte del proprietario (tramite lo script)
        // Creiamo un'istanza dello script WithdrawFundMe.
        WithdrawFundMe withdrawFundMe = new WithdrawFundMe();
        // Chiamiamo la funzione withdrawFundMe dello script, passandogli l'indirizzo del nostro contratto FundMe.
        // *** PUNTO CHIAVE SUL PROPRIETARIO NEL PRELIEVO ***
        // La funzione withdraw() nel contratto FundMe ha il modificatore onlyOwner.
        // Quando withdrawFundMe.withdrawFundMe() viene chiamato da questo contratto di test (InteractionsTest),
        // il msg.sender di quella chiamata sarà l'indirizzo del contratto InteractionsTest stesso.
        // Poiché, come spiegato in setUp(), il contratto InteractionsTest è il proprietario di fundMe,
        // la condizione onlyOwner è soddisfatta automaticamente.
        // Non è necessario un vm.prank(fundMe.getOwner()) qui, perché il chiamante (il test contract)
        // è già l'owner.
        withdrawFundMe.withdrawFundMe(address(fundMe));

        // 3. Assert (Verifica)
        uint256 afterUserBalance = address(alice).balance; // Saldo di Alice dopo il finanziamento
        uint256 afterOwnerBalance = address(fundMe.getOwner()).balance; // Saldo del proprietario dopo il prelievo

        // Asserzioni per verificare il comportamento atteso:
        // Il saldo del contratto FundMe deve essere zero dopo il prelievo.
        assert(address(fundMe).balance == 0);
        // Il saldo finale di Alice più il valore che ha inviato deve essere uguale al suo saldo iniziale (meno il gas).
        assertEq(afterUserBalance + SEND_VALUE, preUserBalance);
        // Il saldo finale del proprietario deve essere uguale al suo saldo iniziale più il valore finanziato (meno il gas).
        assertEq(preOwnerBalance + SEND_VALUE, afterOwnerBalance);
    }
}
