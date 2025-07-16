// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

contract SilensIdentity is ERC721, Ownable {
    using ECDSA for bytes32;
    using MessageHashUtils for bytes32;

    bytes4 public constant IERC7231_ID = type(IERC7231).interfaceId;

    mapping(uint256 => bytes32) private _identitiesRoots;
    mapping(address => uint256) private _addressToTokenId;
    mapping(uint256 => string) private _tokenURIs;
    mapping(uint256 => mapping(string => bool)) private _verifiedPlatforms;
    uint256 private _tokenIdCounter;

    event SetIdentitiesRoot(uint256 indexed id, bytes32 identitiesRoot);
    event IdentityMinted(address indexed owner, uint256 indexed tokenId, string uri, uint256 timestamp);
    event PlatformVerified(uint256 indexed tokenId, string platform, string username, address indexed owner, uint256 timestamp);

    constructor() ERC721("Silens Identity", "SI") Ownable(msg.sender) {}

    function mintIdentity(string memory _uri) external returns (uint256) {
        require(_addressToTokenId[msg.sender] == 0, "Identity already exists for this address");
        
        _tokenIdCounter++;
        uint256 tokenId = _tokenIdCounter;
        
        _mint(msg.sender, tokenId);
        _tokenURIs[tokenId] = _uri;
        _addressToTokenId[msg.sender] = tokenId;
        
        emit IdentityMinted(msg.sender, tokenId, _uri, block.timestamp);
        return tokenId;
    }

    function setIdentitiesRoot(uint256 id, bytes32 identitiesRoot) external {
        require(ownerOf(id) == msg.sender, "Not token owner");
        
        _identitiesRoots[id] = identitiesRoot;
        emit SetIdentitiesRoot(id, identitiesRoot);
    }

    function getIdentitiesRoot(uint256 id) external view returns (bytes32) {
        require(ownerOf(id) != address(0), "Token does not exist");
        return _identitiesRoots[id];
    }

    function verifyPlatformOwnership(
        uint256 tokenId,
        string memory platform,
        string memory username,
        bytes memory signature
    ) external {
        require(ownerOf(tokenId) == msg.sender, "Not token owner");
        
        bytes32 messageHash = keccak256(abi.encode(
            tokenId,
            platform,
            username,
            "I verify ownership of this platform account for my Silens identity"
        ));
        
        bytes32 ethSignedMessageHash = messageHash.toEthSignedMessageHash();
        address signer = ethSignedMessageHash.recover(signature);
        
        require(signer == msg.sender, "Invalid signature");
        
        _verifiedPlatforms[tokenId][platform] = true;
        
        emit PlatformVerified(tokenId, platform, username, msg.sender, block.timestamp);
    }

    function isPlatformVerified(uint256 tokenId, string memory platform) external view returns (bool) {
        return _verifiedPlatforms[tokenId][platform];
    }

    function getVerifiedPlatformCount(uint256 tokenId) external view returns (uint256) {
        uint256 count = 0;
        string[] memory platforms = new string[](4);
        platforms[0] = "twitter";
        platforms[1] = "github";
        platforms[2] = "linkedin";
        platforms[3] = "discord";
        
        for (uint i = 0; i < platforms.length; i++) {
            if (_verifiedPlatforms[tokenId][platforms[i]]) {
                count++;
            }
        }
        
        return count;
    }

    function verifyIdentitiesBinding(
        uint256 id,
        address nftOwnerAddress,
        string[] memory userIDs,
        bytes32 identitiesRoot,
        bytes calldata signature
    ) external view returns (bool) {
        require(ownerOf(id) == nftOwnerAddress, "Address is not token owner");
        require(_identitiesRoots[id] == identitiesRoot, "Identities root mismatch");

        bytes32 messageHash = keccak256(abi.encode(
            id,
            nftOwnerAddress,
            userIDs,
            identitiesRoot
        ));
        
        bytes32 ethSignedMessageHash = messageHash.toEthSignedMessageHash();
        address signer = ethSignedMessageHash.recover(signature);
        
        return signer == nftOwnerAddress;
    }

    function getTokenIdByAddress(address _address) external view returns (uint256) {
        return _addressToTokenId[_address];
    }

    function hasIdentity(address _address) external view returns (bool) {
        return _addressToTokenId[_address] != 0;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(ownerOf(tokenId) != address(0), "Token does not exist");
        return _tokenURIs[tokenId];
    }

    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        return interfaceId == IERC7231_ID || super.supportsInterface(interfaceId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override {
        require(to == address(0) || from == address(0), "Identity NFTs are non-transferable");
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override {
        require(to == address(0) || from == address(0), "Identity NFTs are non-transferable");
        super.safeTransferFrom(from, to, tokenId, data);
    }
}

/**
 * @title IERC7231
 * @dev ERC-7231 interface for identity-aggregated NFTs
 */
interface IERC7231 {
    /**
     * @notice Emit the user binding information
     * @param id NFT id 
     * @param identitiesRoot New identity root
     */
    event SetIdentitiesRoot(uint256 id, bytes32 identitiesRoot);

    /**
     * @notice Set the user ID binding information of NFT with identitiesRoot
     * @param id NFT id 
     * @param identitiesRoot Multi UserID Root data hash
     */
    function setIdentitiesRoot(uint256 id, bytes32 identitiesRoot) external;

    /**
     * @notice Get the multi-userID root by NFT ID
     * @param id NFT id 
     * @return The bytes32 multiUserIDsRoot
     */
    function getIdentitiesRoot(uint256 id) external view returns (bytes32);

    /**
     * @notice Verify the userIDs binding 
     * @param id NFT id 
     * @param nftOwnerAddress The NFT owner address
     * @param userIDs UserIDs for check
     * @param identitiesRoot Identities root to verify
     * @param signature ECDSA signature 
     * @return True if verification passes, false otherwise
     */
    function verifyIdentitiesBinding(
        uint256 id,
        address nftOwnerAddress,
        string[] memory userIDs,
        bytes32 identitiesRoot,
        bytes calldata signature
    ) external view returns (bool);
} 