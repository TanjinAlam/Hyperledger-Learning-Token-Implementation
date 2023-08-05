// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
// import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "hardhat/console.sol";

contract asdads is AccessControlEnumerable, ERC1155, Ownable{
    //define all the event here
    event Approval(address indexed owner, address indexed spender,uint256 tokenId,  uint256 value);


    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    using Counters for Counters.Counter;
    Counters.Counter public programTokenId;
    Counters.Counter public instiutionId;
    Counters.Counter public learnerId;
    Counters.Counter public instructorId;
    Counters.Counter public programLearnerId;

    //Institution Struct 
    struct Institutions {
        uint256 _institutionId;
        string institutionName;
        uint256 createdAt;
    }

    //Instructor Struct 
    struct Instructors {
        uint256 _institutionId;
        uint256 _instructorId;
        string instructorName;
        uint256 createdAt;
    }

    //Learner Struct || How to check validity of learner
    struct Learners {
        uint256 _learnerId;
        uint256 _institutionId;
        string learnerName;
        uint256 createdAt;
    }

    struct ProgramLearners {
        uint256 _learnerId;
        uint256 _institutionId;
        string learnerName;
    }

    struct Programs {
        uint256 _instructorId;
        uint256 _institutionId;
        // uint256[] Learners;
        mapping(address => ProgramLearners) programLearners;
        uint256 createdAt;
        string programName;
        uint256 totalSupply;
        uint256 _programTokenId;
        uint256 decimals;
    }

    mapping(uint256 => Programs) public programs;
    mapping(address => Instructors) public instructors;
    mapping(address => Institutions) public institutions; //considering each institution has an single owner entity
    mapping(address => Learners) public learners;

    mapping(uint256=> mapping(address => bool)) public instructorPermission;
    mapping(uint256=> mapping(address => bool)) public institutionPermission;

    // mapping(address => mapping(uint256 => Instructors)) public instructors;
    constructor() ERC1155("") {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(AccessControlEnumerable, ERC1155)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function getInstructorId(address instructorAddress) view internal returns(uint256) {
        return (instructors[instructorAddress]._instructorId);
    }

    function getInstitutionId(address institutionAddress) view internal returns(uint256) {
        return (institutions[institutionAddress]._institutionId);
    }

    function getLearnerId(address learnerAddress) view internal returns(uint256) {
        return (learners[learnerAddress]._learnerId);
    }

    // function getLearnerByAddress(address learnerAddress) view internal return(Learners learners){
    //     return lear
    // }

    //register learner || can be called institute authority only institue autohriy can call this.
    function registerLearner(address _learnerAddress, string memory _learnerName,uint256 createdAt) external onlyInstitution {
        uint256 _institutionId = getInstitutionId(msg.sender);
        learners[_learnerAddress] = Learners(learnerId.current(), _institutionId ,_learnerName, createdAt);
        learnerId.increment();
        //event emit
    }

    //register instructor || can be called by an institutional authority
    function registerInstructor(string memory _instructorName,address instructorAddress, uint256 createdAt) external onlyInstitution {
        uint256 _institutionId = getInstitutionId(msg.sender);
        instructors[instructorAddress] = Instructors(_institutionId, instructorId.current() ,_instructorName, createdAt);
        instructorId.increment();
        //event emit
    }

    //register institution || can be called by onlyowner of contract
    function registerInstitution(string memory _institutionName,address _institutionAddress,uint256 createdAt) external onlyOwner {
        institutions[_institutionAddress] = Institutions(instiutionId.current(), _institutionName, createdAt);
        institutionPermission[instiutionId.current()][_institutionAddress] = true;
        instiutionId.increment();
        //event emit
    }
    
    
    function createProgram(string memory _programName, uint256 _createdAt, uint256 _totalSupply, bytes memory data, address[] memory learnerAddress, uint256[] memory learnerIds) external onlyOwner {
        uint256 _instructorId = getInstructorId(msg.sender);
        Instructors memory _instructor = instructors[msg.sender];
        Programs storage _program = programs[programTokenId.current()];
        for(uint256 i =0; i<learnerAddress.length; i++){
            _program.programLearners[learnerAddress[i]] = ProgramLearners(learnerIds[i],_instructor._institutionId,_programName);
        }
        _program._instructorId = _instructorId;
        _program._institutionId = _instructor._institutionId;
        _program.programName = _programName;
        _program.createdAt = _createdAt;
        _program.totalSupply = _totalSupply;
        _program.decimals = 0;
        // programs[programTokenId.current()] = Programs(_instructorId, _instructor._institutionId,temp, _programName ,_createdAt, _totalSupply, programTokenId.current(), 0);
        _mint(msg.sender, programTokenId.current(), _totalSupply , data);
        // programTokenIds.push(programTokenId.current());
        instructorPermission[programTokenId.current()][msg.sender] = true;
        programTokenId.increment();
    }
        // uint256 _learnerId;
        // uint256 _institutionId;
        // string learnerName;
        // uint256 createdAt;
    function registerForProgram(uint256 _programId) external {
        Programs storage _program = programs[_programId];
        Learners storage _learner = learners[msg.sender];
        //check if the learner is a valid learner or not ??
        _program.programLearners[msg.sender] = ProgramLearners(_learner._learnerId,_learner._institutionId,_learner.learnerName);
        // require(_program.learners[msg.sender]);
        // _program.learners[msg.sender]._learnerId = _learner._learnerId;
        // _program.learners[msg.sender]._institutionId = _learner._institutionId;
        // _program.learners[msg.sender].learnerName = _learner.learnerName;
        // _program.learners[msg.sender].createdAt = _learner.createdAt;
        
        // _learner._learnerId = _learner._learnerId;
        // _learner._institutionId = _learner._institutionId;
        // _learner.learnerName = _learner.learnerName;
        // _learner.createdAt = _learner.createdAt;
    }

    modifier onlyInstitution() {
        uint256 _institutionId = getInstitutionId(msg.sender);
		require(institutionPermission[_institutionId][msg.sender], "Only institution admin has the permission");
		_;
	}
    
	modifier onlyInstructor(uint256 _programId) {
		require(instructorPermission[_programId][msg.sender], "Only program creator has the permission");
		_;
	}

    function checkIsRegisteredForProgram(uint256 _programId) external view returns (ProgramLearners memory){
        Programs storage _program = programs[_programId];
        return _program.programLearners[msg.sender];
    }

    //can be called by the program instructor
    function addLearnerToPorgram(uint256 _programId, address learnerAddress) external onlyInstructor (_programId) {
        Learners storage _learner = learners[learnerAddress];
        Programs storage _program = programs[_programId];
        _program.programLearners[learnerAddress] = ProgramLearners(_learner._learnerId,_learner._institutionId,_program.programName);
    }

    function grantMinterRole(address account) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller is not an admin");
        grantRole(MINTER_ROLE, account);
    }

    function grantBurnerRole(address account) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller is not an admin");
        grantRole(BURNER_ROLE, account);
    }

    function revokeMinterRole(address account) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller is not an admin");
        revokeRole(MINTER_ROLE, account);
    }

    function revokeBurnerRole(address account) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller is not an admin");
        revokeRole(BURNER_ROLE, account);
    }

    function checkIsMinter() public view returns(bool) {
       return hasRole(MINTER_ROLE, msg.sender);
    }

    function checkIsBurner() public view returns(bool) {
       return hasRole(BURNER_ROLE, msg.sender);
    }

    function getMinterMembers() public view returns (string[] memory) {
        uint256 minterRoleCount = getRoleMemberCount(MINTER_ROLE);
        uint256 burnerRoleCount = getRoleMemberCount(BURNER_ROLE);
        uint256 totalMembers = minterRoleCount + burnerRoleCount;

        string[] memory roleInfo = new string[](totalMembers);
        uint256 index = 0;

        for (uint256 i = 0; i < minterRoleCount; i++) {
            address memberMinter = getRoleMember(MINTER_ROLE, i);
            bool isMinter = hasRole(MINTER_ROLE, memberMinter);

            if (memberMinter == msg.sender) {
                if (isMinter) {
                    roleInfo[index] = "Minter";
                    index++;
                }
            }
        }

        for (uint256 i = 0; i < burnerRoleCount; i++) {
            address memberBurner = getRoleMember(BURNER_ROLE, i);
            bool isBurner = hasRole(BURNER_ROLE, memberBurner);

            if (memberBurner == msg.sender) {
                if (isBurner) {
                    roleInfo[index] = "Burner";
                    index++;
                }
            }
        }

        if (index == 0) {
            roleInfo[index] = "Not a Minter or Burner";
        }

        return roleInfo;
    }

    // function mintTo(uint256 _tokenId, address receiverAddress, uint256 amount, bytes memory data) external onlyOwner {
    //     require(bytes(programs[_tokenId].programName).length > 0, "tokenId does not exist");
    //     Programs memory _program = programs[_tokenId];
    //     _mint(receiverAddress, _program._programTokenId, amount, data);
    //     programs[_tokenId].totalSupply += amount;
    // }

    // function getDecimals( uint256 _tokenId ) external view returns( uint256 ) {
    //     Programs memory _program = programs[_tokenId];
	// 	return( _program.decimals );
	// }
}
