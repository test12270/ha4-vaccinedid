pragma solidity 0.8.7;

abstract contract OwnerHelper {
    address private owner;

    event OwnerTransferPropose(address indexed _from, address indexed _to);

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function transferOwnership(address _to) public onlyOwner {
        require(_to != owner);
        require(_to != address(0x0));
        owner = _to;
        emit OwnerTransferPropose(owner, _to);
    }
}

abstract contract IssuerHelper is OwnerHelper {
    mapping(address => bool) public issuers;

    event AddIssuer(address indexed _issuer);
    event DelIssuer(address indexed _issuer);

    modifier onlyIssuer() {
        require(isIssuer(msg.sender) == true);
        _;
    }

    constructor() {
        issuers[msg.sender] = true;
    }

    function isIssuer(address _addr) public view returns (bool) {
        return issuers[_addr];
    }

    function addIssuer(address _addr) public onlyOwner returns (bool) {
        require(issuers[_addr] == false);
        issuers[_addr] = true;
        emit AddIssuer(_addr);
        return true;
    }

    function delIssuer(address _addr) public onlyOwner returns (bool) {
        require(issuers[_addr] == true);
        issuers[_addr] = false;
        emit DelIssuer(_addr);
        return true;
    }
}

contract CredentialBox is IssuerHelper{
    uint8 private idCount;
    mapping(uint8 => string) private vaccineEnum;
    uint8 vaccineLen;

    struct Credential {
        uint256 id;
        string value;
        mapping(uint8 => address) vaccineIssuers;
        mapping(uint8 => uint8) vaccineType;
        mapping(uint8 => uint256) vaccineInfo;
        uint8 lastestVaccineNum;
    }

    struct Presentation{
        address vaccineIssuers;
        string vaccineType;
        uint8 vaccineNum;
        uint256 vaccineInfo;
    }

    mapping(address => Credential) private credentials;

    constructor() {
        idCount = 1;
        vaccineEnum[0] = "Moderna";
        vaccineEnum[1] = "Pfizer";
        vaccineEnum[2] = "Janssen";
        vaccineEnum[3] = "Astrazeneca";
        vaccineLen = 4;
    }

    function claimCredential(address _vaccinatedAddress, uint8 _vaccineNum, uint8 _vaccineType, string calldata _value) public onlyIssuer returns (bool) {
        Credential storage credential = credentials[_vaccinatedAddress];
        require(credential.id == 0);
        require(_vaccineNum == 1);
        credential.id = idCount;
        credential.vaccineIssuers[_vaccineNum] = msg.sender;
        credential.vaccineType[_vaccineNum] = _vaccineType;
        credential.vaccineInfo[_vaccineNum] = block.timestamp;
        credential.value = _value;
        credential.lastestVaccineNum = 1;

        idCount += 1;

        return true;
    }

    function getCredential(address _vaccinatedAddress, uint8 _vaccineNum) public view returns (Presentation memory) {
        require(credentials[_vaccinatedAddress].id != 0, "not claimed credential");
        require(_vaccineNum <= credentials[_vaccinatedAddress].lastestVaccineNum, "invaild vaccien number");

        string memory vaccineType;
        vaccineType = getVaccineType(credentials[_vaccinatedAddress].vaccineType[_vaccineNum]);
        Presentation memory presentation = Presentation(
            credentials[_vaccinatedAddress].vaccineIssuers[_vaccineNum],
            vaccineType,
            _vaccineNum,
            credentials[_vaccinatedAddress].vaccineInfo[_vaccineNum]
        );

        return presentation;
    }

    function addVaccineType(string calldata _vaccineType) public onlyIssuer returns (bool) {
        for (uint8 i = 0; i < vaccineLen; i++) {
            require(keccak256(bytes(_vaccineType)) != keccak256(bytes(vaccineEnum[i])), "existed vaccine type");
        }
        vaccineEnum[vaccineLen] = _vaccineType;
        vaccineLen++;
        return true;
    }

    function getVaccineType(uint8 _vaccineType) public view returns (string memory) {
		require(bytes(vaccineEnum[_vaccineType]).length != 0, "invaild type");
        return vaccineEnum[_vaccineType];
    }

    function updateVaccinationState(address _vaccinatedAddress, uint8 _vaccineNum, uint8 _vaccineType) public onlyIssuer returns (bool) {
        require(credentials[_vaccinatedAddress].id != 0, "not claimed credential");
        require(_vaccineType < vaccineLen, "invaild type");
        credentials[_vaccinatedAddress].vaccineType[_vaccineNum] = _vaccineType;
        credentials[_vaccinatedAddress].vaccineInfo[_vaccineNum] = block.timestamp;
        credentials[_vaccinatedAddress].lastestVaccineNum = _vaccineNum;
        credentials[_vaccinatedAddress].vaccineIssuers[_vaccineNum] = msg.sender;
        return true;
    }
}