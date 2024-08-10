// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ERC20 {
    string private name;
    string private symbol;
    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowances;

    uint256 private totalSupply;
    address private owner;

    bool private paused;
    mapping(address => uint256) public nonces;

    bytes32 public DOMAIN_SEPARATOR;

    event Paused(address account);
    event Transfer(address sender, address recipient, uint256 amount);
    event Approval(address owner, address spender, uint256 amount);
    event TransferFrom(address sender, address recipient, uint256 amount);

    modifier whenNotPaused() {
        require(msg.sender == owner, "Only Owner");
        require(!paused, "ERC20: paused");
        _;
    }

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
        balances[msg.sender] = 1000 ether;
        totalSupply = 1000 ether;
        paused = false;
        owner = msg.sender;

        uint256 chainId;
        assembly {
            chainId := chainid()
        }

        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes(_name)),
                keccak256(bytes("1")),
                chainId,
                address(this)
            )
        );
    }

    function transfer(
        address recipient,
        uint256 amount
    ) public whenNotPaused returns (bool) {
        require(
            balances[msg.sender] >= amount,
            "ERC20: transfer amount exceeds balance"
        );
        require(recipient != address(0), "Recipient is must not zero address");
        balances[msg.sender] -= amount;
        balances[recipient] += amount;
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public whenNotPaused returns (bool) {
        require(
            balances[sender] >= amount,
            "ERC20: transfer amount exceeds balance"
        );
        require(
            allowances[sender][msg.sender] >= amount,
            "ERC20: transfer amount exceeds allowance"
        );
        balances[sender] -= amount;
        balances[recipient] += amount;
        allowances[sender][msg.sender] -= amount;
        emit TransferFrom(sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function pause() public whenNotPaused {
        require(msg.sender == owner, "ERC20: not owner");
        paused = true;
        emit Paused(msg.sender);
    }

    function allowance(
        address owner,
        address spender
    ) public view returns (uint256) {
        return allowances[owner][spender];
    }

    function _toTypedDataHash(
        bytes32 structHash
    ) public view returns (bytes32) {
        return
            keccak256(
                abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, structHash)
            );
    }

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        require(block.timestamp <= deadline, "ERC20: expired permit");
        bytes32 structHash = keccak256(
            abi.encode(
                keccak256(
                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                ),
                owner,
                spender,
                value,
                nonces[owner]++,
                deadline
            )
        );
        bytes32 hash = _toTypedDataHash(structHash);
        address signer = ecrecover(hash, v, r, s);
        require(signer == owner, "INVALID_SIGNER");
        allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }
}
