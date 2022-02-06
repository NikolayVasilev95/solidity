// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
pragma abicoder v2;

import {Ownable} from "./Ownable.sol";

contract Shop is Ownable {
    uint public sequence; // initial value is 0
    mapping(string => Product) public productStructs;
    mapping(address => Client) public clientStructs;
    address[] public buyers;

    struct Product {
        uint id;
        string name;
        uint quantity;
    }

    struct Client {
        address clientAddress;
        Product[] clientItems;
    }


    function getId() private returns (uint) {
        sequence ++;
        return sequence;
    }

    function isEmptyAddress(address _address) private pure returns (bool) {
        return _address != address(0x0);
    }

    function isEmptyStr(string memory str) private pure returns (bool) {
        return bytes(str).length > 0;
    }

    function stringsEquals(string memory s1, string memory s2) private pure returns (bool) {
        bytes memory b1 = bytes(s1);
        bytes memory b2 = bytes(s2);
        uint256 l1 = b1.length;
        if (l1 != b2.length) return false;
        for (uint256 i=0; i<l1; i++) {
            if (b1[i] != b2[i]) return false;
        }
        return true;
    }

    function getClient(address _address) private view returns (Client memory) {
        return clientStructs[_address];
    }

    function getProduct(string memory _name) private view returns (Product memory) {
        return productStructs[_name];
    }

    function isClientBuyedProduct(Product[] memory _clientItems, uint _searchedProductId) private view returns (bool) {
        bool isBuyed = false;
        for(uint i = 0; i < _clientItems.length; i++) {
            if(_clientItems[i].id == _searchedProductId) {
                isBuyed = true;
                break;
            }
        }
        return isBuyed;
    }

    function productQuantity(Product[] memory _clientItems, uint _searchedProductId) private view returns (uint) {
        uint _quantity;
        for(uint i = 0; i < _clientItems.length; i++) {
            if(_clientItems[i].id == _searchedProductId) {
                _quantity = _clientItems[i].quantity;
                break;
            }
        }
        return _quantity;
    }
    
    modifier isClient() {
        require(msg.sender != Ownable.owner, "Not client");
        _;
    }

    error ProductError(uint _id);
    function isProductFiend(uint _id) private view {
        if(_id > 0) revert ProductError(_id);
    }

    error AmountError(uint productQuantity,uint wantedQuantity);
    function isAmount(uint productQuantity,uint wantedQuantity) private view {
        if(productQuantity < wantedQuantity) revert AmountError(productQuantity, wantedQuantity);
    }

    error AlreadyBuyedtError(string productName,string wantedProductName);
    function isAlreadyBuyed(string memory productName,string memory wantedProductName) private view {
        if(stringsEquals(productName, wantedProductName)) revert AlreadyBuyedtError(productName, wantedProductName);
    }

    function addingProduct(string memory _name, uint _quantity) public onlyOwner {
        require(_quantity > 0, "Quantity must be at least 1 unit");
        Product memory fiendProduct = getProduct(_name);
        productStructs[_name] = isEmptyStr(fiendProduct.name) ? Product(fiendProduct.id, fiendProduct.name, _quantity) : Product(getId(), _name, _quantity);
    }

    // function buyProduct(string memory name, uint _quantity) public isClient {
    //     // require(id > 0, "Id must be greater then");
    //     address sender = msg.sender;
    //     Client memory fiendClient = getClient(sender);
    //     Product memory fiendProduct = getProduct(name);
    //     isProductFiend(fiendProduct);
    //     if(isEmptyAddress(fiendClient.clientAddress)) {
    //         if(fiendClient.clientItems.length > 0) {
    //             for (uint i = 0; i < fiendClient.clientItems.length; i++) {
    //                 isAlreadyBuyed(fiendClient.clientItems[i].name, fiendProduct.name);
    //                 break;
    //             }
    //             isAmount(fiendProduct.quantity, _quantity);
    //             Product memory buyedProduct = Product(fiendProduct.id,fiendProduct.name,_quantity);
    //             // fiendClient.ClientItems.push(Product(fiendProduct.id,fiendProduct.name,_quantity));
    //             fiendClient.clientItems;
    //         } else {
    //             isAmount(fiendProduct.quantity, _quantity);
    //             Product memory buyedProduct = Product(fiendProduct.id,fiendProduct.name,_quantity);
    //             fiendClient.clientItems.push(buyedProduct);
    //         }
    //     } else {
    //         buyers.push(sender);
    //         clientStructs[sender] = Client(sender, fiendProduct);
    //     }
    // }

    function buyProduct(string memory name, uint _quantity) public isClient {
        // require(id > 0, "Id must be greater then");
        address sender = msg.sender;
        isProductFiend(productStructs[name].id);
        if(isEmptyAddress(clientStructs[sender].clientAddress)) {
            if(clientStructs[sender].clientItems.length > 0) {
                for (uint i = 0; i < clientStructs[sender].clientItems.length; i++) {
                    isAlreadyBuyed(clientStructs[sender].clientItems[i].name, productStructs[name].name);
                    break;
                }
                isAmount(productStructs[name].quantity, _quantity);
                clientStructs[sender].clientItems.push(Product(productStructs[name].id,productStructs[name].name,_quantity));
            } else {
                isAmount(productStructs[name].quantity, _quantity);
                clientStructs[sender].clientItems.push(Product(productStructs[name].id,productStructs[name].name,_quantity));
            }
        } else {
            buyers.push(sender);
            Product[] memory newProduct;
            newProduct[0]=Product(productStructs[name].id,productStructs[name].name,_quantity);
            clientStructs[sender] = Client(sender, newProduct);
        }
    }

    function returnProducts(string[] memory names, uint blockNumber) public {
         address sender = msg.sender;
         uint blockWaitTime = blockNumber > 0 ? blockNumber : 100;
        if(block.number == blockWaitTime) {
            for(uint i = 0; i < names.length; i++) {
                isProductFiend(productStructs[names[i]].id);
                if(isEmptyAddress(clientStructs[sender].clientAddress)) {
                    if(isClientBuyedProduct(clientStructs[sender].clientItems, productStructs[names[i]].id)) {
                        productStructs[names[i]] = Product(productStructs[names[i]].id, productStructs[names[i]].name, productStructs[names[i]].quantity + productQuantity(clientStructs[sender].clientItems,productStructs[names[i]].id));
                    }
                }
            }
        }
    }

    function seeAllBuyersForThatProduct(string memory name) public view returns (address[] memory) {
        isProductFiend(productStructs[name].id);
        address[] memory allBuyers;
        for(uint i = 0; i < buyers.length; i++) {
            if(isEmptyAddress(clientStructs[buyers[i]].clientAddress)) {
                if(isClientBuyedProduct(clientStructs[buyers[i]].clientItems, productStructs[name].id)) {
                    allBuyers[allBuyers.length+1] = clientStructs[buyers[i]].clientAddress;
                }
            }
        }
        return allBuyers;
    }
}
