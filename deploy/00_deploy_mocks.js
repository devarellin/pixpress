module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();
  const MockPxa = await deploy('MockPxa', {
    from: deployer,
    log: true,
  });
  const MockPws = await deploy('MockPWS', {
    from: deployer,
    log: true,
  });
  const MockPxt = await deploy('MockPxt', {
    from: deployer,
    log: true,
  });
  await deploy('MockPxaMarket', {
    from: deployer,
    log: true,
    args: [MockPxa.address, MockPws.address]
  });
  await deploy('MockPxtPool', {
    from: deployer,
    log: true,
    args: [MockPxt.address]
  });
  await deploy('MockCeloPunks', {
    from: deployer,
    log: true,
  });
  await deploy('MockUbeswap', {
    from: deployer,
    log: true,
  });
};

module.exports.tags = ['Mocks'];
module.exports.skip = (env) => !env.network.tags.local