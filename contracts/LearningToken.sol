// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
// import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "hardhat/console.sol";

contract AttentanceToken is  AccessControlEnumerable, ERC1155, Ownable{
    //define all the event here
    event Approval(address indexed owner, address indexed spender,uint256 tokenId,  uint256 value);
    event InstitutionRegistered(uint256 indexed institutionId, string institutionName, uint registeredTime);
    event InstructorRegistered(uint256 indexed instructorId, string instructorName, uint256 registeredTime);
    event InstructorRegisteredUnderInstitution(uint256 indexed instructorId,string instructorName, uint256 indexed institutionId, string institutionName, uint256 registeredTime);
    event LearnerRegistered(uint256 indexed learnerId, string learnerName, uint256 registeredTime);
    event CourseCreated(uint256 indexed courseId, uint256 instructorId, uint256 institutionId, string courseName);
    event LearnerRegisteredForCourse(uint256 indexed courseId, uint256 instructorId, uint256 institutionId, string courseName);
    event AttendanceTokenMinted(address indexed holderAddress,uint256 indexed tokenId ,uint256 indexed courseId, uint256 amount);
    event TokenMetadataCreated(uint256 indexed courseId, uint256 indexed courseTokenId, uint256 institutionId, uint256 instructorId, string skillName, string _fieldOfKnowledge, uint256 registeredTime);
    event HelpingTokenTransfered(address indexed from, address indexed to, uint256 indexed tokenId, uint256 amount, uint256 courseId);
    event SkillTokenMinted(address indexed holderAddress,uint256 indexed tokenId ,uint256 indexed courseId, uint256 amount, string fieldOfKnowledge, string skillName);
    event HelpingTokenMinted(address indexed holderAddress,uint256 indexed tokenId ,uint256 indexed courseId, uint256 amount);
    
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    using Counters for Counters.Counter;
    Counters.Counter public courseId;
    Counters.Counter public instiutionId;
    Counters.Counter public learnerId;
    Counters.Counter public instructorId;
    Counters.Counter public courseTokenCounter;

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

    struct CourseLearners {
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
        mapping(address => CourseLearners) courseLearners;
        mapping(uint256 => address) courseLearnerAddress;
        TokenMetadatas[] tokenMetadataArray;
        uint256 createdAt;
        string courseName;
        uint256 totalSupply;
        uint256 courseHelpingTokneId;
        uint256 courseInstructorScoreTokenId;
        uint256 _courseLearnerCount;
    }

    mapping(uint256 => TokenMetadatas) public tokenMetadatas;
    mapping(uint256 => Courses) public courses;
    mapping(address => Instructors) public instructors;
    mapping(address => Institutions) public institutions; //considering each institution has an single owner entity
    mapping(address => Learners) public learners;

    mapping(uint256=> mapping(address => bool)) public instructorPermission;
    mapping(uint256=> mapping(address => bool)) public institutionPermission;
    mapping(uint256=> mapping(address => bool)) public institutionRolePermission;

    mapping(uint256 => bool) private _isTokenTransferable;

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

    function getCourseLearnerDetails(uint256 _courseId, address _courseLearnersAddress)
        public
        view
        returns (uint256, string memory, bool)
    {
        CourseLearners storage _courseLearner = courses[_courseId].courseLearners[_courseLearnersAddress];
        return (
            _courseLearner._learnerId,
            _courseLearner.learnerName,
            _courseLearner.isActive
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
            _course.courseLearners[learnerAddress[i]] = CourseLearners(_learner._learnerId,_learner.learnerName, true);
            _course.courseLearnerAddress[_course._courseLearnerCount] = learnerAddress[i];
            _course._courseLearnerCount++;
            //event emit for learner registration;
        }
        _course._instructorId = _institution.institutionInstructors[msg.sender]._instructorId;
        _course._institutionId = _institution.institutionInstructors[msg.sender]._institutionId;
        _course._institutionAddress = _institutionAddress;
        _course.courseName = _courseName;
        _course.createdAt = _createdAt;


        _course.courseHelpingTokneId = courseTokenCounter.current();
        courseTokenCounter.increment();
        _course.courseInstructorScoreTokenId = courseTokenCounter.current();
        courseTokenCounter.increment();



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
        _isTokenTransferable[_courseId] = true;
        emit TokenMetadataCreated(_courseId , _courseId, _institutionId, _instructorId, _skillName, _fieldOfKnowledge, createdAt);
    }


        //can be called by the program instructor
    function addLearnerToCourse(uint256 _courseId, address learnerAddress, address _institutionAddress) external onlyInstructor (_courseId) checkInstructorCourseAccess(_institutionAddress){
        Learners storage _learner = learners[learnerAddress];
        Courses storage _course = courses[_courseId];
        require(!_course.courseLearners[learnerAddress].isActive, "learner already in the course");
        require(bytes(_learner.learnerName).length > 0, "learner is not registered");
        _course.courseLearners[learnerAddress] = CourseLearners(_learner._learnerId,_course.courseName, true);
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

    function checkIsRegisteredForCourse(uint256 _programId) external view returns (CourseLearners memory){
        Courses storage _course = courses[_programId];
        return _course.courseLearners[msg.sender];
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

    //check course creator is calling this function or not
    //check token metadata is setted or not
    //check token transfer is alllowed or not
    //checkTokenTransferIsAllowed(id)
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override  {
        revert("safe transfers are disabled in this contract");
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory id,
        uint256[] memory amount,
        bytes memory data
    ) public virtual override  {
        revert("safe transfers are disabled in this contract");
    }


    function getLearnersAddress(uint256[] memory learnersId, uint256 _courseId) internal view returns(address[] memory learnersAddress){
        address[] memory _learnerAddress = new address[](learnersId.length);
        for(uint256 i = 0; i<learnersId.length; i++){
            _learnerAddress[i] = (courses[_courseId].courseLearnerAddress[learnersId[i]]);
        }
        return _learnerAddress;
    }

    // -------------------------- Attendance Token ------------------------------


    //event mint should be more soposticated
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

        require(courses[_courseId].courseLearners[_learnersAddress[0]].isActive, "Learner status is not active");
        _mint(_learnersAddress[0], courseTokenCounter.current(), 1 , "0x");

        // set token metadata notification
        // all validation for all learns are in course or not
        TokenMetadatas memory newTokenMetadata = TokenMetadatas({
            _institutionId: _course._institutionId,
            _instructorId: _course._instructorId,
            createdAt: _createdAt,
            courseId: _courseId,
            fieldOfKnowledge: "",
            skill: ""
        });
        
        _course.tokenMetadataArray.push(newTokenMetadata);
        emit AttendanceTokenMinted(_learnersAddress[0], courseTokenCounter.current(), _courseId, amount);
        courseTokenCounter.increment();
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
            _mint(_learnersAddress[i], courseTokenCounter.current(), 1 , "0x");
                TokenMetadatas memory newTokenMetadata = TokenMetadatas({
                _institutionId: _course._institutionId,
                _instructorId: _course._instructorId,
                createdAt: _createdAt,
                courseId: _courseId,
                fieldOfKnowledge: "",
                skill: ""
            });
            _course.tokenMetadataArray.push(newTokenMetadata);
            emit AttendanceTokenMinted(_learnersAddress[i], courseTokenCounter.current(), _courseId, amount);
            courseTokenCounter.increment();
        }
    }

    // Function to get InstitutionInstructors details for a given institution
    function getInstructorDetails(address institutionAddress, address instructorAddress) public view returns (
        uint256 _institutionId,
        uint256 _instructorId,
        string memory _instructorName,
        bool isActive,
        uint256 createdAt
    ) {
        return (
            institutions[institutionAddress].institutionInstructors[instructorAddress]._institutionId,
            institutions[institutionAddress].institutionInstructors[instructorAddress]._instructorId,
            institutions[institutionAddress].institutionInstructors[instructorAddress]._instructorName,
            institutions[institutionAddress].institutionInstructors[instructorAddress].isActive,
            institutions[institutionAddress].institutionInstructors[instructorAddress].createdAt
        );
    }

    function getCourseDetails (uint256 _courseId) public view returns (uint256 _programLearnerIdCounts) {
        return  courses[_courseId]._courseLearnerCount;
    }

    
    // -------------------------- Skill Token ------------------------------

    //check learners are in the course or not.
    function mintSkillToken(
        uint256 _learnerId,
        uint256 amount,
        uint256 _courseId,
        uint256 _createdAt,
        string memory _fieldOfKnowledge,
        string memory _skillName
    ) public checkTokenTransferIsAllowed(_courseId) {
        Courses storage _course = courses[_courseId];
        uint256[] memory _tempLearnerId = new uint256[](1);
        _tempLearnerId[0] = _learnerId;
        address[] memory _learnersAddress = getLearnersAddress(_tempLearnerId, _courseId);
        _mint(_learnersAddress[0], courseTokenCounter.current(), 1 , "0x");

        TokenMetadatas memory newTokenMetadata = TokenMetadatas({
            _institutionId: _course._institutionId,
            _instructorId: _course._instructorId,
            createdAt: _createdAt,
            courseId: _courseId,
            fieldOfKnowledge: _fieldOfKnowledge,
            skill: _skillName
        });
        
        _course.tokenMetadataArray.push(newTokenMetadata);
        emit SkillTokenMinted(_learnersAddress[0], courseTokenCounter.current(), _courseId, amount, _fieldOfKnowledge, _skillName);
        courseTokenCounter.increment();
    }


    function batchMintSkillToken(
        uint256[] memory _learnerIds,
        uint256 amount,
        uint256 _courseId,
        uint256 _createdAt,
        string memory _fieldOfKnowledge,
        string memory _skillName
    ) public checkTokenTransferIsAllowed(_courseId) {
        address[] memory _learnersAddress = getLearnersAddress(_learnerIds, _courseId);
        Courses storage _course = courses[_courseId];
        for(uint256 i = 0; i< _learnersAddress.length; i++ ){
            _mint(_learnersAddress[i], courseTokenCounter.current(), 1 , "0x");
                TokenMetadatas memory newTokenMetadata = TokenMetadatas({
                _institutionId: _course._institutionId,
                _instructorId: _course._instructorId,
                createdAt: _createdAt,
                courseId: _courseId,
                fieldOfKnowledge: _fieldOfKnowledge,
                skill: _skillName
            });
            _course.tokenMetadataArray.push(newTokenMetadata);
            emit SkillTokenMinted(_learnersAddress[i], courseTokenCounter.current(), _courseId, amount, _fieldOfKnowledge, _skillName);
            courseTokenCounter.increment();
        }
    }


    // ------------------ Helping Token ------------------

    function transferFungableToken(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        uint256 _courseId
    ) external {
        Courses storage _course = courses[_courseId];
        require(_course.courseHelpingTokneId == id, "Only fungale token are allow to transfer");
        super.safeTransferFrom(from, to, id, amount, "0x");
        emit HelpingTokenTransfered(from, to, id, amount, _courseId);
    }


    function mintHelpingToken(
        uint256 _learnerId,
        uint256 amount,
        uint256 _courseId,
        uint256 _createdAt
    ) public checkTokenTransferIsAllowed(_courseId) {
        Courses storage _course = courses[_courseId];
        uint256[] memory _tempLearnerId = new uint256[](1);
        _tempLearnerId[0] = _learnerId;
        address[] memory _learnersAddress = getLearnersAddress(_tempLearnerId, _courseId);
        _mint(_learnersAddress[0], _course.courseHelpingTokneId, amount , "0x");
        TokenMetadatas memory newTokenMetadata = TokenMetadatas({
            _institutionId: _course._institutionId,
            _instructorId: _course._instructorId,
            createdAt: _createdAt,
            courseId: _courseId,
            fieldOfKnowledge: "",
            skill: ""
        });
        
        _course.tokenMetadataArray.push(newTokenMetadata);
        emit HelpingTokenMinted(_learnersAddress[0], _course.courseHelpingTokneId, _courseId, amount);
    }


    function batchMintHelpingToken(
        uint256[] memory _learnerIds,
        uint256 amount,
        uint256 _courseId,
        uint256 _createdAt
    ) public checkTokenTransferIsAllowed(_courseId) {
        address[] memory _learnersAddress = getLearnersAddress(_learnerIds, _courseId);
        Courses storage _course = courses[_courseId];
        for(uint256 i = 0; i< _learnersAddress.length; i++ ){
            _mint(_learnersAddress[i], _course.courseHelpingTokneId, amount , "0x");
                TokenMetadatas memory newTokenMetadata = TokenMetadatas({
                _institutionId: _course._institutionId,
                _instructorId: _course._instructorId,
                createdAt: _createdAt,
                courseId: _courseId,
                fieldOfKnowledge: "",
                skill: ""
            });
            _course.tokenMetadataArray.push(newTokenMetadata);
            emit HelpingTokenMinted(_learnersAddress[i], _course.courseHelpingTokneId, _courseId, amount);
        }
    }


    // ------------------ Instructor Scoring Token ------------------

    function mintInstructorScoreToken(
        uint256 _learnerId,
        uint256 amount,
        uint256 _courseId,
        uint256 _createdAt
    ) public checkTokenTransferIsAllowed(_courseId) {
        Courses storage _course = courses[_courseId];
        uint256[] memory _tempLearnerId = new uint256[](1);
        _tempLearnerId[0] = _learnerId;
        address[] memory _learnersAddress = getLearnersAddress(_tempLearnerId, _courseId);
        _mint(_learnersAddress[0], _course.courseInstructorScoreTokenId, amount , "0x");
        TokenMetadatas memory newTokenMetadata = TokenMetadatas({
            _institutionId: _course._institutionId,
            _instructorId: _course._instructorId,
            createdAt: _createdAt,
            courseId: _courseId,
            fieldOfKnowledge: "",
            skill: ""
        });
        
        _course.tokenMetadataArray.push(newTokenMetadata);
        emit HelpingTokenMinted(_learnersAddress[0], _course.courseInstructorScoreTokenId, _courseId, amount);
    }


    function batchMintInstructorScoreToken(
        uint256[] memory _learnerIds,
        uint256 amount,
        uint256 _courseId,
        uint256 _createdAt
    ) public checkTokenTransferIsAllowed(_courseId) {
        address[] memory _learnersAddress = getLearnersAddress(_learnerIds, _courseId);
        Courses storage _course = courses[_courseId];
        for(uint256 i = 0; i< _learnersAddress.length; i++ ){
            _mint(_learnersAddress[i], _course.courseInstructorScoreTokenId, amount , "0x");
                TokenMetadatas memory newTokenMetadata = TokenMetadatas({
                _institutionId: _course._institutionId,
                _instructorId: _course._instructorId,
                createdAt: _createdAt,
                courseId: _courseId,
                fieldOfKnowledge: "",
                skill: ""
            });
            _course.tokenMetadataArray.push(newTokenMetadata);
            emit HelpingTokenMinted(_learnersAddress[i], _course.courseInstructorScoreTokenId, _courseId, amount);
        }
    }
}
