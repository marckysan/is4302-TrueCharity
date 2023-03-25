const SuperApp = artifacts.require("SuperApp");
const CharityToken = artifacts.require("CharityToken");

module.exports = (deployer, network, accounts) => {
    deployer.deploy(CharityToken).then(function() {
        return deployer.deploy(SuperApp, CharityToken.address);
    })
}