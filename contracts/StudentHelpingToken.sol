// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
// import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "hardhat/console.sol";

contract StudentHelpingToken is AccessControlEnumerable, ERC1155, Ownable{
    //define all the event here
    event Approval(address indexed owner, address indexed spender,uint256 tokenId,  uint256 value);
    event InstitutionRegistered(uint256 indexed institutionId, string institutionName, uint registeredTime);
    event InstructorRegistered(uint256 indexed instructorId, string instructorName, uint256 registeredTime);
    event InstructorRegisteredUnderInstitution(uint256 indexed instructorId,string instructorName, uint256 indexed institutionId, string institutionName, uint256 registeredTime);
    event LearnerRegistered(uint256 indexed learnerId, string learnerName, uint256 registeredTime);
    event CourseCreated(uint256 indexed courseId, uint256 instructorId, uint256 institutionId, string courseName);
    event LearnerRegisteredForCourse(uint256 indexed courseId, uint256 instructorId, uint256 institutionId, string courseName);
    event HelpingTokenTransfered(address indexed from, address indexed to, uint256 indexed tokenId, uint256 amount, uint256 courseId);
    event TokenMetadataCreated(uint256 indexed courseId, uint256 indexed courseTokenId, uint256 institutionId, uint256 instructorId, string skillName, string _fieldOfKnowledge, uint256 registeredTime);
    event HelpingTokenMinted(address indexed holderAddress,uint256 indexed tokenId ,uint256 indexed courseId, uint256 amount);
    
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    using Counters for Counters.Counter;
    Counters.Counter public courseId;
    Counters.Counter public instiutionId;
    Counters.Counter public learnerId;
    Counters.Counter public instructorId;
    Counters.Counter public programLearnerId;
    Counters.Counter public tokenMetadataId;

    //Institution Struct 
    struct Institutions {
        uint256 _institutionId;
        string institutionName;
        mapping(address => InstitutionInstructors) institutionInstructors;
        uint256 createdAt;
    }

    //Instructor Struct 
    struct InstitutionInstructors {
        uint256 _institutionId;
        uint256 _instructorId;
        string _instructorName;
        bool isActive;
        uint256 createdAt;
    }

    //Instructor Struct 
    struct Instructors {
        uint256 _instructorId;
        string instructorName;
        uint256 createdAt;
    }

    //Learner Struct || How to check validity of learner
    //exclude _institution id from learner -> 
    struct Learners {
        uint256 _learnerId;
        string learnerName;
        uint256 createdAt;
    }

    struct ProgramLearners {
        uint256 _learnerId;
        string learnerName;
        bool isActive;
    }

    struct TokenMetadatas {
        uint256 _institutionId;
        uint256 _instructorId;
        uint256 createdAt;
        uint256 courseId;
        string fieldOfKnowledge;
        string skill;
    }

    struct Courses {
        uint256 _instructorId;
        uint256 _institutionId;
        address _institutionAddress;
        mapping(address => ProgramLearners) programLearners;
        mapping(uint256 => address) programLearnerAddress;
        TokenMetadatas[] tokenMetadataArray;
        uint256 createdAt;
        string courseName;
        uint256 totalSupply;
        uint256 decimals;
        bool isTransferable;
        uint256 _programTokenId;
        uint256 _programLearnerIdCount;
    }

    mapping(uint256 => TokenMetadatas) public tokenMetadatas;
    mapping(uint256 => Courses) public courses;
    mapping(address => Instructors) public instructors;
    mapping(address => Institutions) public institutions; //considering each institution has an single owner entity
    mapping(address => Learners) public learners;

    mapping(uint256=> mapping(address => bool)) public instructorPermission;
    mapping(uint256=> mapping(address => bool)) public institutionPermission;
    mapping(uint256=> mapping(address => bool)) public institutionRolePermission;

    // mapping(address => mapping(uint256 => Instructors)) public instructors;
    //https://yourdomain.hyperledger-learning-token/api/item/{id}.json // or store the ipfs link of the metadata
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

    function getProgramLearnerDetails(uint256 _courseId, address _programLearnersAddress)
        public
        view
        returns (uint256, string memory, bool)
    {
        ProgramLearners storage _programLearner = courses[_courseId].programLearners[_programLearnersAddress];
        return (
            _programLearner._learnerId,
            _programLearner.learnerName,
            _programLearner.isActive
        );
    }

    //register learner || learner can be or cant be part of a close circuit 
    function registerLearner(address _learnerAddress, string memory _learnerName,uint256 createdAt) external {
        learners[_learnerAddress] = Learners(learnerId.current() ,_learnerName, createdAt);

        emit LearnerRegistered(learnerId.current(), _learnerName, createdAt);
        learnerId.increment();
        //event emit
    }

    //register instructor because any single entity can create course
    function registerInstructor(string memory _instructorName,address instructorAddress, uint256 createdAt) external  {
        // uint256 _institutionId = getInstitutionId(msg.sender);
        instructors[instructorAddress] = Instructors(instructorId.current() ,_instructorName, createdAt);

        emit InstructorRegistered(instructorId.current(), _instructorName, createdAt);
        instructorId.increment();

    }

    //register institution || can be called by onlyowner of contract
    function registerInstitution(string memory _institutionName,address _institutionAddress, uint256 createdAt) external onlyOwner {
        institutions[_institutionAddress]._institutionId = instiutionId.current();
        institutions[_institutionAddress].institutionName = _institutionName;
        institutions[_institutionAddress].createdAt = createdAt;

        // Initialize the mapping for institutionInstructors
        institutions[_institutionAddress].institutionInstructors[_institutionAddress]._institutionId = institutions[_institutionAddress]._institutionId;
        institutions[_institutionAddress].institutionInstructors[_institutionAddress]._instructorId = 1; 
        institutions[_institutionAddress].institutionInstructors[_institutionAddress]._instructorName = "Default Instructor"; 
        institutions[_institutionAddress].institutionInstructors[_institutionAddress].isActive = false; 
        institutions[_institutionAddress].institutionInstructors[_institutionAddress].createdAt = createdAt; 


        emit InstitutionRegistered(instiutionId.current(), _institutionName, createdAt);

        institutionPermission[instiutionId.current()][_institutionAddress] = true;
        instiutionId.increment();
    }
    
    //function to add instructor within a institution 
    function addInstructorToInstitution(address _instructorAddress, uint256 createdAt) external onlyInstitution {
        Instructors memory _instructor = instructors[_instructorAddress];
        Institutions storage _institution = institutions[msg.sender];

        // Check if the instructor exists in the institution's mapping
        require(bytes(_instructor.instructorName).length > 0, "Instructor is not registered");

        institutions[msg.sender].institutionInstructors[_instructorAddress]._institutionId = institutions[msg.sender]._institutionId;
        institutions[msg.sender].institutionInstructors[_instructorAddress]._instructorId = _institution.institutionInstructors[_instructorAddress]._instructorId; 
        institutions[msg.sender].institutionInstructors[_instructorAddress]._instructorName = _instructor.instructorName; 
        institutions[msg.sender].institutionInstructors[_instructorAddress].isActive = true; 
        institutions[msg.sender].institutionInstructors[_instructorAddress].createdAt = createdAt; 

        // emit InstructorRegistered()
        emit InstructorRegisteredUnderInstitution(_institution.institutionInstructors[_instructorAddress]._instructorId, _institution.institutionInstructors[_instructorAddress]._instructorName ,institutions[msg.sender]._institutionId, institutions[msg.sender].institutionName, createdAt);
    }



    //create a function that will check either a instructor has the access to create program under the institiuion.
    modifier checkInstructorCourseAccess(address _institutionAddress) {
       Institutions storage _institution = institutions[_institutionAddress];

        // Check if the instructor exists in the institution's mapping
        require(bytes(_institution.institutionInstructors[msg.sender]._instructorName).length > 0, "Instructor not found in the institution");

        // Check if the instructor is active
        require(_institution.institutionInstructors[msg.sender].isActive, "instructor status requires activated");
        _;
    }


    
    //check learnrs are registered or not
    //checking function caller is a institution instructor 
    function createCourse(address _institutionAddress, string memory _courseName, uint256 _createdAt, address[] memory learnerAddress) external checkInstructorCourseAccess(_institutionAddress){
        Institutions storage _institution = institutions[_institutionAddress];

        Courses storage _course = courses[courseId.current()];
        for(uint256 i =0; i<learnerAddress.length; i++){
            Learners memory _learner = learners[learnerAddress[i]];
            _course.programLearners[learnerAddress[i]] = ProgramLearners(_learner._learnerId,_learner.learnerName, true);
            _course.programLearnerAddress[_course._programLearnerIdCount++] = learnerAddress[i];
            //event emit for learner registration;
        }
        _course._instructorId = _institution.institutionInstructors[msg.sender]._instructorId;
        _course._institutionId = _institution.institutionInstructors[msg.sender]._institutionId;
        _course._institutionAddress = _institutionAddress;
        _course.courseName = _courseName;
        _course.createdAt = _createdAt;
        // _course._tokenMetadataId = courseId.current();
        _course.decimals = 0;
        _course.isTransferable = true;
        // programs[courseId.current()] = Programs(_instructorId, _instructor._institutionId,temp, _programName ,_createdAt, _totalSupply, courseId.current(), 0);
        // _mint(msg.sender, courseId.current(), _totalSupply , data);
        // courseIds.push(courseId.current());
        instructorPermission[courseId.current()][msg.sender] = true;
        emit CourseCreated(courseId.current(), _institution.institutionInstructors[msg.sender]._instructorId,  _institution.institutionInstructors[msg.sender]._institutionId, _courseName);
        courseId.increment();
    }

    function setTokenMetadata(uint256 _courseId, uint256 _institutionId, uint256 _instructorId, 
    string memory _fieldOfKnowledge, string memory _skillName, address _institutionAddress,uint256 createdAt) external onlyInstructor (_courseId) checkInstructorCourseAccess(_institutionAddress) {
        TokenMetadatas storage _tokenMetadata = tokenMetadatas[_courseId];
        _tokenMetadata._institutionId = _institutionId;
        _tokenMetadata._instructorId = _instructorId;
        _tokenMetadata.createdAt = createdAt;
        _tokenMetadata.courseId = _courseId;
        _tokenMetadata.fieldOfKnowledge = _fieldOfKnowledge;
        _tokenMetadata.skill = _skillName;
        emit TokenMetadataCreated(_courseId , _courseId, _institutionId, _instructorId, _skillName, _fieldOfKnowledge, createdAt);
    }

    //can be called by the program instructor
    function addLearnerToCourse(uint256 _courseId, address learnerAddress, address _institutionAddress) external onlyInstructor (_courseId) checkInstructorCourseAccess(_institutionAddress){
        Learners storage _learner = learners[learnerAddress];
        Courses storage _course = courses[_courseId];
        require(!_course.programLearners[learnerAddress].isActive, "learner already in the course");
        require(bytes(_learner.learnerName).length > 0, "learner is not registered");
        _course.programLearners[learnerAddress] = ProgramLearners(_learner._learnerId,_course.courseName, true);
        emit LearnerRegisteredForCourse(_courseId, _course._instructorId, _course._institutionId, _course.courseName);
    }

    modifier onlyInstitution() {
        uint256 _institutionId = getInstitutionId(msg.sender);
		require(institutionPermission[_institutionId][msg.sender], "Only institution admin has the permission");
		_;
	}
    
	modifier onlyInstructor(uint256 _programId) {
		require(instructorPermission[_programId][msg.sender], "Only course creator has the permission");
		_;
	}

    function checkIsRegisteredForProgram(uint256 _programId) external view returns (ProgramLearners memory){
        Courses storage _course = courses[_programId];
        return _course.programLearners[msg.sender];
    }

    function grantMinterBurnerRole(address institutionsAddress, uint256 _institutionId) internal {
        //grant both role for institution 
        grantRole(MINTER_ROLE, institutionsAddress);
        grantRole(BURNER_ROLE, institutionsAddress);
        //update the role-base-access-permission
        institutionRolePermission[_institutionId][msg.sender] = true;
    }

    // can be called by an institution only 
    function grantMinterRole(address _instructorAddress, uint256 _institutionId) external {
        // require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller is not an admin");
        require(institutionRolePermission[_institutionId][msg.sender], "Institution does not have permission");
        grantRole(MINTER_ROLE, _instructorAddress);
    }

    function grantBurnerRole(address _instructorAddress, uint256 _institutionId) external {
        // require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller is not an admin");
        require(institutionRolePermission[_institutionId][msg.sender], "Institution does not have permission");
        grantRole(BURNER_ROLE, _instructorAddress);
    }

    function revokeMinterRole(address _instructorAddress, uint256 _institutionId) external {
        // require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller is not an admin");
        require(institutionRolePermission[_institutionId][msg.sender], "Institution does not have permission");
        revokeRole(MINTER_ROLE, _instructorAddress);
    }

    function revokeBurnerRole(address _instructorAddress, uint256 _institutionId) external {
        // require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller is not an admin");
        require(institutionRolePermission[_institutionId][msg.sender], "Institution does not have permission");
        revokeRole(BURNER_ROLE, _instructorAddress);
    }

    function checkIsMinter() external view returns(bool) {
       return hasRole(MINTER_ROLE, msg.sender);
    }

    function checkIsBurner() external view returns(bool) {
       return hasRole(BURNER_ROLE, msg.sender);
    }

    function getMinterMembers() external view returns (string[] memory) {
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



    modifier checkTokenTransferIsAllowed(uint256 _courseId) {
        Courses storage _course = courses[_courseId];
        Institutions storage _institution = institutions[_course._institutionAddress];
         // Check if the instructor exists in the institution's mapping
        require(bytes(_institution.institutionInstructors[msg.sender]._instructorName).length > 0, "Instructor not found in the institution");
        
        // Check if the instructor is active
        require(_institution.institutionInstructors[msg.sender].isActive, "instructor status requires activated");

        //check course creator is calling this function or not
        require(instructorPermission[_courseId][msg.sender], "Only course creator has the permission");
        _;
    }

    
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override  {
        uint256 _courseId = abi.decode(data, (uint256));
        super.safeTransferFrom(from, to, id, amount, data);
        emit HelpingTokenTransfered(from, to, id, amount, _courseId);
    }


    function getLearnersAddress(uint256[] memory learnersId, uint256 _courseId) internal view returns(address[] memory learnersAddress){
        address[] memory _learnerAddress = new address[](learnersId.length);
        for(uint256 i = 0; i<learnersId.length; i++){
            _learnerAddress[i] = (courses[_courseId].programLearnerAddress[learnersId[i]]);
        }
        return _learnerAddress;
    }

    function mintAttendanceToken(
        uint256 _learnerId,
        uint256 amount,
        uint256 _courseId,
        uint256 _createdAt
    ) public checkTokenTransferIsAllowed(_courseId) {
        Courses storage _course = courses[_courseId];
        uint256[] memory _tempLearnerId = new uint256[](1);
        _tempLearnerId[0] = _learnerId;
        address[] memory _learnersAddress = getLearnersAddress(_tempLearnerId, _courseId);
        _mint(_learnersAddress[0], _course._programTokenId, 1 , "0x");
        TokenMetadatas memory newTokenMetadata = TokenMetadatas({
            _institutionId: _course._institutionId,
            _instructorId: _course._instructorId,
            createdAt: _createdAt,
            courseId: _courseId,
            fieldOfKnowledge: "",
            skill: ""
        });
        
        _course.tokenMetadataArray.push(newTokenMetadata);
        emit HelpingTokenMinted(_learnersAddress[0], _course._programTokenId, _courseId, amount);
    }


    function batchMintAttendanceToken(
        uint256[] memory _learnerIds,
        uint256 amount,
        uint256 _courseId,
        uint256 _createdAt
    ) public checkTokenTransferIsAllowed(_courseId) {
        address[] memory _learnersAddress = getLearnersAddress(_learnerIds, _courseId);
        Courses storage _course = courses[_courseId];
        for(uint256 i = 0; i< _learnersAddress.length; i++ ){
            _mint(_learnersAddress[i], _course._programTokenId, 1 , "0x");
                TokenMetadatas memory newTokenMetadata = TokenMetadatas({
                _institutionId: _course._institutionId,
                _instructorId: _course._instructorId,
                createdAt: _createdAt,
                courseId: _courseId,
                fieldOfKnowledge: "",
                skill: ""
            });
            _course.tokenMetadataArray.push(newTokenMetadata);
            emit HelpingTokenMinted(_learnersAddress[i], _course._programTokenId, _courseId, amount);
        }
    }



    // //check instructor is allowed to transfer or not
    // //check receptant is active 
    // function batchTransfer(address[] calldata recipients, uint256 tokenId, uint256 amount, uint256 _courseId) external checkTokenTransferIsAllowed(tokenId) {
    //     address sender = msg.sender;
    //     for (uint256 i = 0; i < recipients.length; i++) {
    //         address recipient = recipients[i];
    //         uint256[] memory tokenIds = new uint256[](1);
    //         uint256[] memory amounts = new uint256[](1);
            
    //         tokenIds[0] = tokenId;
    //         amounts[0] = amount;
    //         if(courses[_courseId].programLearners[recipient].isActive){
    //             super.safeBatchTransferFrom(sender, recipient, tokenIds, amounts, "0x");
    //             emit HelpingTokenTransfered(sender, recipient, tokenId, amount, _courseId);
    //         }
            
    //     }
    // }
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        revert("Batch transfers are disabled in this contract");
    }
}
