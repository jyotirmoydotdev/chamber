// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../lib/forge-std/src/Test.sol";

import { Registry } from "../src/Registry.sol";
import { Chamber } from "../src/Chamber.sol";

import { IRegistry } from "../src/interfaces/IRegistry.sol";
import { IChamber } from "../src/interfaces/IChamber.sol";
import { IChamberProxy } from "../src/interfaces/IChamberProxy.sol";
import { DeployRegistry } from "../test/utils/DeployRegistry.sol";

import { MockERC20 } from "../lib/contract-utils/src/MockERC20.sol";
import { MockNFT } from "../lib/contract-utils/src/MockNFT.sol";
import { ERC1967Proxy } from "../lib/openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract ProxyUpgradeTest is Test {

    MockERC20 mERC20;
    MockNFT mERC721;
    
    IRegistry registry;
    IChamber chamber;

    IChamberProxy multiProxy;
    IChamberProxy MultiProxy;

    address chamberProxyAddr;
    address registryProxyAddr;

    function setUp() public {
            
        mERC20 = new MockERC20("MockERC20", "mERC20", address(this));
        mERC721 = new MockNFT("MockNFT", "mNFT", address(this));

        DeployRegistry registryDeployer = new DeployRegistry();
        registryProxyAddr = registryDeployer.deploy(address(this));
        chamberProxyAddr = IRegistry(registryProxyAddr).deploy(address(mERC721), address(mERC20));
        
        MultiProxy = IChamberProxy(chamberProxyAddr);
        multiProxy = IChamberProxy(registryProxyAddr);

        chamber = IChamber(chamberProxyAddr);
        registry = IRegistry(registryProxyAddr);
    }

    function test_Proxy_upgrade() public {
        MultiProxy.getImplementation();
        mERC20.approve(address(MultiProxy), 1000);
        chamber.promote(1, 1);
        (uint256[] memory leaders, uint256[] memory amounts) = chamber.getLeaderboard();
        Chamber chamberV2 = new Chamber();

        MultiProxy.upgradeTo(address(chamberV2));
        (uint256[] memory newLeaders, uint256[] memory newAmounts) = chamber.getLeaderboard();
        assertEq(newLeaders[0], leaders[0]);
        assertEq(newAmounts[0], amounts[0]); 
        assertEq(MultiProxy.getImplementation(), address(chamberV2));
        IChamber(address(MultiProxy)).getLeaderboard();
    }

    function test_Proxy_access() public {
        Chamber chamberV2 = new Chamber();
        
        vm.expectRevert();
        MultiProxy.changeAdmin(address(0));

        vm.startPrank(address(1));
        vm.expectRevert();
        MultiProxy.changeAdmin(address(1));
        vm.stopPrank();

        MultiProxy.changeAdmin(address(1));
        assertEq(MultiProxy.getAdmin(), address(1));
        
        vm.expectRevert();
        MultiProxy.upgradeTo(address(chamberV2));
        MultiProxy.getImplementation();

        Chamber chamberV3 = new Chamber();
        vm.prank(address(1));
        MultiProxy.upgradeTo(address(chamberV3));
        assertEq(MultiProxy.getImplementation(), address(chamberV3));
    } 
}