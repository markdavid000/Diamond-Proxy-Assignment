// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../contracts/libraries/LibDiamond.sol";
import "../contracts/facets/StakingFacet.sol";
import "../contracts/facets/BorrowerFacet.sol";
import "../contracts/facets/MarketPlaceFacet.sol";
import "../contracts/facets/MultisigFacet.sol";
import "../contracts/facets/SVGFacet.sol";
import "../contracts/interfaces/IERC20.sol";
import "../contracts/interfaces/IERC721.sol";

// ========== MOCK ERC20 ==========
contract MockERC20 is IERC20 {
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    function mint(address to, uint256 amount) external {
        balanceOf[to] += amount;
    }

    function transfer(address to, uint256 amount) public returns (bool) {
        require(balanceOf[msg.sender] >= amount, "Insufficient balance");
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public returns (bool) {
        require(balanceOf[from] >= amount, "Insufficient balance");
        require(allowance[from][msg.sender] >= amount, "Allowance exceeded");
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        allowance[from][msg.sender] -= amount;
        emit Transfer(from, to, amount);
        return true;
    }

    function totalSupply() external pure returns (uint256) { return 0; }
}

// ========== MOCK ERC721 ==========
contract MockERC721 is IERC721 {
    mapping(uint256 => address) public ownerOf;
    mapping(address => uint256) public balanceOf;

    function mint(address to, uint256 tokenId) external {
        ownerOf[tokenId] = to;
        balanceOf[to]++;
    }

    function transferFrom(address from, address to, uint256 tokenId) public {
        require(ownerOf[tokenId] == from, "Not owner");
        ownerOf[tokenId] = to;
        balanceOf[from]--;
        balanceOf[to]++;
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) external {
        transferFrom(from, to, tokenId);
    }

    function approve(address, uint256) external {}
    function getApproved(uint256) external pure returns (address) { return address(0); }
    function setApprovalForAll(address, bool) external {}
    function isApprovedForAll(address, address) external pure returns (bool) { return false; }
    function totalSupply() external pure returns (uint256) { return 0; }
}

// ========== TEST CONTRACT ==========
contract DiamondTest is Test {
    StakingFacet public stakingFacet;
    BorrowerFacet public borrowerFacet;
    MarketplaceFacet public marketplaceFacet;
    MultisigFacet public multisigFacet;
    SVGFacet public svgFacet;

    MockERC20 public erc20Token;
    MockERC721 public erc721Token;

    address public user1 = address(1);
    address public user2 = address(2);
    address public signer1 = address(4);
    address public signer2 = address(5);

    bytes32 constant DIAMOND_SLOT = keccak256("diamond.standard.diamond.storage");

    function setUp() public {
        // Deploy mocks
        erc20Token = new MockERC20();
        erc721Token = new MockERC721();

        // Deploy facets
        stakingFacet     = new StakingFacet();
        borrowerFacet    = new BorrowerFacet();
        marketplaceFacet = new MarketplaceFacet();
        multisigFacet    = new MultisigFacet();
        svgFacet         = new SVGFacet();

        bytes32 ownerSlot  = bytes32(uint256(DIAMOND_SLOT) + 3);
        bytes32 erc20Slot  = bytes32(uint256(DIAMOND_SLOT) + 8);
        bytes32 erc721Slot = bytes32(uint256(DIAMOND_SLOT) + 9);

        address[5] memory facets = [
            address(stakingFacet),
            address(borrowerFacet),
            address(marketplaceFacet),
            address(multisigFacet),
            address(svgFacet)
        ];

        for (uint256 i = 0; i < facets.length; i++) {
            vm.store(facets[i], ownerSlot,  bytes32(uint256(uint160(address(this)))));
            vm.store(facets[i], erc20Slot,  bytes32(uint256(uint160(address(erc20Token)))));
            vm.store(facets[i], erc721Slot, bytes32(uint256(uint160(address(erc721Token)))));
        }

        // Mint ERC20 for users
        erc20Token.mint(user1, 1000 * 10 ** 18);
        erc20Token.mint(user2, 1000 * 10 ** 18);
        erc20Token.mint(address(stakingFacet), 1000 * 10 ** 18);

        // Mint ERC721s
        erc721Token.mint(address(this), 1);
        erc721Token.mint(user1, 2);
    }

    // ========== STAKING TESTS ==========

    function test_StakeTokens() public {
        vm.startPrank(user1);
        erc20Token.approve(address(stakingFacet), 100 * 10 ** 18);
        stakingFacet.stakeTokens(100 * 10 ** 18);
        vm.stopPrank();

        assertEq(stakingFacet.fetchStakingBalance(user1), 100 * 10 ** 18);
    }

    function test_UnstakeTokens() public {
        vm.startPrank(user1);
        erc20Token.approve(address(stakingFacet), 100 * 10 ** 18);
        stakingFacet.stakeTokens(100 * 10 ** 18);
        stakingFacet.unstakeTokens(50 * 10 ** 18);
        vm.stopPrank();

        assertEq(stakingFacet.fetchStakingBalance(user1), 50 * 10 ** 18);
    }

    // ========== SVG TESTS ==========

    function test_GenerateSVG() public view {
        string memory svg = svgFacet.generateSVG(1);
        assertTrue(bytes(svg).length > 0);
        assertTrue(contains(svg, "Diamond NFT"));
    }

    function test_TokenURI() public view {
        string memory uri = svgFacet.tokenURI(1);
        assertTrue(bytes(uri).length > 0);
    }

    // ========== MULTISIG TESTS ==========

    function test_RegisterSigner() public {
        multisigFacet.registerSigner(signer1);
        assertTrue(multisigFacet.verifyIsSigner(signer1));
    }

    function test_SubmitProposal() public {
        multisigFacet.registerSigner(signer1);

        vm.prank(signer1);
        uint256 id = multisigFacet.submitProposal(
            new LibDiamond.FacetCut[](0),
            address(0),
            ""
        );
        assertEq(id, 0);
    }

    // ========== MARKETPLACE TESTS ==========

    function test_Marketplace_CreateListing_RevertsWithoutApproval() public {
        vm.prank(user1);
        vm.expectRevert();
        marketplaceFacet.createListing(1, 100 * 10 ** 18);
    }

    // ========== BORROWER TESTS ==========

    function test_Borrower_InitiateLoan_RevertsWithoutCollateral() public {
        vm.prank(user1);
        vm.expectRevert();
        borrowerFacet.initiateLoan(1, 500 * 10 ** 18, 86400);
    }

    // ========== HELPERS ==========

    function contains(string memory haystack, string memory needle) internal pure returns (bool) {
        return bytes(haystack).length >= bytes(needle).length && find(haystack, needle) != -1;
    }

    function find(string memory haystack, string memory needle) internal pure returns (int256) {
        bytes memory h = bytes(haystack);
        bytes memory n = bytes(needle);
        if (n.length == 0) return 0;
        if (h.length < n.length) return -1;
        for (uint256 i = 0; i <= h.length - n.length; i++) {
            bool found = true;
            for (uint256 j = 0; j < n.length; j++) {
                if (h[i + j] != n[j]) { found = false; break; }
            }
            if (found) return int256(i);
        }
        return -1;
    }
}