pragma solidity >=0.6.0 <0.9.0;
import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./USDT.sol";

interface ERC20 {
    function transfer(address to, uint256 tokens)
        external
        returns (bool success);

    function transferFrom(
        address from,
        address to,
        uint256 tokens
    ) external returns (bool success);

    function balanceOf(address tokenOwner)
        external
        view
        returns (uint256 balance);

    function approve(address spender, uint256 tokens)
        external
        returns (bool success);

    function allowance(address tokenOwner, address spender)
        external
        view
        returns (uint256 remaining);

    function totalSupply() external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(
        address indexed tokenOwner,
        address indexed spender,
        uint256 tokens
    );
}

contract Keey is ERC20 {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public override totalSupply;
    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowed;

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _totalSupply
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _totalSupply;
        balances[msg.sender] = _totalSupply;
    }

    function transfer(address to, uint256 value)
        public
        override
        returns (bool)
    {
        require(balances[msg.sender] >= value, "Not enough Keey!!!");
        balances[msg.sender] -= value;
        balances[to] += value;
        emit Transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) public override returns (bool) {
        require(
            balances[msg.sender] >= value && allowed[from][msg.sender] >= value,
            "Not enough Keey!!!"
        );
        allowed[from][msg.sender] -= value;
        balances[msg.sender] -= value;
        balances[to] += value;
        emit Transfer(msg.sender, to, value);
        return true;
    }

    function approve(address spender, uint256 value)
        public
        override
        returns (bool)
    {
        require(spender != msg.sender);
        allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return allowed[owner][spender];
    }

    function balanceOf(address owner) public view override returns (uint256) {
        return balances[owner];
    }
}

contract SellKeey {
    address public minter;
    uint256 public priceEther;
    uint256 public priceUSDT;
    Keey public keey;
    USDT public usdt;
    bool internal isSuccess;
    mapping(address => uint256) public lastReceived;

    event Sold(address buyer, uint256 amount);

    constructor() {
        minter = msg.sender;
        keey = new Keey("Keey Coin", "KEEY", 0, 2500);
        usdt = new USDT(
            0x90F79bf6EB2c4f870365E785982E1f101E93b906,
            100000 * (10**18)
        ); //Add balance USDT for adress b906
        priceEther = (1 / 100) * (10**18);
        priceUSDT = 10000 * (10**18);
    }

    receive() external payable {}

    function sellKeey() external payable {
        //buy by Ether
        uint256 valueToBuy = msg.value / priceEther; // 1Keey = 0.01 ether

        require(msg.value % priceEther == 0, "Enter only positive integers!!!");
        require(msg.value > 0, "You need to buy at least some tokens!!!");
        require(
            keey.balanceOf(msg.sender) + valueToBuy <= 2,
            "Wallet buys up to 2 KEEY"
        );
        require(
            block.timestamp - lastReceived[msg.sender] > 1 days,
            "Just 01 tranfer per day for this address!!!"
        );

        //Then send Keey
        require(keey.transfer(msg.sender, valueToBuy), "error send keey");

        emit Sold(msg.sender, valueToBuy);
        updateLastReceived(msg.sender);
    }

    function sellKeeyByUsdt(uint256 value) external {
        //buy by USDT
        uint256 valueToBuy = value * priceUSDT; // 1Keey = 10000 USDT

        require(valueToBuy % priceUSDT == 0, "Enter only positive integers!!!");
        require(value > 0, "You need to buy at least some tokens!!!");
        require(
            keey.balanceOf(msg.sender) + value <= 2,
            "Wallet can only buy up to 2 KEEY!!!"
        );
        require(
            block.timestamp - lastReceived[msg.sender] > 1 days,
            "Just 01 tranfer per day for this address!!!"
        );

        //Send usdt to contract for main net // with testnet must creat new token pool USDT and replace address
        // IERC20 usdt = IERC20(address(0xdAC17F958D2ee523a2206206994597C13D831ec7));//Address contract USDT

        //Send usdt to contract for local
        require(
            usdt.transferFrom(msg.sender, address(this), valueToBuy),
            "Not enough USDT in your wallet!!!"
        );

        //Then send Keey
        require(keey.transfer(msg.sender, value), "error send keey");

        emit Sold(msg.sender, value);
        updateLastReceived(msg.sender);
    }

    function balanceOf(address owner) public view returns (uint256) {
        return keey.balanceOf(owner);
    }

    function withdraw(address payable to, uint256 amount) external forMinter {
        to.transfer(amount);
    }

    modifier forMinter() {
        require(msg.sender == minter, "Only for minter");
        _;
    }

    function updateLastReceived(address receiver) internal {
        lastReceived[receiver] = block.timestamp;
    }

    function getLastReceived(address receiver) public view returns (bool) {
        if (block.timestamp - lastReceived[msg.sender] > 1 days) {
            return true;
        }
        return false;
    }
}
