// Declare Solidity version
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Declare the contract
contract AssetPlan {
    uint assetCount = 0; // State variable -> written to the blockchain, recording the state on the chain.

    // Definition of a data type
    struct Asset {
        string assetNumber;
        string area;
        string description;
        string unit;
        uint quantity;
        uint expectedLife; // In milliseconds - expected end of life
        uint purchasePrice; // In cents
        uint purchaseDate; // In milliseconds
        uint warrantyEnd; // In milliseconds
        string barcode;
        // These are stored in cents
        uint[] forecastMaintenance;
        uint[] actualMaintenance;
        
        uint createdBy; // Maps to the creator's AddressTuple
        uint deletedBy; // Maps to the deletor's AddressTuple
        uint replacedBy;
    }
    
    struct ForecastMaintenance {
        uint cost; // In cents - per unit
        uint date; // In milliseconds
        string description;
        
        uint createdBy; // Maps to the creator's AddressTuple
        uint deletedBy; // Maps to the deletor's AddressTuple
    }
    
    struct ActualMaintenance {
        uint cost; // In cents - per unit
        uint date; // In milliseconds
        string description;
        string supplier;
        string invoiceNumber;
        uint invoiceDate; // In milliseconds
        
        uint createdBy; // Maps to the creator's AddressTuple
        uint deletedBy; // Maps to the deletor's AddressTuple
    }

    // A lot like a hash -> key value pair
    mapping(uint => Asset) assets;
    mapping(uint => ForecastMaintenance) forecastMaintenance;
    uint forecastMaintenanceCount = 0;
    mapping(uint => ActualMaintenance) actualMaintenance;
    uint actualMaintenanceCount = 0;

    // Event to listen to blockchain network events
    event AssetCreated(
        uint count,
        uint assetId,
        bool success
    );

    // Runs when the smart contract first accessed (on deployment)
    constructor() {
        // createTask("First task");   
    }

    // Takes all parameters required for the creation of an asset
    // _replaceExistingAsset is an array containing a 1 as first element if we will be replacing an asset and the asset this is replacing as the second element
    function createAsset(string memory _assetNumber, string memory _area, string memory _description, string memory _unit, uint _quantity, uint _expectedLife, uint _purchasePrice, uint _purchaseDate, uint _warrantyEnd, string memory _barcode, uint[] memory _replaceExistingAsset) public {
        
        // Find the user's address
        uint addressIndex = 0;
        for (uint i = 1; i < addressCount; i++) { 
            if (addresses[i].key == msg.sender) {
                addressIndex = i;
            }
        }
        // Address not found - they are not allowed to create an asset
        if (addressIndex == 0) {
            emit AssetCreated(assetCount, 0, false);
            return;
        }
        
        Asset memory a;
        a.assetNumber = _assetNumber;
        a.area = _area;
        a.description = _description;
        a.unit = _unit;
        a.quantity = _quantity;
        a.expectedLife = _expectedLife;
        a.purchasePrice = _purchasePrice;
        a.purchaseDate = _purchaseDate;
        a.warrantyEnd = _warrantyEnd;
        a.barcode = _barcode;
        a.createdBy = addressIndex;
        a.deletedBy = 0; // No one has deleted this yet
        a.replacedBy = 0; // Not replaced by anything -> nothing can be replace by the first asset
        assets[assetCount] = a;
        
        if (_replaceExistingAsset[0] == 1) {
            assets[_replaceExistingAsset[1]].replacedBy = assetCount;
            assets[_replaceExistingAsset[1]].deletedBy = addressIndex; // This asset is also decommissioned
        }
        
        assetCount ++; // Increment where we are up to
        
        // Trigger event - these can also be listened to client-side
        emit AssetCreated(assetCount, assetCount - 1, true);
    }
    
    // Decommission an asset from use
    function deleteAsset(uint _assetId) public {
        // Find the user's address
        uint addressIndex = 0;
        for (uint i = 1; i < addressCount; i++) { 
            if (addresses[i].key == msg.sender) {
                addressIndex = i;
            }
        }
        // Address not found - they are not allowed to delete an asset
        if (addressIndex == 0) {
            emit AssetDeleted(false, false, false);
            return;
        }
        
        // Asset not found
        if (_assetId >= assetCount) {
            emit AssetDeleted(false, true, false);
            return;
        }
        
        assets[_assetId].deletedBy = addressIndex;
        
        // Trigger event - these can also be listened to client-side
        emit AssetDeleted(true, true, true);
    }
    
    event AssetDeleted (
        bool assetFound, // Was the assetId valid
        bool addressFound, // Was the address valid
        bool success // Deleted successfully
    );
    
    event ForecastMaintenanceAdded (
        bool assetFound, // Was the assetId valid
        bool addressFound, // Was the address valid
        bool success // Saved successfully
    );
    
    event ActualMaintenanceAdded (
        bool assetFound, // Was the assetId valid
        bool addressFound, // Was the address valid
        bool success // Saved successfully
    );
    
    // Add Maintenance for the the asset with the provided id
    // Returns a bool based on whether the asset was found and access granted
    function addForecastMaintenance(uint[] memory _assetId, uint[] memory _cost, uint[] memory _date, string[] memory _description) public {
        // Find the user's address
        uint addressIndex = 0;
        for (uint i = 1; i < addressCount; i++) { 
            if (addresses[i].key == msg.sender) {
                addressIndex = i;
            }
        }
        // Address not found
        if (addressIndex == 0) {
            emit ForecastMaintenanceAdded(false, false, false);
            return;
        }
        
        // Loop through each of the forecast's assetCount
        for (uint i = 0; i < _assetId.length; i++) {
            // Asset not found
            if (_assetId[i] >= assetCount) {
                emit ForecastMaintenanceAdded(false, true, false);
                return;
            }
            
            
            // Save to the forecast 
            forecastMaintenance[forecastMaintenanceCount] = ForecastMaintenance(_cost[i], _date[i], _description[i], addressIndex, 0);
            
            // Save the reference to this maintenance in the asset
            assets[_assetId[i]].forecastMaintenance.push(forecastMaintenanceCount);
            
            forecastMaintenanceCount++;
            
            emit ForecastMaintenanceAdded(true, true, true);
        }
    }
    
    // Add Maintenance for the the asset with the provided id
    // Returns a bool based on whether the asset was found and access granted
    function addActualMaintenance(uint _assetId, uint _cost, uint _date, string memory _description, string memory _supplier, string memory _invoiceNumber, uint _invoiceDate) public {
        // Find the user's address
        uint addressIndex = 0;
        for (uint i = 1; i < addressCount; i++) { 
            if (addresses[i].key == msg.sender) {
                addressIndex = i;
            }
        }
        // Address not found
        if (addressIndex == 0) {
            emit ActualMaintenanceAdded(false, false, false);
            return;
        }
        
        // Loop through each of the forecast's assetCount
        // Asset not found
        if (_assetId >= assetCount) {
            emit ActualMaintenanceAdded(false, true, false);
            return;
        }
        
        
        // Save to the forecast 
        actualMaintenance[actualMaintenanceCount] = ActualMaintenance(_cost, _date, _description, _supplier, _invoiceNumber, _invoiceDate, addressIndex, 0);
        
        // Save the reference to this maintenance in the asset
        assets[_assetId].actualMaintenance.push(actualMaintenanceCount);
        
        actualMaintenanceCount++;
        
        emit ActualMaintenanceAdded(true, true, true);
    }
    
    // Return all the assets, with the created and deleted device names. If there is no AddressTuple attached to these
    // then return empty string for them
    function getAllAssets() public view returns (Asset[] memory, string[] memory, string[] memory) {
        Asset[] memory tempArray = new Asset[](assetCount); 
        string[] memory created = new string[](assetCount);
        string[] memory deleted = new string[](assetCount);
        for (uint i = 0; i < assetCount; i++) {
          tempArray[i] = assets[i];
          if (assets[i].createdBy != 0) {
              uint index = assets[i].createdBy;
              created[i] = addresses[index].deviceName;
          }
          else {
              created[i] = '';
          }
          if (assets[i].deletedBy != 0) {
              uint index = assets[i].deletedBy;
              deleted[i] = addresses[index].deviceName;
          }
          else {
              deleted[i] = '';
          }
        }
        
        return (tempArray, created, deleted);
    }
    
    // Return a single asset based on the provided assetId, with the created and deleted device names. If there is no AddressTuple attached to these
    // then return empty string for them
    function getAsset(uint _assetId) public view returns (Asset memory, string memory, string memory) {
        Asset memory tempAsset = assets[_assetId]; 
        string memory created = '';
        string memory deleted = '';
          if (tempAsset.createdBy != 0) {
              uint index = tempAsset.createdBy;
              created = addresses[index].deviceName;
          }
          if (tempAsset.deletedBy != 0) {
              uint index = tempAsset.deletedBy;
              deleted = addresses[index].deviceName;
          }
        
        return (tempAsset, created, deleted);
    }
    
    // Return all the forecasts, with the created and deleted device names. If there is no AddressTuple attached to these
    // then return empty string for them.
    function getAssetForecasts(uint assetIndex) public view returns (ForecastMaintenance[] memory, string[] memory, string[] memory) {
        Asset memory asset = assets[assetIndex];
        string[] memory created = new string[](asset.forecastMaintenance.length);
        string[] memory deleted = new string[](asset.forecastMaintenance.length);
        ForecastMaintenance[] memory tempArray = new ForecastMaintenance[](asset.forecastMaintenance.length); 
        for (uint i = 0; i < asset.forecastMaintenance.length; i++) {
            // Lookup each of the forecast maintence for each index stored in the asset's array
            uint index = asset.forecastMaintenance[i];
            tempArray[i] = forecastMaintenance[index];
            if (forecastMaintenance[i].createdBy != 0) {
              index = forecastMaintenance[i].createdBy;
              created[i] = addresses[index].deviceName;
            }
            else {
              created[i] = '';
            }
            if (forecastMaintenance[i].deletedBy != 0) {
              index = forecastMaintenance[i].deletedBy;
              deleted[i] = addresses[index].deviceName;
            }
            else {
              deleted[i] = '';
            }
        }
        
        return (tempArray, created, deleted);
    }
    
    // Return all the actuals, with the created and deleted device names. If there is no AddressTuple attached to these
    // then return empty string for them
    // Return empty arrays for everything if the user is not authorised
    function getAssetActuals(uint assetIndex) public view returns (ActualMaintenance[] memory, string[] memory, string[] memory) {
        Asset memory asset = assets[assetIndex];
        string[] memory created = new string[](asset.actualMaintenance.length);
        string[] memory deleted = new string[](asset.actualMaintenance.length);
        ActualMaintenance[] memory tempArray = new ActualMaintenance[](asset.actualMaintenance.length); 
        for (uint i = 0; i < asset.actualMaintenance.length; i++) {
            // Lookup each of the forecast maintence for each index stored in the asset's array
            uint index = asset.actualMaintenance[i];
            tempArray[i] = actualMaintenance[index];
            if (actualMaintenance[i].createdBy != 0) {
              index = actualMaintenance[i].createdBy;
              created[i] = addresses[index].deviceName;
            }
            else {
              created[i] = '';
            }
            if (actualMaintenance[i].deletedBy != 0) {
              index = actualMaintenance[i].deletedBy;
              deleted[i] = addresses[index].deviceName;
            }
            else {
              deleted[i] = '';
            }
        }
        
        return (tempArray, created, deleted);
    }
    
    
    // ADDRESS MANAGEMENT DETAILS
    // User must register an address with a device name to be able to make transactions on the network.
    // Anyone can register an address and device name. 
    // It is the plan that users will make public the name that they have registered, tying transactions to them.
    // It is impossible to register two addresses with the same name
    struct AddressTuple {
        address key;
        string deviceName;
    }
    
    // 0 in the mapping is used as a null value -> ie. no AddressTuple stored for a particular event
    mapping(uint => AddressTuple) addresses;
    uint addressCount = 1;
        
    // Event to listen to blockchain network events
    event RegisteredAddress(
        address sender,
        bool success
    );
    
    // Return value indicates whether successful or not
    // TODO - check address has not already been registered
    function registerAddress(string memory _name) public {
        // Check that the name doesn't already exist
        for (uint i = 1; i < addressCount; i++) { 
            if (compareStrings(addresses[i].deviceName, _name)) {
                emit RegisteredAddress(msg.sender, false); // Registration failed
                return;
                // return false;
            }
        }

        // Store the address
        addresses[addressCount] = AddressTuple(msg.sender, _name);
        addressCount++;
        // return true;
        emit RegisteredAddress(msg.sender, true); // Registration successful
    }
    
    // Source: https://ethereum.stackexchange.com/questions/30912/how-to-compare-strings-in-solidity/82739
    function compareStrings(string memory a, string memory b) private pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }
}