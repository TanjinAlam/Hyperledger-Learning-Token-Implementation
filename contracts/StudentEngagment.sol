// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
// import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "hardhat/console.sol";

contract StudentAttendancesssss is AccessControlEnumerable, ERC1155, Ownable{
    //define all the event here
    event Approval(address indexed owner, address indexed spender,uint256 tokenId,  uint256 value);


    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    using Counters for Counters.Counter;
    Counters.Counter public tokenId;

    struct SkillDetail {
        uint256 createdAt;
        string skillName;
        uint256 tokenId;
        string description;
    }

    mapping(uint256 => SkillDetail) public skillDetail;

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

    function createClass(uint256 _createdAt, string memory _skillName, string memory _description, bytes memory data) external onlyOwner {
        skillDetail[tokenId.current()] = SkillDetail(_createdAt, _skillName, tokenId.current(), _description);
        _mint(msg.sender, tokenId.current(), 1 , data);
        tokenId.increment();
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

    function mintTo(uint256 _createdAt,string memory _skillName,string memory _description, address receiverAddress, bytes memory data) external onlyOwner {
        skillDetail[tokenId.current()] = SkillDetail(_createdAt, _skillName, tokenId.current(), _description);
        _mint(receiverAddress, tokenId.current(), 1 , data);
        tokenId.increment();
    }

    // function getDecimals( uint256 _tokenId ) external view returns( uint256 ) {
    //     SkillDetail memory _skillDetail = SkillDetail[_tokenId];
	// 	return( _skillDetail.decimals );
	// }
}
