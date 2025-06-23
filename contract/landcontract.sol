// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract LandRegistry {
    // Enum for land types
    enum LandType { Residential, Farm, Commercial }
    
    // Enum for countries
    enum Country { Uganda, Kenya }
    
    // Struct to represent a land owner
    struct LandOwner {
        string name;
        string phoneNumber;
        string email;
        string nationalId;
        string profilePictureUrl;
        Country country;
    }
    
    // Struct to represent a land parcel with comprehensive details
    struct Land {
        uint256 id;
        LandOwner owner;
        address ownerAddress;
        string region;
        string district;
        string parish;
        string village;
        string landAddress;
        LandType landType;
        string locationDescription;
        uint256 landSizeAcres; // in acres
        uint256 landPriceUGX; // in UGX
        uint256 yearAcquired;
        bool isRegistered;
        uint256 registrationTimestamp;
        uint256 lastTransferTimestamp;
        uint256 transferCount;
    }
    
    // Struct for transfer history
    struct TransferRecord {
        uint256 landId;
        address fromAddress;
        address toAddress;
        LandOwner fromOwner;
        LandOwner toOwner;
        uint256 transferTimestamp;
        uint256 transferYear;
        uint256 transferMonth;
        uint256 transferDay;
        string transferReason;
    }
    
    // State variables
    mapping(uint256 => Land) public lands;
    mapping(address => uint256[]) public ownerToLands;
    mapping(uint256 => TransferRecord[]) public landTransferHistory;
    mapping(string => bool) public usedNationalIds; // Prevent duplicate national IDs
    
    uint256 public nextLandId = 1;
    uint256 public totalRegisteredLands = 0;
    uint256 public totalTransfers = 0;
    
    // Events
    event LandRegistered(
        uint256 indexed landId,
        string ownerName,
        string district,
        string village,
        LandType landType,
        uint256 landSizeAcres,
        uint256 landPriceUGX,
        address indexed ownerAddress,
        uint256 timestamp
    );
    
    event OwnershipTransferred(
        uint256 indexed landId,
        address indexed previousOwnerAddress,
        address indexed newOwnerAddress,
        string previousOwnerName,
        string newOwnerName,
        uint256 transferTimestamp,
        uint256 transferYear,
        uint256 transferMonth,
        uint256 transferDay
    );
    
    // Modifiers
    modifier onlyLandOwner(uint256 _landId) {
        require(lands[_landId].isRegistered, "Land does not exist");
        require(lands[_landId].ownerAddress == msg.sender, "You are not the owner of this land");
        _;
    }
    
    modifier validLandId(uint256 _landId) {
        require(_landId > 0 && _landId < nextLandId, "Invalid land ID");
        require(lands[_landId].isRegistered, "Land does not exist");
        _;
    }
    
    modifier uniqueNationalId(string memory _nationalId) {
        require(!usedNationalIds[_nationalId], "National ID already registered");
        _;
    }
    
    // Register a new land parcel with comprehensive details
    function registerLand(
        string memory _ownerName,
        string memory _phoneNumber,
        string memory _email,
        string memory _nationalId,
        string memory _profilePictureUrl,
        Country _country,
        string memory _region,
        string memory _district,
        string memory _parish,
        string memory _village,
        string memory _landAddress,
        LandType _landType,
        string memory _locationDescription,
        uint256 _landSizeAcres,
        uint256 _landPriceUGX,
        uint256 _yearAcquired
    ) public uniqueNationalId(_nationalId) returns (uint256) {
        require(bytes(_ownerName).length > 0, "Owner name cannot be empty");
        require(bytes(_phoneNumber).length > 0, "Phone number cannot be empty");
        require(bytes(_nationalId).length > 0, "National ID cannot be empty");
        require(bytes(_district).length > 0, "District cannot be empty");
        require(bytes(_village).length > 0, "Village cannot be empty");
        require(_landSizeAcres > 0, "Land size must be greater than 0");
        require(_landPriceUGX > 0, "Land price must be greater than 0");
        require(_yearAcquired > 1900 && _yearAcquired <= 2100, "Invalid year acquired");
        
        uint256 landId = nextLandId;
        
        LandOwner memory newOwner = LandOwner({
            name: _ownerName,
            phoneNumber: _phoneNumber,
            email: _email,
            nationalId: _nationalId,
            profilePictureUrl: _profilePictureUrl,
            country: _country
        });
        
        lands[landId] = Land({
            id: landId,
            owner: newOwner,
            ownerAddress: msg.sender,
            region: _region,
            district: _district,
            parish: _parish,
            village: _village,
            landAddress: _landAddress,
            landType: _landType,
            locationDescription: _locationDescription,
            landSizeAcres: _landSizeAcres,
            landPriceUGX: _landPriceUGX,
            yearAcquired: _yearAcquired,
            isRegistered: true,
            registrationTimestamp: block.timestamp,
            lastTransferTimestamp: block.timestamp,
            transferCount: 0
        });
        
        ownerToLands[msg.sender].push(landId);
        usedNationalIds[_nationalId] = true;
        nextLandId++;
        totalRegisteredLands++;
        
        emit LandRegistered(
            landId,
            _ownerName,
            _district,
            _village,
            _landType,
            _landSizeAcres,
            _landPriceUGX,
            msg.sender,
            block.timestamp
        );
        
        return landId;
    }
    
    // Transfer ownership of a land parcel with detailed tracking
    function transferOwnership(
        uint256 _landId, 
        address _newOwnerAddress,
        string memory _newOwnerName,
        string memory _newPhoneNumber,
        string memory _newEmail,
        string memory _newNationalId,
        string memory _newProfilePictureUrl,
        Country _newCountry,
        string memory _transferReason
    ) public onlyLandOwner(_landId) uniqueNationalId(_newNationalId) {
        require(_newOwnerAddress != address(0), "New owner address cannot be zero");
        require(_newOwnerAddress != msg.sender, "Cannot transfer to yourself");
        require(bytes(_newOwnerName).length > 0, "New owner name cannot be empty");
        require(bytes(_newNationalId).length > 0, "New owner national ID cannot be empty");
        
        Land storage land = lands[_landId];
        LandOwner memory previousOwner = land.owner;
        address previousOwnerAddress = land.ownerAddress;
        
        // Create new owner
        LandOwner memory newOwner = LandOwner({
            name: _newOwnerName,
            phoneNumber: _newPhoneNumber,
            email: _newEmail,
            nationalId: _newNationalId,
            profilePictureUrl: _newProfilePictureUrl,
            country: _newCountry
        });
        
        // Update land ownership
        land.owner = newOwner;
        land.ownerAddress = _newOwnerAddress;
        land.lastTransferTimestamp = block.timestamp;
        land.transferCount++;
        
        // Remove land from previous owner's list
        _removeLandFromOwner(previousOwnerAddress, _landId);
        
        // Add land to new owner's list
        ownerToLands[_newOwnerAddress].push(_landId);
        
        // Update national ID tracking
        usedNationalIds[previousOwner.nationalId] = false;
        usedNationalIds[_newNationalId] = true;
        
        // Create transfer record with date details
        (uint256 year, uint256 month, uint256 day) = _timestampToDate(block.timestamp);
        
        TransferRecord memory transferRecord = TransferRecord({
            landId: _landId,
            fromAddress: previousOwnerAddress,
            toAddress: _newOwnerAddress,
            fromOwner: previousOwner,
            toOwner: newOwner,
            transferTimestamp: block.timestamp,
            transferYear: year,
            transferMonth: month,
            transferDay: day,
            transferReason: _transferReason
        });
        
        landTransferHistory[_landId].push(transferRecord);
        totalTransfers++;
        
        emit OwnershipTransferred(
            _landId,
            previousOwnerAddress,
            _newOwnerAddress,
            previousOwner.name,
            _newOwnerName,
            block.timestamp,
            year,
            month,
            day
        );
    }
    
    // Get comprehensive land details by ID
    function getLandById(uint256 _landId) 
        public 
        view 
        validLandId(_landId) 
        returns (
            uint256 id,
            LandOwner memory owner,
            address ownerAddress,
            string memory region,
            string memory district,
            string memory parish,
            string memory village,
            string memory landAddress,
            LandType landType,
            string memory locationDescription,
            uint256 landSizeAcres,
            uint256 landPriceUGX,
            uint256 yearAcquired,
            uint256 registrationTimestamp,
            uint256 lastTransferTimestamp,
            uint256 transferCount
        ) 
    {
        Land memory land = lands[_landId];
        return (
            land.id,
            land.owner,
            land.ownerAddress,
            land.region,
            land.district,
            land.parish,
            land.village,
            land.landAddress,
            land.landType,
            land.locationDescription,
            land.landSizeAcres,
            land.landPriceUGX,
            land.yearAcquired,
            land.registrationTimestamp,
            land.lastTransferTimestamp,
            land.transferCount
        );
    }
    
    // Get transfer history for a land
    function getLandTransferHistory(uint256 _landId) 
        public 
        view 
        validLandId(_landId) 
        returns (TransferRecord[] memory) 
    {
        return landTransferHistory[_landId];
    }
    
    // Get all lands owned by a specific address
    function getLandsByOwner(address _owner) 
        public 
        view 
        returns (uint256[] memory) 
    {
        return ownerToLands[_owner];
    }
    
    // Get paginated land IDs with filtering options
    function getAllLandIds(
        uint256 _start, 
        uint256 _limit,
        LandType _filterType,
        bool _useTypeFilter,
        Country _filterCountry,
        bool _useCountryFilter
    ) 
        public 
        view 
        returns (uint256[] memory landIds, bool hasMore) 
    {
        require(_start > 0, "Start must be greater than 0");
        require(_limit > 0 && _limit <= 100, "Limit must be between 1 and 100");
        
        if (_start >= nextLandId) {
            return (new uint256[](0), false);
        }
        
        uint256 end = _start + _limit;
        if (end >= nextLandId) {
            end = nextLandId;
        }
        
        uint256 actualLength = 0;
        for (uint256 i = _start; i < end; i++) {
            if (lands[i].isRegistered && _matchesFilters(i, _filterType, _useTypeFilter, _filterCountry, _useCountryFilter)) {
                actualLength++;
            }
        }
        
        uint256[] memory result = new uint256[](actualLength);
        uint256 index = 0;
        
        for (uint256 i = _start; i < end; i++) {
            if (lands[i].isRegistered && _matchesFilters(i, _filterType, _useTypeFilter, _filterCountry, _useCountryFilter)) {
                result[index] = i;
                index++;
            }
        }
        
        return (result, end < nextLandId);
    }
    
    // Get contract statistics
    function getContractInfo() 
        public 
        view 
        returns (
            uint256 totalLands,
            uint256 nextId,
            uint256 totalTransfersCount
        ) 
    {
        return (totalRegisteredLands, nextLandId, totalTransfers);
    }
    
    // Get lands by district
    function getLandsByDistrict(string memory _district) 
        public 
        view 
        returns (uint256[] memory) 
    {
        uint256[] memory result = new uint256[](totalRegisteredLands);
        uint256 count = 0;
        
        for (uint256 i = 1; i < nextLandId; i++) {
            if (lands[i].isRegistered && 
                keccak256(abi.encodePacked(lands[i].district)) == keccak256(abi.encodePacked(_district))) {
                result[count] = i;
                count++;
            }
        }
        
        // Resize array to actual count
        uint256[] memory finalResult = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            finalResult[i] = result[i];
        }
        
        return finalResult;
    }
    
    // Check if a national ID is already used
    function isNationalIdUsed(string memory _nationalId) public view returns (bool) {
        return usedNationalIds[_nationalId];
    }
    
    // Helper function to check if land matches filters
    function _matchesFilters(
        uint256 _landId,
        LandType _filterType,
        bool _useTypeFilter,
        Country _filterCountry,
        bool _useCountryFilter
    ) private view returns (bool) {
        Land memory land = lands[_landId];
        
        if (_useTypeFilter && land.landType != _filterType) {
            return false;
        }
        
        if (_useCountryFilter && land.owner.country != _filterCountry) {
            return false;
        }
        
        return true;
    }
    
    // Helper function to remove land from owner's list
    function _removeLandFromOwner(address _owner, uint256 _landId) private {
        uint256[] storage ownerLands = ownerToLands[_owner];
        for (uint256 i = 0; i < ownerLands.length; i++) {
            if (ownerLands[i] == _landId) {
                ownerLands[i] = ownerLands[ownerLands.length - 1];
                ownerLands.pop();
                break;
            }
        }
    }
    
    // Helper function to convert timestamp to date components
    function _timestampToDate(uint256 timestamp) private pure returns (uint256 year, uint256 month, uint256 day) {
        uint256 secondsPerDay = 24 * 60 * 60;
        uint256 daysFromEpoch = timestamp / secondsPerDay;
        
        // Simplified date calculation (approximate)
        year = 1970 + (daysFromEpoch * 400) / (400 * 365 + 97); // Account for leap years
        
        // More precise calculation would require more complex leap year logic
        // For demonstration, using simplified approach
        uint256 yearStart = (year - 1970) * 365 + (year - 1969) / 4; // Approximate
        uint256 dayOfYear = daysFromEpoch - yearStart + 1;
        
        // Simplified month calculation
        if (dayOfYear <= 31) {
            month = 1;
            day = dayOfYear;
        } else if (dayOfYear <= 59) {
            month = 2;
            day = dayOfYear - 31;
        } else if (dayOfYear <= 90) {
            month = 3;
            day = dayOfYear - 59;
        } else if (dayOfYear <= 120) {
            month = 4;
            day = dayOfYear - 90;
        } else if (dayOfYear <= 151) {
            month = 5;
            day = dayOfYear - 120;
        } else if (dayOfYear <= 181) {
            month = 6;
            day = dayOfYear - 151;
        } else if (dayOfYear <= 212) {
            month = 7;
            day = dayOfYear - 181;
        } else if (dayOfYear <= 243) {
            month = 8;
            day = dayOfYear - 212;
        } else if (dayOfYear <= 273) {
            month = 9;
            day = dayOfYear - 243;
        } else if (dayOfYear <= 304) {
            month = 10;
            day = dayOfYear - 273;
        } else if (dayOfYear <= 334) {
            month = 11;
            day = dayOfYear - 304;
        } else {
            month = 12;
            day = dayOfYear - 334;
        }
        
        return (year, month, day);
    }
    
    // Get land type as string
    function getLandTypeString(LandType _landType) public pure returns (string memory) {
        if (_landType == LandType.Residential) return "Residential";
        if (_landType == LandType.Farm) return "Farm";
        if (_landType == LandType.Commercial) return "Commercial";
        return "Unknown";
    }
    
    // Get country as string
    function getCountryString(Country _country) public pure returns (string memory) {
        if (_country == Country.Uganda) return "Uganda";
        if (_country == Country.Kenya) return "Kenya";
        return "Unknown";
    }
}