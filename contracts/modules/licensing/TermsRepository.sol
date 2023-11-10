// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import { Licensing } from "contracts/lib/modules/Licensing.sol";
import { EnumerableSet } from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import { ShortString, ShortStrings } from "@openzeppelin/contracts/utils/ShortStrings.sol";
import { Errors } from "contracts/lib/Errors.sol";

contract TermsRepository {
    using EnumerableSet for EnumerableSet.Bytes32Set;
    using ShortStrings for *;

    event TermCategoryAdded(string category);
    event TermCategoryRemoved(string category);
    event TermAdded(string category, string termId);
    event TermDisabled(string category, string termId);

    EnumerableSet.Bytes32Set private _termCategories;
    // TermId -> LicensingTerm
    mapping(ShortString => Licensing.LicensingTerm) private _terms;
    // CategoryId -> TermIds[]
    mapping(ShortString => EnumerableSet.Bytes32Set) private _termIdsByCategory;
    // TermId -> CategoryId
    mapping(ShortString => ShortString) private _termCategoryByTermId;

    function addTermCategory(string calldata category_) public {
        _termCategories.add(ShortString.unwrap(category_.toShortString()));
        emit TermCategoryAdded(category_);
    }

    function removeTermCategory(string calldata category_) public {
        _termCategories.remove(ShortString.unwrap(category_.toShortString()));
        emit TermCategoryRemoved(category_);
    }

    function totalTermCategories() public view returns (uint256) {
        return _termCategories.length();
    }

    function termCategoryAt(
        uint256 index_
    ) public view returns (string memory) {
        return ShortString.wrap(_termCategories.at(index_)).toString();
    }

    // TODO: access control
    function addTerm(
        string calldata category_,
        string calldata termId_,
        Licensing.LicensingTerm calldata term_
    ) public {
        ShortString category = category_.toShortString();
        _verifyCategoryExists(category);
        if (term_.comStatus == Licensing.CommercialStatus.Unset) {
            revert Errors.TermsRegistry_CommercialStatusUnset();
        }
        ShortString termId = termId_.toShortString();

        if (_terms[termId].comStatus != Licensing.CommercialStatus.Unset) {
            revert Errors.TermsRegistry_TermAlreadyExists();
        }
        _terms[termId] = term_;
        _termIdsByCategory[category].add(ShortString.unwrap(termId));
        emit TermAdded(category_, termId_);
    }

    // TODO: access control
    function disableTerm(
        string calldata category_,
        string calldata termId_
    ) public {
        ShortString category = category_.toShortString();
        _verifyCategoryExists(category);
        ShortString termId = termId_.toShortString();
        _termIdsByCategory[category].add(ShortString.unwrap(termId));
        emit TermDisabled(category_, termId_);
    }

    function categoryForTerm(
        string calldata termId_
    ) public view returns (string memory) {
        return _termCategoryByTermId[termId_.toShortString()].toString();
    }

    function getTerm(
        string memory termId_
    ) public view returns (Licensing.LicensingTerm memory) {
        ShortString termId = termId_.toShortString();
        if (_terms[termId].comStatus == Licensing.CommercialStatus.Unset) {
            revert Errors.TermsRegistry_UnsupportedTerm();
        }
        return _terms[termId];
    }

    function totalTermsForCategory(
        string calldata category_
    ) public view returns (uint256) {
        ShortString category = category_.toShortString();
        _verifyCategoryExists(category);
        return _termIdsByCategory[category].length();
    }

    function termForCategoryAt(
        string calldata category_,
        uint256 index_
    ) public view returns (Licensing.LicensingTerm memory) {
        ShortString category = category_.toShortString();
        _verifyCategoryExists(category);
        ShortString termId = ShortString.wrap(
            _termIdsByCategory[category].at(index_)
        );
        return _terms[termId];
    }

    function _verifyCategoryExists(ShortString category_) private view {
        if (!_termCategories.contains(ShortString.unwrap(category_))) {
            revert Errors.TermsRegistry_UnsupportedTermCategory();
        }
    }
}
