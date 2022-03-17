module.exports = async ({ deployments, getNamedAccounts }) => {
    const { get, deploy } = deployments
    const { deployer } = await getNamedAccounts();

    const MockPxa = await get('MockPxa');
    const MockPxt = await get('MockPxt');

    await deploy('Pixpress', {
        from: deployer,
        log: true,
        args: [MockPxa.address, MockPxt.address]
    });


};

module.exports.tags = ['Main'];