pragma solidity >=0.6.0 <0.7.0;

contract SupplyChain {
    address owner;
    uint256 skuCount;

    enum State {ForSale, Sold, Shipped, Received}
    struct Item {
        string name;
        uint256 sku;
        uint256 price;
        State state;
        address payable seller;
        address payable buyer;
    }

    mapping(uint256 => Item) public items;

    event LogForSale(uint256 sku);
    event LogSold(uint256 sku);
    event LogShipped(uint256 sku);
    event LogReceived(uint256 sku);

    /* Create a modifer that checks if the msg.sender is the owner of the contract */
    modifier isOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier verifyCaller(address _address) {
        require(msg.sender == _address);
        _;
    }

    modifier paidEnough(uint256 _price) {
        require(msg.value >= _price);
        _;
    }

    modifier checkValue(uint256 _sku) {
        //refund them after pay for item (why it is before, _ checks for logic before func)
        _;
        uint256 _price = items[_sku].price;
        uint256 amountToRefund = msg.value - _price;
        items[_sku].buyer.transfer(amountToRefund);
    }

    modifier forSale(uint256 sku) {
        require(items[sku].state == State.ForSale && items[sku].price != 0);
        _;
    }
    modifier sold(uint256 sku) {
        require(items[sku].state == State.Sold);
        _;
    }
    modifier shipped(uint256 sku) {
        require(items[sku].state == State.Shipped);
        _;
    }
    modifier received(uint256 sku) {
        require(items[sku].state == State.Received);
        _;
    }

    constructor() public {
        owner = msg.sender;
        skuCount = 0;
    }

    function addItem(string memory _name, uint256 _price)
        public
        returns (bool)
    {
        emit LogForSale(skuCount);
        items[skuCount] = Item({
            name: _name,
            sku: skuCount,
            price: _price,
            state: State.ForSale,
            seller: msg.sender,
            buyer: address(0)
        });
        skuCount = skuCount + 1;
        return true;
    }

    function buyItem(uint256 sku)
        public
        payable
        forSale(sku)
        paidEnough(items[sku].price)
        checkValue(sku)
    {
        LogSold(sku);

        items[sku].buyer = msg.sender;
        items[sku].state = State.Sold;

        items[sku].seller.transfer(items[sku].price);
    }

    /* Add 2 modifiers to check if the item is sold already, and that the person calling this function
  is the seller. Change the state of the item to shipped. Remember to call the event associated with this function!*/
    function shipItem(uint256 sku) public sold(sku) verifyCaller(items[sku].seller) {
        LogShipped(sku);

        items[sku].state = State.Shipped;
    }

    function receiveItem(uint256 sku)
        public
        shipped(sku)
        verifyCaller(items[sku].buyer)
    {
        LogReceived(sku);

        items[sku].state = State.Received;
    }

    /* We have these functions completed so we can run tests, just ignore it :) */

    function fetchItem(uint256 _sku)
        public
        view
        returns (
            string memory name,
            uint256 sku,
            uint256 price,
            uint256 state,
            address seller,
            address buyer
        )
    {
        name = items[_sku].name;
        sku = items[_sku].sku;
        price = items[_sku].price;
        state = uint256(items[_sku].state);
        seller = items[_sku].seller;
        buyer = items[_sku].buyer;
        return (name, sku, price, state, seller, buyer);
    }
}
