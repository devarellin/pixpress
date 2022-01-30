module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();
  await deploy('PixelAva', {
    from: deployer,
    log: true,
    args: ['https://test-service.pixelava.space/api/metadata/']
  });
};

module.exports.tags = ['PixelAva'];