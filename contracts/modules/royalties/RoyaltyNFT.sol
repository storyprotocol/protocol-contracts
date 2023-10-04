// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import { ERC1155Supply } from "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import { ERC1155 } from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import { Base64 } from "@openzeppelin/contracts/utils/Base64.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { ERC20 } from "solmate/src/tokens/ERC20.sol";
import { IIPAccount } from "contracts/interfaces/ip-accounts/IIPAccount.sol";
import { ISplitMain } from "contracts/interfaces/modules/royalties/ISplitMain.sol";

error AccountsAndAllocationsMismatch(
    uint256 accountsLength,
    uint256 allocationsLength
);

error InvalidAllocationsSum(uint32 allocationsSum);

contract RoyaltyNFT is ERC1155Supply {
    using SafeERC20 for IERC20;

    // tokenId => owners list
    mapping(uint256 => address[]) private owners;
    // hash(tokenId, owner address) => index
    mapping(bytes32 => uint256) private ownerIndexes;

    uint256 public constant TOTAL_SUPPLY = 1e6;

    ISplitMain public immutable splitMain;

    mapping(uint256 => address) public splits;

    constructor(address _splitMain) ERC1155("") {
        splitMain = ISplitMain(_splitMain);
    }

    function distributeFunds(address sourceAccount, address token) external {
        uint256 tokenId = toTokenId(sourceAccount);
        address[] memory accounts = owners[tokenId];
        sort(accounts);
        uint256 numAccounts = accounts.length;
        uint32[] memory allocations = new uint32[](numAccounts);
        for (uint256 i; i < numAccounts;) {
            allocations[i] = percentage(sourceAccount, accounts[i]);
            unchecked {
                ++i;
            }
        }
        address split = splits[tokenId];
        IIPAccount(payable(sourceAccount)).sendRoyaltyForDistribution(split, token);
        splitMain.updateAndDistributeERC20({
            split: split,
            token: ERC20(token),
            accounts: accounts,
            percentAllocations: allocations,
            distributorFee: 0,
            distributorAddress: address(0)
        });
    }

    function claim(address account, address token) external {
        ERC20[] memory tokens = new ERC20[](1);
        tokens[0] = ERC20(token);
        splitMain.withdraw(account, 0, tokens);
    }

    function mint(address sourceAccount, address[] calldata accounts, uint32[] calldata initAllocations) external {
        uint256 tokenId = toTokenId(sourceAccount);

        uint256 numAccs = accounts.length;

        if (accounts.length != initAllocations.length)
            revert AccountsAndAllocationsMismatch(
                accounts.length,
                initAllocations.length
            );

        if (_getSum(initAllocations) != TOTAL_SUPPLY)
            revert InvalidAllocationsSum(_getSum(initAllocations));

        unchecked {
            for (uint256 i; i < numAccs; ++i) {
                _mint(accounts[i], tokenId, initAllocations[i], "");
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

    function _afterTokenTransfer(
        address,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory,
        bytes memory
    ) internal virtual override {
        for (uint256 i = 0; i < ids.length; ++i) {
            bytes32 indexTo = keccak256(abi.encode(ids[i], to));
            if (from == address(0) || balanceOf(from, ids[i]) != 0) {
                ownerIndexes[indexTo] = owners[ids[i]].length;
                owners[ids[i]].push(to);
            } else {
                bytes32 indexFrom = keccak256(abi.encode(ids[i], from));
                owners[ids[i]][ownerIndexes[indexFrom]] = to;
                ownerIndexes[indexTo] = ownerIndexes[indexFrom];
                delete ownerIndexes[indexFrom];
            }
        }
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

    function percentage(address sourceAccount, address account) public view returns (uint32) {
        unchecked {
            return uint32(balanceOf(account, toTokenId(sourceAccount)));
        }
    }

    function toTokenId(address sourceAccount) public pure returns (uint256 tokenId) {
        tokenId = uint256(uint160(sourceAccount));
    }

    function _getSum(uint32[] calldata numbers) internal pure returns (uint32 sum) {
        uint256 numbersLength = numbers.length;
        for (uint256 i; i < numbersLength;) {
            sum += numbers[i];
            unchecked {
                // overflow should be impossible in for-loop index
                ++i;
            }
        }
    }

    function sort(address[] memory data) internal pure {
        uint length = data.length;
        for (uint i = 1; i < length; i++) {
            address key = data[i];
            int j = int(i - 1);
            while ((j >= 0) && (data[uint(j)] > key)) {
                data[uint(j) + 1] = data[uint(j)];
                j--;
            }
            data[uint(j + 1)] = key;
        }
    }
}
