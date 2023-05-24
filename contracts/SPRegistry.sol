// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import { IStoryBlockAware } from "./IStoryBlockAware.sol";
import { SPFranchiseNFTFactory } from "./franchises/SPFranchiseNFTFactory.sol";
import { AccessControlled } from "./access-control/AccessControlled.sol";
import { UPGRADER_ROLE } from "./access-control/ProtocolRoles.sol";
import { ZeroAddress } from "./errors/General.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { ERC721Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";

contract SPRegistry is UUPSUpgradeable, AccessControlled, ERC721Upgradeable, IStoryBlockAware {

    event FranchiseRegistered(address indexed to, uint256 indexed franchiseId, address indexed nftAddress);

    error AlreadyRegistered();

    uint256 _franchiseIds;
    // Franchise id => Collection address
    mapping(uint256 => address) public _franchises;

    SPFranchiseNFTFactory public immutable FACTORY;
    uint256 public constant PROTOCOL_ROOT_ID = 0;
    address public constant PROTOCOL_ROOT_ADDRESS = address(0);

    constructor(address _factory) {
        _disableInitializers();
        if (_factory == address(0)) revert ZeroAddress("factory");
        FACTORY = SPFranchiseNFTFactory(_factory);
    }

    function initialize(address accessControl) public initializer {
        __UUPSUpgradeable_init();
        __AccessControlled_init(accessControl);
        __ERC721_init("Story Protocol", "SP");
    }

    function registerFranchise(address to, string calldata name, string calldata symbol, string calldata description) external returns(address) {
        address franchise = FACTORY.createFranchise(name, symbol, description);
        _franchises[++_franchiseIds] = franchise;
        _safeMint(to, _franchiseIds);
        emit FranchiseRegistered(to, _franchiseIds, franchise);
        return franchise;
    }

    function franchiseContract(uint256 franchiseId) public view returns(address) {
        return _franchises[franchiseId];
    }

    function _authorizeUpgrade(address newImplementation) internal virtual override onlyRole(UPGRADER_ROLE) {
    }

}