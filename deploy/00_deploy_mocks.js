module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();
  await deploy('MockPxa', {
    from: deployer,
    log: true,
  });
  await deploy('MockPxt', {
    from: deployer,
    log: true,
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