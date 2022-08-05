// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.9;

import "./@openzeppelin/contracts/security/Pausable.sol";
import "./@openzeppelin/contracts/access/Ownable.sol";
import "./@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";

interface iCollection {
    function transferFrom(address from,address to,uint256 tokenId) external;
}

contract ReentrancyGuard {
  bool private reentrancyLock = false;
  
  modifier nonReentrant() {
    require(!reentrancyLock);
    reentrancyLock = true;
    _;
    reentrancyLock = false;
  }
}

contract TradeEthNFT is Pausable, Ownable,ReentrancyGuard {
    /* to set 0.5% commission, set multiplier as 1 and divisor as 2 i.e 1/2 */
    uint256 _feeMultiplier=1;
    uint256 _feeDivisor=2;
    iCollection cAddr;
    
    event FeeChanged(uint256 feeMultiplier,uint256 feeDivisor);
    event BuyNFT(address to,uint256 count,uint256 price);
    mapping(uint256 => bool) usedNonces;

    constructor(iCollection tokenAddress) {
        require(address(tokenAddress) != address(0), "tokenAddress cannot be address 0");
        cAddr = tokenAddress;
    }

    function setFee(uint256 feeMul, uint256 feeDiv) external onlyOwner {
        _feeMultiplier=feeMul;
        _feeDivisor=feeDiv;
        emit FeeChanged(feeMul,feeDiv);
    }

    function toEthSignedMessageHash(bytes32 hash) public pure returns (bytes32)
    {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    function verify(address _signer,
        uint256 _tokenId,
        address _from,
        uint256 _ethValue,
        uint256 _nonce,
        bytes calldata signature
    ) public view returns (bool) {
        
        bytes32 ethMessageHash = toEthSignedMessageHash(keccak256(abi.encode(_tokenId, _from, _ethValue, _nonce)));
        return SignatureChecker.isValidSignatureNow(_signer,ethMessageHash,signature);
    }

    function BuyEthNFT(uint256  _tokenId,address _from,uint256 _nonce,bytes calldata signature
    ) external payable nonReentrant whenNotPaused {
        require(!usedNonces[_nonce], "already used");
        require(msg.value >0,'Invalid amount');
        require(
            verify(owner(), _tokenId, _from, msg.value, _nonce, signature),
            "invalid request"
        );

        usedNonces[_nonce] = true;
        uint ethVal=0;

        if (_feeMultiplier > 0)
            /* deduct commission from amount */
            ethVal=msg.value - ((msg.value * _feeMultiplier)/(_feeDivisor*100));
        else
            ethVal = msg.value;

        /* Transfer NFT to Buyer */
        cAddr.transferFrom(_from, _msgSender(), _tokenId);
        /* Transfer eth to seller */
        (bool success,  ) = _from.call{value: ethVal}("");
        require(success, "Transfer failed.");

        emit BuyNFT(_msgSender(), _tokenId,msg.value);
    }

    /* Dont accept eth*/  
    receive() external payable {
        revert("The contract does not accept direct payment, please use the purchase method with a referral address.");
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
}
