// SPDX-License-Identifier: UNLICENSED
// See Story Protocol Alpha Agreement: https://github.com/storyprotocol/protocol-contracts/blob/main/StoryProtocol-AlphaTestingAgreement-17942166.3.pdf
pragma solidity ^0.8.19;

import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { ERC1155Supply } from "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import { ERC1155 } from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import { Base64 } from "@openzeppelin/contracts/utils/Base64.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { ERC20 } from "solmate/src/tokens/ERC20.sol";
import { IIPAccount } from "contracts/interfaces/ip-accounts/IIPAccount.sol";
import { ISplitMain } from "contracts/interfaces/modules/royalties/ISplitMain.sol";
import { Errors } from "contracts/lib/Errors.sol";


contract RoyaltyNFT is ERC1155Supply {
    using SafeERC20 for IERC20;

    // tokenId => owners list
    mapping(uint256 => address[]) private owners;
    // hash(tokenId, owner address) => index
    mapping(bytes32 => uint256) private ownerIndexes;

    uint256 public constant TOTAL_SUPPLY = 1e6;

    ISplitMain public immutable splitMain;

    mapping(uint256 => address) public splits;

    constructor(address splitMain_) ERC1155("") {
        splitMain = ISplitMain(splitMain_);
    }

    function distributeFunds(address sourceAccount_, address token_) external {
        uint256 tokenId = toTokenId(sourceAccount_);
        address[] memory accounts = owners[tokenId];
        sort(accounts);
        uint256 numAccounts = accounts.length;
        uint32[] memory allocations = new uint32[](numAccounts);
        for (uint256 i; i < numAccounts;) {
            allocations[i] = percentage(sourceAccount_, accounts[i]);
            unchecked {
                ++i;
            }
        }
        address split = splits[tokenId];
        IIPAccount(payable(sourceAccount_)).sendRoyaltyForDistribution(split, token_);
        splitMain.updateAndDistributeERC20({
            split: split,
            token: ERC20(token_),
            accounts: accounts,
            percentAllocations: allocations,
            distributorFee: 0,
            distributorAddress: address(0)
        });
    }

    function claim(address account_, address token_) external {
        ERC20[] memory tokens = new ERC20[](1);
        tokens[0] = ERC20(token_);
        splitMain.withdraw(account_, 0, tokens);
    }

    function mint(address sourceAccount_, address[] calldata accounts_, uint32[] calldata initAllocations_) external {
        uint256 tokenId = toTokenId(sourceAccount_);

        uint256 numAccs = accounts_.length;

        if (accounts_.length != initAllocations_.length)
            revert Errors.RoyaltyNFT_AccountsAndAllocationsMismatch(
                accounts_.length,
                initAllocations_.length
            );

        if (_getSum(initAllocations_) != TOTAL_SUPPLY)
            revert Errors.RoyaltyNFT_InvalidAllocationsSum(_getSum(initAllocations_));

        unchecked {
            for (uint256 i; i < numAccs; ++i) {
                _mint(accounts_[i], tokenId, initAllocations_[i], "");
            }
        }

        address[] memory initAccounts = new address[](2);
        initAccounts[0] = address(0);
        initAccounts[1] = address(1);
        uint32[] memory initPercentAllocations = new uint32[](2);
        initPercentAllocations[0] = uint32(500000);
        initPercentAllocations[1] = uint32(500000);

        splits[tokenId] = payable(
            splitMain.createSplit({
                accounts: initAccounts,
                percentAllocations: initPercentAllocations,
                distributorFee: 0,
                controller: address(this)
            })
        );
    }

    function uri(uint256) public view override returns (string memory) {
        return string.concat(
            "data:application/json;base64,",
            Base64.encode(
                bytes(
                    string.concat(
                        '{"name": "Royalty Distribute ',
                        Strings.toHexString(address(this)),
                        '", "description": ',
                        '"Each token represents 0.001% of this Royalty Distribute. ',
                        '"}'
                    )
                )
            )
        );
    }

    function percentage(address sourceAccount_, address account_) public view returns (uint32) {
        unchecked {
            return uint32(balanceOf(account_, toTokenId(sourceAccount_)));
        }
    }

    function toTokenId(address sourceAccount_) public pure returns (uint256 tokenId) {
        tokenId = uint256(uint160(sourceAccount_));
    }

    function _afterTokenTransfer(
        address,
        address from_,
        address to_,
        uint256[] memory ids_,
        uint256[] memory,
        bytes memory
    ) internal virtual override {
        for (uint256 i = 0; i < ids_.length; ++i) {
            bytes32 indexTo = keccak256(abi.encode(ids_[i], to_));
            if (from_ == address(0) || balanceOf(from_, ids_[i]) != 0) {
                ownerIndexes[indexTo] = owners[ids_[i]].length;
                owners[ids_[i]].push(to_);
            } else {
                bytes32 indexFrom = keccak256(abi.encode(ids_[i], from_));
                owners[ids_[i]][ownerIndexes[indexFrom]] = to_;
                ownerIndexes[indexTo] = ownerIndexes[indexFrom];
                delete ownerIndexes[indexFrom];
            }
        }
    }

    function _getSum(uint32[] calldata numbers_) internal pure returns (uint32 sum) {
        uint256 numbersLength = numbers_.length;
        for (uint256 i; i < numbersLength;) {
            sum += numbers_[i];
            unchecked {
                // overflow should be impossible in for-loop index
                ++i;
            }
        }
    }

    function sort(address[] memory data_) internal pure {
        uint length = data_.length;
        for (uint i = 1; i < length; i++) {
            address key = data_[i];
            int j = int(i - 1);
            while ((j >= 0) && (data_[uint(j)] > key)) {
                data_[uint(j) + 1] = data_[uint(j)];
                j--;
            }
            data_[uint(j + 1)] = key;
        }
    }
}
