// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../libraries/LibDiamond.sol";

contract SVGFacet {
    event NFTMetadataSet(uint256 indexed tokenId, string name, string description);

    function setNFTMetadata(
        uint256 _tokenId,
        string calldata _name,
        string calldata _description
    ) external {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        require(msg.sender == ds.owner, "Not owner");
        
        ds.nftNames[_tokenId] = _name;
        ds.nftDescriptions[_tokenId] = _description;
        
        emit NFTMetadataSet(_tokenId, _name, _description);
    }

    function generateSVG(uint256 _tokenId) public view returns (string memory) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        
        string memory name = ds.nftNames[_tokenId];
        if (bytes(name).length == 0) {
            name = "Diamond NFT";
        }
        
        return string(abi.encodePacked(
            '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 400 400">',

            '<defs>',
            '<linearGradient id="bg" x1="0%" y1="0%" x2="100%" y2="100%">',
            '<stop offset="0%" style="stop-color:#0a0a1a;stop-opacity:1"/>',
            '<stop offset="100%" style="stop-color:#0d0d2b;stop-opacity:1"/>',
            '</linearGradient>',

            '<linearGradient id="g1" x1="0%" y1="0%" x2="100%" y2="100%">',
            '<stop offset="0%" style="stop-color:#a8d8ff;stop-opacity:1"/>',
            '<stop offset="100%" style="stop-color:#4a90d9;stop-opacity:1"/>',
            '</linearGradient>',
            '<linearGradient id="g2" x1="100%" y1="0%" x2="0%" y2="100%">',
            '<stop offset="0%" style="stop-color:#ffffff;stop-opacity:0.9"/>',
            '<stop offset="100%" style="stop-color:#7ec8ff;stop-opacity:0.7"/>',
            '</linearGradient>',
            '<linearGradient id="g3" x1="0%" y1="0%" x2="0%" y2="100%">',
            '<stop offset="0%" style="stop-color:#2a6db5;stop-opacity:1"/>',
            '<stop offset="100%" style="stop-color:#0a3060;stop-opacity:1"/>',
            '</linearGradient>',
            '<filter id="glow">',
            '<feGaussianBlur stdDeviation="4" result="blur"/>',
            '<feMerge><feMergeNode in="blur"/><feMergeNode in="SourceGraphic"/></feMerge>',
            '</filter>',
            '</defs>',

            '<rect width="400" height="400" fill="url(#bg)"/>',

            '<ellipse cx="200" cy="210" rx="90" ry="60" fill="#4a90d9" opacity="0.15" filter="url(#glow)"/>',

            '<polygon points="200,80 160,160 240,160" fill="url(#g2)"/>',
            '<polygon points="200,80 130,150 160,160" fill="url(#g1)" opacity="0.85"/>',
            '<polygon points="200,80 270,150 240,160" fill="url(#g1)" opacity="0.7"/>',

            '<polygon points="130,150 160,160 140,175" fill="#c8e6ff" opacity="0.5"/>',
            '<polygon points="270,150 240,160 260,175" fill="#c8e6ff" opacity="0.4"/>',

            '<polygon points="160,160 240,160 220,230 180,230" fill="url(#g1)" opacity="0.9"/>',
            '<polygon points="160,160 180,230 140,175" fill="url(#g3)"/>',
            '<polygon points="240,160 260,175 220,230" fill="url(#g3)" opacity="0.85"/>',

            '<polygon points="180,230 220,230 200,300" fill="url(#g2)" opacity="0.8"/>',
            '<polygon points="180,230 140,175 200,300" fill="url(#g3)" opacity="0.9"/>',
            '<polygon points="220,230 260,175 200,300" fill="#1a4f8a" opacity="0.9"/>',

            '<polygon points="200,88 188,130 212,130" fill="#ffffff" opacity="0.6"/>',

            '<text x="200" y="355" text-anchor="middle" fill="#a8d8ff" ',
            'font-family="monospace" font-size="18" font-weight="bold">', name, '</text>',
            '<text x="200" y="378" text-anchor="middle" fill="#4a7faa" ',
            'font-family="monospace" font-size="12">ID: ', uint2str(_tokenId), '</text>',

            '</svg>'
        ));
    }

    function tokenURI(uint256 _tokenId) external view returns (string memory) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        
        string memory svg = generateSVG(_tokenId);
        string memory name = ds.nftNames[_tokenId];
        string memory description = ds.nftDescriptions[_tokenId];
        
        string memory json = string(abi.encodePacked(
            '{"name":"', name, '",',
            '"description":"', description, '",',
            '"image":"data:image/svg+xml;base64,', base64Encode(bytes(svg)), '"}'
        ));
        
        return string(abi.encodePacked("data:application/json;base64,", base64Encode(bytes(json))));
    }

    function uint2str(uint256 _i) internal pure returns (string memory) {
        if (_i == 0) return "0";
        uint256 j = _i;
        uint256 len;
        while (j != 0) { len++; j /= 10; }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) { k = k - 1; uint8 temp = (48 + uint8(_i - _i / 10 * 10)); bytes1 b1 = bytes1(temp); bstr[k] = b1; _i /= 10; }
        return string(bstr);
    }

    function base64Encode(bytes memory _data) internal pure returns (string memory) {
        return "BASE64_PLACEHOLDER";
    }
}