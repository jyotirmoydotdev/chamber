// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { MultiProxy } from "./MultiProxy.sol";
import { IChamber } from "./interfaces/IChamber.sol";
import { IRegistry } from "./interfaces/IRegistry.sol";
import { Ownable } from "openzeppelin-contracts/contracts/access/Ownable.sol";
import { Initializable } from "openzeppelin-contracts/contracts/proxy/utils/Initializable.sol";

contract Registry is IRegistry, Initializable, Ownable {

    /// @notice totalChamber The total number of Chambers
    uint256 public totalChambers;

    /// @notice chambers The Deployed Chambers
    /// @dev serial index -> ChamberData Struct
    mapping(uint256 => ChamberData) public chambers;

    /// @notice chamerVersion is the latest version of the Chamber contract
    address public chamberVersion;

    /// @notice contructor disables initializers
    constructor() { _disableInitializers(); }

    /// @inheritdoc IRegistry
    function initialize(address _chamberVersion, address _owner) external initializer {
        require(_owner != address(0),"The address is zero");
        require(_chamberVersion != address(0),"The address is zero");
        super._transferOwnership(_owner);
        chamberVersion = _chamberVersion;
    }

    /// @inheritdoc IRegistry
    function setChamberVersion(address _chamberVersion) external onlyOwner {
        require(_chamberVersion != address(0), "The address is zero");
        chamberVersion = _chamberVersion;
    }

    /// @inheritdoc IRegistry
    function getChambers(uint256 limit, uint256 skip) external view returns (ChamberData[] memory) {
        if (limit > totalChambers && totalChambers <= 255) limit = uint256(totalChambers);
        ChamberData[] memory _chambers = new ChamberData[](limit);
        for (uint256 i = 0; i < limit; i++) {
            _chambers[i] = chambers[i + skip];
        }
        return _chambers;
    }

    /// @inheritdoc IRegistry
    function deploy(address _memberToken, address _govToken) external returns (address) {
        
        bytes memory data = abi.encodeWithSelector(IChamber.initialize.selector, _memberToken, _govToken);
        MultiProxy chamber = new MultiProxy(chamberVersion, data, msg.sender);

        ChamberData memory chamberData = ChamberData({
            chamber: address(chamber),
            memberToken: _memberToken,
            govToken: _govToken
        });
        
        chambers[totalChambers] = chamberData;
        totalChambers++;

        emit ChamberDeployed(address(chamber), totalChambers, msg.sender, _memberToken, _govToken);
        return address(chamber);
    }
}

