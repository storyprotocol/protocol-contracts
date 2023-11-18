// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import { Licensing } from "contracts/lib/modules/Licensing.sol";
import { EnumerableSet } from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import { ShortString, ShortStrings } from "@openzeppelin/contracts/utils/ShortStrings.sol";
import { Multicall } from "@openzeppelin/contracts/utils/Multicall.sol";
import { Errors } from "contracts/lib/Errors.sol";
import { IHook } from "contracts/interfaces/hooks/base/IHook.sol";
import { AccessControlled } from "contracts/access-control/AccessControlled.sol";
import { AccessControl } from "contracts/lib/AccessControl.sol";

/// @title TermsRepository
/// @notice Protocol repository for terms that can be used by Licensing Modules to compose
/// licenses. Terms are grouped by categories, and each term has a unique id within its category.
/// Terms are added by the protocol.
/// The text of the terms is not stored in the contract, but in external storage.
contract TermsRepository is AccessControlled, Multicall {
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

    modifier onlyValidTerm(ShortString termId_) {
        if (_terms[termId_].comStatus == Licensing.CommercialStatus.Unset) {
            revert Errors.TermsRegistry_UnsupportedTerm();
        }
        _;
    }

    modifier onlyValidTermString(string memory termId_) {
        ShortString termId = termId_.toShortString();
        if (_terms[termId].comStatus == Licensing.CommercialStatus.Unset) {
            revert Errors.TermsRegistry_UnsupportedTerm();
        }
        _;
    }

    constructor(address accessControl_) AccessControlled(accessControl_) { }

    /// Adds a new category of terms
    function addCategory(string calldata category_) public {
        _termCategories.add(ShortString.unwrap(category_.toShortString()));
        emit TermCategoryAdded(category_);
    }

    /// Removes a category of terms
    function removeCategory(string calldata category_) public {
        _termCategories.remove(ShortString.unwrap(category_.toShortString()));
        emit TermCategoryRemoved(category_);
    }

    /// Returns the total number of term categories
    function totalTermCategories() public view returns (uint256) {
        return _termCategories.length();
    }

    /// Returns the term category at the given index
    function termCategoryAt(
        uint256 index_
    ) public view returns (string memory) {
        return ShortString.wrap(_termCategories.at(index_)).toString();
    }

    /// Adds a new term to a category
    /// @param category_ The category to add the term to
    /// @param termId_ The unique id of the term within the category
    /// @param term_ The term definition
    function addTerm(
        string calldata category_,
        string calldata termId_,
        Licensing.LicensingTerm calldata term_
    ) public onlyRole(AccessControl.TERMS_SETTER_ROLE) {
        // TODO: access control
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

    function categoryForTerm(
        string calldata termId_
    ) public view returns (string memory) {
        return _termCategoryByTermId[termId_.toShortString()].toString();
    }

    function shortStringCategoryForTerm(
        ShortString termId_
    ) public view returns (ShortString) {
        return _termCategoryByTermId[termId_];
    }

    function getTerm(
        ShortString termId_
    ) public view onlyValidTerm(termId_) returns (Licensing.LicensingTerm memory) {
        return _terms[termId_];
    }

    function getTermHook(
        ShortString termId_
    ) public view onlyValidTerm(termId_) returns (IHook) {
        return getTerm(termId_).hook;
    }

    function getTerm(
        string memory termId_
    ) public view onlyValidTermString(termId_) returns (Licensing.LicensingTerm memory) {
        ShortString termId = termId_.toShortString();
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
