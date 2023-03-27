// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./LandToken.sol";
import "./Voting.sol";

contract Dao is ERC721,Ownable {

    LandToken public tokenLand; // Contrato TokenLand
    Voting public voting; // Contrato Voting
    mapping(address => uint256) public daoBalances; // Almacenamiento de balances de la DAO
    mapping(address => bool) public daoOwners; // Almacenamiento de propietarios de la DAO
    uint256 public totalDaoOwners; // Contador de propietarios de la DAO
    uint256 public daoBankBalance; // Balance de la DAO en ethers
    mapping(address => bool) public landOwners; // Almacenamiento de propietarios de land
    mapping(address => uint256) public landOwnersVotingPower; // Almacenamiento del poder de voto de los propietarios de land
    uint256 public totalLandOwners; // Contador de propietarios de land
    mapping(address => bool) public registeredUsers; // Almacenamiento de usuarios registrados
    mapping(address => uint256) public registeredUsersVotingPower; // Almacenamiento del poder de voto de los usuarios registrados
    uint256 public totalRegisteredUsers; // Contador de usuarios registrados
    uint256 public voteThreshold; // Umbral de votación requerido para aprobar una propuesta
    Proposal[] public proposals; // Lista de propuestas
    mapping(address => bool) public isMember;

   // Evento que se emite cuando se depositan ethers en la DAO
event Deposited(address indexed from, uint256 amount);

// Evento que se emite cuando se retiran ethers de la DAO
event Withdrawn(address indexed to, uint256 amount);

// Evento que se emite cuando se transfieren ethers de la DAO a otra dirección
event Transfered(address indexed to, uint256 amount);

// Evento que se emite cuando se agrega un propietario a la DAO
event DaoOwnerAdded(address indexed owner);

// Evento que se emite cuando se remueve un propietario de la DAO
event DaoOwnerRemoved(address indexed owner);

// Evento que se emite cuando se agrega un propietario de land
event LandOwnerAdded(address indexed owner, uint256 votingPower);

// Evento que se emite cuando se agrega un usuario registrado
event RegisteredUserAdded(address indexed user, uint256 votingPower);

// Evento que se emite cuando se actualiza el poder de voto de un propietario de land
event LandOwnerVotingPowerUpdated(address indexed owner, uint256 votingPower);

// Evento que se emite cuando se crea una propuesta
event ProposalCreated(uint256 proposalId, string description, address indexed creator, uint256 landId);

// Evento que se emite cuando se vota en una propuesta
event Voted(uint256 indexed id, address indexed voter, bool inSupport);

// Evento que se emite cuando se ejecuta una propuesta
event ProposalExecuted(uint256 proposalId, address indexed executor);
event ProposalVoted(uint256 proposalId, address indexed voter, bool inFavor);

// Estructura de una propuesta
struct Proposal {
    string title; // Título de la propuesta
    string description; // Descripción de la propuesta
    address payable recipient; // Dirección que recibirá los fondos en caso de ser aprobada la propuesta
    uint256 amount; // Monto en ethers de la propuesta
    uint256 votesFor; // Votos a favor de la propuesta
    uint256 votesAgainst; // Votos en contra de la propuesta
    bool executed; // Indica si la propuesta ha sido ejecutada
    bool exists; // Indica si la propuesta existe
    mapping(address => bool) voted;
    
}


    // Función para crear una nueva propuesta
function createProposal(string memory _description, address _proposer, uint256 _landId) public onlyMembers {
    require(_landId > 0, "Land ID must be greater than 0");
    proposals.push(Proposal({
        id: proposalCounter,
        description: _description,
        proposer: _proposer,
        landId: _landId,
        voteCount: 0,
        status: ProposalStatus.Pending
    }));

    uint256 proposalId = proposalCounter;
    proposalCounter++;

    emit ProposalCreated(proposalId, _description, _proposer, _landId);
}
    modifier onlyMembers() {
    require(isMember[msg.sender], "Caller is not a member of the DAO");
    _;
}

    
    // Función para calcular el resultado de una propuesta
    function calculateProposalResult(uint256 _proposalId) public {
        require(proposals[_proposalId].exists, "Proposal does not exist"); // Verifica que la propuesta exista
        require(!proposals[_proposalId].executed, "Proposal already executed"); // Verifica que la propuesta no haya sido ejecutada
        if (proposals[_proposalId].totalVotes < voteThreshold) { // Si no se ha alcanzado el umbral de votación
            proposals[_proposalId].result = ProposalResult.Pending; // La propuesta queda pendiente
        } else if (proposals[_proposalId].votesFor > proposals[_proposalId].votesAgainst) { // Si hay más votos a favor que en contra
            proposals[_proposalId].result = ProposalResult.Approved; // La propuesta es aprobada
        } else { // Si hay más votos en contra o la misma cantidad de votos a favor y en contra
            proposals[_proposalId].result = ProposalResult.Rejected; // La propuesta es rechazada
            }
        emit ProposalResultCalculated(_proposalId, proposals[_proposalId].result); // Emite el evento correspondiente
    }
    // Función para obtener el estado actual de una propuesta
    function getProposalState(uint256 _proposalId) public view returns (ProposalState) {
        require(proposals[_proposalId].exists, "Proposal does not exist"); // Verifica que la propuesta exista
        if (proposals[_proposalId].executed) {
            return ProposalState.Executed; // Si la propuesta ha sido ejecutada, devuelve el estado "Ejecutada"
        } else if (isProposalApproved(_proposalId)) {
            return ProposalState.Approved; // Si la propuesta ha sido aprobada, devuelve el estado "Aprobada"
        } else {
            return ProposalState.Pending; // Si la propuesta no ha sido aprobada ni ejecutada, devuelve el estado "Pendiente"
        }
    }

    // Función para ejecutar una propuesta
    function executeProposal(uint256 _proposalId) public onlyOwner {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.status == ProposalStatus.Accepted, "Proposal has not been accepted");

        if (keccak256(abi.encodePacked(proposal.description)) == keccak256(abi.encodePacked("Create new land"))) {
            // Ejecutar acciones para la creación de una nueva tierra
        } else if (keccak256(abi.encodePacked(proposal.description)) == keccak256(abi.encodePacked("Veto land for sale"))) {
            LandToken landTokenContract = LandToken(landToken);
            landTokenContract.vetoLand(proposal.landId);
        } else if (keccak256(abi.encodePacked(proposal.description)) == keccak256(abi.encodePacked("Set land penalty"))) {
            // Ejecutar acciones para establecer una penalización en una tierra
        }

        proposal.status = ProposalStatus.Executed;
        emit ProposalExecuted(_proposalId);
    }
    // Función para ejecutar una propuesta aprobada
    function executeApprovedProposal(uint256 _proposalId) public onlyOwner {
        require(proposals[_proposalId].exists, "Proposal does not exist"); // Verifica que la propuesta exista
        require(!proposals[_proposalId].executed, "Proposal already executed"); // Verifica que la propuesta no haya sido ejecutada
        require(proposals[_proposalId].result == ProposalResult.Approved, "Proposal not approved"); // Verifica que la propuesta haya sido aprobada
    }

    // Función para obtener la información completa de una propuesta
    function getProposal(uint256 _proposalId) public view returns (Proposal memory) {
        require(proposals[_proposalId].exists, "Proposal does not exist"); // Verifica que la propuesta exista
        return proposals[_proposalId];
    }
    // Función para obtener el número total de propuestas creadas
    function getTotalProposals() public view returns (uint256) {
        return proposals.length;
    }
    // Función para actualizar el poder de voto de un usuario registrado
function updateRegisteredUserVotingPower(address _user, uint256 _votingPower) public onlyOwner {
    require(registeredUsers[_user], "Not a registered user"); // Verifica que el usuario sea un usuario registrado
    registeredUsersVotingPower[_user] = _votingPower; // Actualiza el poder de voto del usuario registrado
}

// Función para eliminar un usuario registrado
function removeRegisteredUser(address _user) public onlyOwner {
    require(registeredUsers[_user], "Not a registered user"); // Verifica que el usuario sea un usuario registrado
    registeredUsers[_user] = false; // Elimina el usuario registrado
    totalRegisteredUsers--; // Decrementa el total de usuarios registrados
    registeredUsersVotingPower[_user] = 0; // Establece el poder de voto del usuario registrado en 0
}


// Función para obtener el poder de voto de un usuario registrado
function getRegisteredUserVotingPower(address _user) public view returns (uint256) {
    require(registeredUsers[_user], "User not registered"); // Verifica que el usuario esté registrado
    return registeredUsersVotingPower[_user]; // Devuelve el poder de voto del usuario registrado
}

// Función para obtener el poder de voto de un propietario de land
function getLandOwnerVotingPower(address _landOwner) public view returns (uint256) {
    require(landOwners[_landOwner], "Not a land owner"); // Verifica que el usuario sea propietario de land
    return landOwnersVotingPower[_landOwner]; // Devuelve el poder de voto del propietario de land
}

// Función para obtener el poder de voto de un propietario de la DAO
function getDaoOwnerVotingPower(address _daoOwner) public view returns (uint256) {
    require(daoOwners[_daoOwner], "Not a DAO owner"); // Verifica que el usuario sea propietario de la DAO
    return 1; // Devuelve un poder de voto fijo de 1 para los propietarios de la DAO
}

// Función para obtener el poder de voto de un usuario en una propuesta
function getVotingPowerInProposal(address _user, uint256 _proposalId) public view returns (uint256) {
    uint256 votingPower = 0; // Inicializa el poder de voto en 0
    if (registeredUsers[_user]) { // Si el usuario es un usuario registrado
        votingPower = registeredUsersVotingPower[_user]; // Agrega su poder de voto
    }
    if (landOwners[_user]) { // Si el usuario es propietario de land
        votingPower += landOwnersVotingPower[_user]; // Agrega su poder de voto
    }
    if (daoOwners[_user]) { // Si el usuario es propietario de la DAO
        votingPower += 1; // Agrega un poder de voto fijo de 1
    }
    if (votedForProposal[_user][_proposalId]) { // Si el usuario ha votado a favor de la propuesta
        votingPower -= registeredUsersVotingPower[_user]; // Resta su poder de voto de usuario registrado
        votingPower -= landOwnersVotingPower[_user]; // Resta su poder de voto de propietario de land
        votingPower -= 1; // Resta su poder de voto fijo de propietario de la DAO
    }
    if (votedAgainstProposal[_user][_proposalId]) { // Si el usuario ha votado en contra de la propuesta
        votingPower = 0; // El poder de voto es 0
    }
    return votingPower; // Devuelve el poder de voto del usuario en la propuesta
}


    // Función para votar en una propuesta
function vote(uint256 _proposalId, bool _vote) public onlyMembers {
    Proposal storage proposal = proposals[_proposalId];
    require(proposal.status == ProposalStatus.Pending, "Proposal is not pending");
    require(!hasVoted[msg.sender][_proposalId], "Member has already voted on this proposal");
    
    LandToken landTokenContract = LandToken(landToken);
    require(landTokenContract.ownerOf(proposal.landId) == proposal.proposer, "Proposer is not the owner of the land");
    
    hasVoted[msg.sender][_proposalId] = true;
    proposal.voteCount += (_vote ? 1 : 0);

    if (proposal.voteCount >= quorum) {
        proposal.status = ProposalStatus.Accepted;
        emit ProposalAccepted(_proposalId);
    }
}
    // Función para calcular el poder de voto total de un usuario
    function calculateVotingPower(address _user) public {
    uint256 totalVotingPower = 0;
        if (daoOwners[_user]) { // Si el usuario es propietario de la DAO, su poder de voto es igual a 1
        totalVotingPower = 1;
        }
        if (landOwners[_user]) { // Si el usuario es propietario de land, su poder de voto es igual a la cantidad de land que posee
        totalVotingPower += landOwnersVotingPower[_user];
        }
        if (registeredUsers[_user]) { // Si el usuario es un usuario registrado, su poder de voto es igual a 1
        totalVotingPower += registeredUsersVotingPower[_user];
        }
        votingPower[_user] = totalVotingPower; // Actualiza el poder de voto del usuario
    }

    // Función para eliminar una propuesta
    function deleteProposal(uint256 _proposalId) public onlyOwner {
        require(proposals[_proposalId].exists, "Proposal does not exist"); // Verifica que la propuesta exista
        delete proposals[_proposalId]; // Elimina la propuesta del array de propuestas
        emit ProposalDeleted(_proposalId); // Emite el evento correspondiente
    }

    // Función para obtener el poder de voto total de un usuario
    function getVotingPower(address _user) public view returns (uint256) {
        return votingPower[_user];
    }

    // Función para obtener el número total de usuarios registrados
    function getTotalRegisteredUsers() public view returns (uint256) {
        return totalRegisteredUsers;
    }
    
   
    function canVote(address _user, uint256 _proposalId) public view returns (bool) {
    if (!registeredUsers[_user]) { // Verifica que el usuario esté registrado
        return false;
    }
    if (proposals[_proposalId].exists == false) { // Verifica que la propuesta exista
        return false;
    }
    if (proposals[_proposalId].executed) { // Verifica que la propuesta no haya sido ejecutada
        return false;
    }
    if (votedForProposal[_user][_proposalId] || votedAgainstProposal[_user][_proposalId]) { // Verifica que el usuario no haya votado previamente
        return false;
    }
    if (daoOwners[_user]) { // Si el usuario es propietario de la DAO, puede votar
        return true;
    }
    if (landOwners[_user]) { // Si el usuario es propietario de land, su poder de voto es igual a la cantidad de land que posee
        if (landOwnersVotingPower[_user] > 0) {
            return true;
        }
    }
    if (registeredUsers[_user]) { // Si el usuario es un usuario registrado, su poder de voto es igual a 1
        if (registeredUsersVotingPower[_user] > 0) {
            return true;
        }
    }
    return false; // Si el usuario no cumple ninguna de las condiciones anteriores, no puede votar
}



    // Función para obtener el balance de la DAO en ethers
    function getDaoBankBalance() public view returns (uint256) {
        return daoBankBalance;
    }

    // Función para obtener el balance de un propietario en la DAO
    function getDaoBalance(address _owner) public view returns (uint256) {
        return daoBalances[_owner];
    }

    // Función para obtener la cantidad de propietarios de la DAO
    function getTotalDaoOwners() public view returns (uint256) {
        return totalDaoOwners;
    }

    // Función para obtener la cantidad de propietarios de land
    function getTotalLandOwners() public view returns (uint256) {
        return totalLandOwners;
    }

    // Función para obtener la cantidad de votos a favor de una propuesta
    function getVotesForProposal(uint256 _proposalId) public view returns (uint256) {
        return proposals[_proposalId].votesFor;
    }

    // Función para obtener la cantidad de votos en contra de una propuesta
    function getVotesAgainstProposal(uint256 _proposalId) public view returns (uint256) {
        return proposals[_proposalId].votesAgainst;
    }

    

    // Función para obtener el número total de propuestas creadas
    function getTotalProposals() public view returns (uint256) {
        return proposals.length;
    }
        // Función para verificar si un usuario tiene derecho a votar en una propuesta
   

    // Función para obtener la cantidad total de votos de una propuesta
    function getTotalVotesForProposal(uint256 _proposalId) public view returns (uint256) {
        return proposals[_proposalId].totalVotes;
    }

    // Función para obtener el umbral de votación requerido para aprobar una propuesta
    function getVoteThreshold() public view returns (uint256) {
        return voteThreshold;
    }

    // Función para agregar una nueva propuesta
    function addProposal(string memory _description, address _recipient, uint256 _amount) public returns (uint256) {
        uint256 proposalId = proposals.length; // El ID de la propuesta será el largo del arreglo de propuestas
        proposals.push(Proposal({ // Crea la nueva propuesta
            id: proposalId,
            exists: true,
            description: _description,
            recipient: _recipient,
            amount: _amount,
            votesFor: 0,
            votesAgainst: 0,
            totalVotes: 0,
            executed: false
        }));
        emit ProposalAdded(proposalId, _description); // Emite el evento correspondiente
        return proposalId; // Devuelve el ID de la nueva propuesta
    }
    // Función para votar a favor de una propuesta
    function voteForProposal(uint256 _proposalId) public {
        require(canVote(msg.sender, _proposalId), "Cannot vote");

        votedForProposal[msg.sender][_proposalId] = true; // Marca al usuario como que ha votado a favor de la propuesta
        proposals[_proposalId].votesFor += votingPower[msg.sender]; // Agrega el poder de voto del usuario a los votos a favor de la propuesta
        proposals[_proposalId].totalVotes += votingPower[msg.sender]; // Agrega el poder de voto del usuario al total de votos de la propuesta

        // Verifica si la propuesta ha alcanzado el umbral de votación requerido para aprobarse
        if (proposals[_proposalId].votesFor >= voteThreshold) {
            executeProposal(_proposalId); // Ejecuta la propuesta
        }

        emit VotedForProposal(msg.sender, _proposalId); // Emite el evento correspondiente
    }

    // Función para votar en contra de una propuesta
    function voteAgainstProposal(uint256 _proposalId) public {
        require(votingPower[msg.sender] > 0, "No voting power"); // Verifica que el usuario tenga poder de voto
        require(!proposals[_proposalId].executed, "Proposal already executed"); // Verifica que la propuesta no haya sido ejecutada
        require(!votedForProposal[msg.sender][_proposalId], "Already voted for proposal"); // Verifica que el usuario no haya votado previamente por la propuesta
        require(votedAgainstProposal[msg.sender][_proposalId] == false, "Already voted against proposal"); // Verifica que el usuario no haya votado previamente en contra de la propuesta

        votedAgainstProposal[msg.sender][_proposalId] = true; // Marca al usuario como que ha votado en contra de la propuesta
        proposals[_proposalId].votesAgainst += votingPower[msg.sender]; // Agrega el poder de voto del usuario a los votos en contra de la propuesta
        proposals[_proposalId].totalVotes += votingPower[msg.sender]; // Agrega el poder de voto del usuario al total de votos de la propuesta

        // Verifica si la propuesta ha sido rechazada debido a la cantidad de votos en contra
        if (proposals[_proposalId].votesAgainst >= voteThreshold) {
            proposals[_proposalId].executed = true; // Marca la propuesta como ejecutada
            emit ProposalRejected(_proposalId); // Emite el evento correspondiente
            return;
        }

        emit VotedAgainstProposal(msg.sender, _proposalId); // Emite el evento correspondiente
    }
     // Función para obtener la cantidad total de votos en contra de una propuesta
    function getTotalVotesAgainstProposal(uint256 _proposalId) public view returns (uint256) {
        return proposals[_proposalId].votesAgainst;
    }
}
