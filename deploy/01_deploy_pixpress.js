module.exports = async ({ deployments, getNamedAccounts, network }) => {
    const { get, read, execute, deploy } = deployments
    const { deployer } = await getNamedAccounts();

    let pxaMarketAddress
    let pxtPoolAddress

    if (network.tags.local) {
        const MockPxaMarket = await get('MockPxaMarket');
        const MockPxtPool = await get('MockPxtPool');
        pxaMarketAddress = MockPxaMarket.address
        pxtPoolAddress = MockPxtPool.address
    } else {
        pxaMarketAddress = network.config.pxaMarketAddress
        pxtPoolAddress = network.config.pxtPoolAddress
    }

    await deploy('Pixpress', {
        from: deployer,
        log: true,
        args: [pxaMarketAddress, pxtPoolAddress]
    });

    if (network.tags.local) {
        // open access control
        const Pixpress = await get('Pixpress');
        const coordernatorRole = await read('MockPxtPool', 'COORDINATOR');
        await execute('MockPxtPool', { from: deployer }, 'grantRole', coordernatorRole, Pixpress.address);
    }
};

module.exports.tags = ['Main'];