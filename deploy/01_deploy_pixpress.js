module.exports = async ({ deployments, getNamedAccounts, network }) => {
    const { get, deploy } = deployments
    const { deployer } = await getNamedAccounts();

    let pxaAddress
    let pxtAddress

    if (network.tags.local) {
        const MockPxa = await get('MockPxa');
        const MockPxt = await get('MockPxt');
        pxaAddress = MockPxa.address
        pxtAddress = MockPxt.address
    } else {
        pxaAddress = network.config.pxaAddress
        pxtAddress = network.config.pxtAddress
    }

    await deploy('Pixpress', {
        from: deployer,
        log: true,
        args: [pxaAddress, pxtAddress]
    });
};

module.exports.tags = ['Main'];