const { NFT } = require('../mocks')

// gas limit buffer to prevent out of gas error
const GAS_LIMIT_BUFFER = 50000
const DEFAULT_GAS_LIMIT = 500000

module.exports = async ({ ethers, deployments, getNamedAccounts, network }) => {
    const { read, execute } = deployments
    const { deployer } = await getNamedAccounts();

    const OldPixelAva = await ethers.getContractFactory('PixelAva');
    const oldPixelAva = OldPixelAva.attach(network.config.migrateFrom)
    const oldTotalSupply = await oldPixelAva.totalSupply()

    const newTotalSupplyStr = await read('PixelAva', 'totalSupply')
    const newTotalSupply = parseInt(newTotalSupplyStr)
    if (newTotalSupply >= oldTotalSupply) return;

    let gasLimitForMint;
    let gasLimitForTransfer;
    for (let i = newTotalSupply; i < oldTotalSupply; i++) {
        // // fork an nft on new contract
        const mint = await execute('PixelAva', { from: deployer, gasLimit: gasLimitForMint || DEFAULT_GAS_LIMIT, log: true }, 'mint', NFT.MATRIX, NFT.COLORS)
        // // assign owner to forked nft
        const mintedTokenId = await read('PixelAva', 'totalSupply')
        const ownerOfOriginal = await oldPixelAva.ownerOf(mintedTokenId)

        let transfer
        if (ownerOfOriginal !== deployer) {
            transfer = await execute('PixelAva', { from: deployer, gasLimit: gasLimitForTransfer || DEFAULT_GAS_LIMIT, log: true }, 'safeTransferFrom(address,address,uint256)', deployer, ownerOfOriginal, mintedTokenId)
        }
        // calc gas limit for next round
        const lastMintGasUsed = mint.gasUsed
        const lastTransferGasUsed = transfer.gasUsed
        gasLimitForMint = lastMintGasUsed.add(GAS_LIMIT_BUFFER);
        gasLimitForTransfer = lastTransferGasUsed.add(GAS_LIMIT_BUFFER);
    }
};

module.exports.tags = ['Migration'];
module.exports.skip = (env) => env.network.tags.local