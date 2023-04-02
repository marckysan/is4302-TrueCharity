const { from } = require("responselike");

const SuperApp = artifacts.require("SuperApp");
const CharityToken = artifacts.require("CharityToken");
const Marketplace = artifacts.require("Marketplace");

module.exports = (deployer, network, accounts) => {
  deployer
    .deploy(CharityToken, { from: accounts[0] })
    .then(function () {
      return deployer.deploy(SuperApp, CharityToken.address, {
        from: accounts[0],
      });
    })
    .then(function () {
      return deployer.deploy(
        Marketplace,
        CharityToken.address,
        SuperApp.address,
        { from: accounts[1] }
      );
    });
};
