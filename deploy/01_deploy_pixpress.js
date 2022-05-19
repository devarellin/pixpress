module.exports = async ({ deployments, getNamedAccounts, network }) => {
    const { get, deploy } = deployments
    const { deployer } = await getNamedAccounts();

    let pxaMarketAddress
    let pxtAddress

    if (network.tags.local) {
        const MockPxt = await get('MockPxt');
        const MockPxaMarket = await get('MockPxaMarket');
        pxtAddress = MockPxt.address
        pxaMarketAddress = MockPxaMarket.address
    } else {
        pxtAddress = network.config.pxtAddress
        pxaMarketAddress = network.config.pxaMarketAddress
    }

    await deploy('Pixpress', {
        from: deployer,
        log: true,
        args: [pxtAddress, pxaMarketAddress]
    });
};

module.exports.tags = ['Main'];