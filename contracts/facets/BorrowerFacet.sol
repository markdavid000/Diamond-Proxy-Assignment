// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../libraries/LibDiamond.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/IERC721.sol";

contract BorrowerFacet {
    event LoanInitiated(uint256 indexed loanId, address borrower, uint256 tokenId);
    event LoanRepaid(uint256 indexed loanId);
    event LoanDefaulted(uint256 indexed loanId);

    function initiateLoan(
        uint256 _tokenId,
        uint256 _collateral,
        uint256 _duration
    ) external {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        
        // Transfer collateral to diamond
        IERC20(ds.erc20Token).transferFrom(msg.sender, address(this), _collateral);
        
        // Transfer NFT to borrower
        IERC721(ds.erc721Token).transferFrom(address(this), msg.sender, _tokenId);
        
        uint256 loanId = ds.loanCount++;
        LibDiamond.Loan storage loan = ds.loans[loanId];
        
        loan.borrower = msg.sender;
        loan.tokenId = _tokenId;
        loan.collateral = _collateral;
        loan.duration = _duration;
        loan.startTime = block.timestamp;
        loan.active = true;
        
        emit LoanInitiated(loanId, msg.sender, _tokenId);
    }

    function repayLoan(uint256 _loanId) external {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        LibDiamond.Loan storage loan = ds.loans[_loanId];
        
        require(loan.active, "Loan not active");
        require(msg.sender == loan.borrower, "Not borrower");
        
        // Return NFT to diamond
        IERC721(ds.erc721Token).transferFrom(msg.sender, address(this), loan.tokenId);
        
        // Return collateral to borrower
        IERC20(ds.erc20Token).transfer(loan.borrower, loan.collateral);
        
        loan.active = false;
        
        emit LoanRepaid(_loanId);
    }

    function enforceLoanDefault(uint256 _loanId) external {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        LibDiamond.Loan storage loan = ds.loans[_loanId];
        
        require(loan.active, "Loan not active");
        require(block.timestamp >= loan.startTime + loan.duration, "Not expired");
        
        // NFT stays with borrower (they defaulted)
        // Collateral stays with diamond (as penalty)
        loan.active = false;
        
        emit LoanDefaulted(_loanId);
    }

    function fetchLoanDetails(uint256 _loanId) external view returns (
        address borrower,
        uint256 tokenId,
        uint256 collateral,
        uint256 duration,
        uint256 startTime,
        bool active
    ) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        LibDiamond.Loan storage loan = ds.loans[_loanId];
        
        return (
            loan.borrower,
            loan.tokenId,
            loan.collateral,
            loan.duration,
            loan.startTime,
            loan.active
        );
    }
}